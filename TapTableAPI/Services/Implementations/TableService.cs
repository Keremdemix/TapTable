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
    private readonly ITableLayoutRepository _tableLayoutRepository;
    private readonly string _customerBaseUrl;

    public TableService(
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        ITableLayoutRepository tableLayoutRepository,
        IConfiguration configuration)
    {
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _tableLayoutRepository = tableLayoutRepository;
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
        var table = new RestaurantTable
        {
            RestaurantId = restaurantId,
            TableNumber = request.TableNumber,
            Capacity = request.Capacity,
            QrCodeUrl = string.Empty,
            Status = TableStatus.Available,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _tableRepository.CreateAsync(table);

        // Session önce oluşturulur, QR URL token'a göre üretilir — table id URL'de yer almaz
        var session = new QrSession
        {
            TableId = created.Id,
            RestaurantId = restaurantId,
            SessionKey = NewSessionKey(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        await _qrSessionRepository.CreateAsync(session);

        created.QrCodeUrl = $"{_customerBaseUrl}/menu?token={session.SessionKey}";
        await _tableRepository.UpdateAsync(created);

        // Kat planı kısmı aynı kalıyor...
        var existingCount = (await _tableRepository.GetAllAsync(restaurantId)).Count();
        var index = existingCount - 1;
        var col = index % 5;
        var row = index / 5;

        await _tableLayoutRepository.CreateAsync(new TableLayout
        {
            TableId = created.Id,
            Width = 100,
            Height = 100,
            Shape = "rectangle",
            PositionX = 40 + col * 150,
            PositionY = 40 + row * 150
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

        await _qrSessionRepository.CloseActiveSessionAsync(tableId);
        await _tableRepository.DeleteAsync(table);
    }

    public async Task<RegenerateQrResponseDto> RegenerateQrAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        await _qrSessionRepository.CloseActiveSessionAsync(tableId);

        var newKey = NewSessionKey();
        await _qrSessionRepository.CreateAsync(new QrSession
        {
            TableId = tableId,
            RestaurantId = restaurantId,
            SessionKey = newKey,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        });

        // Eski token'ı taşıyan URL artık geçersiz — table.QrCodeUrl yeni token ile güncellenir
        table.QrCodeUrl = $"{_customerBaseUrl}/menu?token={newKey}";
        var updated = await _tableRepository.UpdateAsync(table);

        return new RegenerateQrResponseDto
        {
            TableId = updated.Id,
            TableNumber = updated.TableNumber,
            QrCodeUrl = updated.QrCodeUrl,
            NewSessionKey = newKey
        };
    }
    // ── Kat Planı ────────────────────────────────────────────────────────

    public async Task<IEnumerable<TableLayoutResponseDto>> GetLayoutAsync(int restaurantId)
    {
        var tables = await _tableRepository.GetAllAsync(restaurantId);

        return tables.Select(t => new TableLayoutResponseDto
        {
            TableId = t.Id,
            TableNumber = t.TableNumber,
            Capacity = t.Capacity,
            Status = t.Status.ToString(),
            Width = t.Layout?.Width ?? 100,
            Height = t.Layout?.Height ?? 100,
            Shape = t.Layout?.Shape ?? "rectangle",
            PositionX = t.Layout?.PositionX ?? 0,
            PositionY = t.Layout?.PositionY ?? 0
        });
    }

    public async Task SaveLayoutAsync(int restaurantId, UpdateLayoutRequestDto request)
    {
        foreach (var item in request.Layouts)
        {
            var table = await _tableRepository.GetByIdAsync(item.TableId, restaurantId);
            if (table is null) continue; // başka restorana ait/bulunamayan masa — sessizce atla

            var layout = await _tableLayoutRepository.GetByTableIdAsync(item.TableId);

            if (layout is null)
            {
                await _tableLayoutRepository.CreateAsync(new TableLayout
                {
                    TableId = item.TableId,
                    Width = item.Width,
                    Height = item.Height,
                    Shape = item.Shape,
                    PositionX = item.PositionX,
                    PositionY = item.PositionY
                });
            }
            else
            {
                layout.Width = item.Width;
                layout.Height = item.Height;
                layout.Shape = item.Shape;
                layout.PositionX = item.PositionX;
                layout.PositionY = item.PositionY;
                await _tableLayoutRepository.UpdateAsync(layout);
            }
        }
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