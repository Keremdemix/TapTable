using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Table;
using TapTable.Api.DTOs.Response.Table;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class TableService : ITableService
{
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;
    private readonly string _customerBaseUrl;

    public TableService(
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IConfiguration configuration)
    {
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _customerBaseUrl = configuration["App:CustomerBaseUrl"]
            ?? "https://customer.taptable.com";
    }

    public async Task<TableResponseDto> GetTableAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        return MapToDto(table);
    }

    public async Task<IEnumerable<TableResponseDto>> GetTablesAsync(int restaurantId)
    {
        var tables = await _tableRepository.GetAllAsync(restaurantId);
        return tables.Select(MapToDto);
    }

    public async Task<TableResponseDto> CreateTableAsync(int restaurantId, CreateTableRequestDto request)
    {
        // 1. Masayı kaydet
        var table = new RestaurantTable
        {
            RestaurantId = restaurantId,
            TableNumber = request.TableNumber,
            Capacity = request.Capacity,
            QrCodeUrl = string.Empty, // Id gelince doldurulacak
            Status = TableStatus.Available,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _tableRepository.CreateAsync(table);

        // 2. Kalıcı QR URL — tableId bazlı, fiziksel QR hiç değişmez
        created.QrCodeUrl = $"{_customerBaseUrl}/table/{created.Id}";
        await _tableRepository.UpdateAsync(created);

        // 3. İlk QrSession'ı otomatik aç
        await _qrSessionRepository.CreateAsync(new QrSession
        {
            TableId = created.Id,
            RestaurantId = restaurantId,
            SessionKey = NewSessionKey(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        });

        return MapToDto(created);
    }

    public async Task<TableResponseDto> UpdateTableAsync(int tableId, int restaurantId, UpdateTableRequestDto request)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        table.TableNumber = request.TableNumber;
        table.Capacity = request.Capacity;
        table.IsActive = request.IsActive;

        // null → dokunma | boş string → sil | değer → güncelle
        if (request.QrCodeUrl is not null)
            table.QrCodeUrl = request.QrCodeUrl;

        return MapToDto(await _tableRepository.UpdateAsync(table));
    }

    public async Task<TableResponseDto> SetQrUrlAsync(int tableId, int restaurantId, string newUrl)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        table.QrCodeUrl = newUrl;
        return MapToDto(await _tableRepository.UpdateAsync(table));
    }

    public async Task<TableResponseDto> DeleteQrUrlAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        table.QrCodeUrl = string.Empty;
        return MapToDto(await _tableRepository.UpdateAsync(table));
    }

    public async Task DeleteTableAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        // Açık session varsa kapat
        await _qrSessionRepository.CloseActiveSessionAsync(tableId);

        await _tableRepository.DeleteAsync(table);
    }

    public async Task<RegenerateQrResponseDto> RegenerateQrAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        // Mevcut session'ı kapat
        await _qrSessionRepository.CloseActiveSessionAsync(tableId);

        // Yeni session aç — sonraki müşteriler bu key ile başlar
        var newKey = NewSessionKey();
        await _qrSessionRepository.CreateAsync(new QrSession
        {
            TableId = tableId,
            RestaurantId = restaurantId,
            SessionKey = newKey,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        });

        // Fiziksel QR URL değişmez — sadece yeni sessionKey dönüyoruz
        return new RegenerateQrResponseDto
        {
            TableId = table.Id,
            TableNumber = table.TableNumber,
            QrCodeUrl = table.QrCodeUrl,
            NewSessionKey = newKey
        };
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static string NewSessionKey() => Guid.NewGuid().ToString("N");

    private static TableResponseDto MapToDto(RestaurantTable t) => new()
    {
        Id = t.Id,
        RestaurantId = t.RestaurantId,
        TableNumber = t.TableNumber,
        Capacity = t.Capacity,
        QrCodeUrl = t.QrCodeUrl,
        Status = t.Status.ToString(),
        IsActive = t.IsActive,
        CreatedAt = t.CreatedAt,
        UpdatedAt = t.UpdatedAt
    };
}