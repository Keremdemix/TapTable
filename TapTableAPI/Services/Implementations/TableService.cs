using System.Text.Json;
using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Table;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class TableService : ITableService
{
    private readonly ITableRepository _tableRepository;
    private readonly IConfiguration _configuration;

    public TableService(ITableRepository tableRepository, IConfiguration configuration)
    {
        _tableRepository = tableRepository;
        _configuration = configuration;
    }

    public async Task<IEnumerable<TableDto>> GetTablesAsync(int restaurantId)
    {
        var tables = await _tableRepository.GetTablesByRestaurantAsync(restaurantId);
        return tables.Select(MapToTableDto);
    }

    public async Task<TableDto> GetTableByIdAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetTableByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");
        return MapToTableDto(table);
    }

    public async Task<TableDto> CreateTableAsync(int restaurantId, CreateTableDto request)
    {
        var qrToken = Guid.NewGuid().ToString("N");

        var table = new Table
        {
            RestaurantId = restaurantId,
            Name = request.Name,
            Capacity = request.Capacity,
            QrToken = qrToken,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _tableRepository.CreateTableAsync(table);
        return MapToTableDto(created);
    }

    public async Task<TableDto> UpdateTableAsync(int tableId, int restaurantId, UpdateTableDto request)
    {
        var table = await _tableRepository.GetTableByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        table.Name = request.Name;
        table.Capacity = request.Capacity;
        table.IsActive = request.IsActive;
        table.UpdatedAt = DateTime.UtcNow;

        var updated = await _tableRepository.UpdateTableAsync(table);
        return MapToTableDto(updated);
    }

    public async Task DeleteTableAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetTableByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");
        await _tableRepository.DeleteTableAsync(table);
    }

    public async Task<TableLayoutDto> GetLayoutAsync(int restaurantId)
    {
        var layout = await _tableRepository.GetLayoutAsync(restaurantId);
        if (layout == null)
            return new TableLayoutDto { RestaurantId = restaurantId, Positions = [] };

        return new TableLayoutDto
        {
            RestaurantId = restaurantId,
            Positions = JsonSerializer.Deserialize<List<TablePositionDto>>(layout.LayoutJson) ?? []
        };
    }

    public async Task<TableLayoutDto> UpsertLayoutAsync(int restaurantId, UpsertLayoutDto request)
    {
        var layoutJson = JsonSerializer.Serialize(request.Positions);
        await _tableRepository.UpsertLayoutAsync(restaurantId, layoutJson);

        return new TableLayoutDto
        {
            RestaurantId = restaurantId,
            Positions = request.Positions
        };
    }

    public async Task<string> GenerateQrCodeAsync(int tableId, int restaurantId)
    {
        var table = await _tableRepository.GetTableByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        var baseUrl = _configuration["App:BaseUrl"];
        return $"{baseUrl}/menu?token={table.QrToken}";
    }

    public async Task<TableDto> GetTableByQrTokenAsync(string qrToken)
    {
        var table = await _tableRepository.GetTableByQrTokenAsync(qrToken)
            ?? throw new KeyNotFoundException("Geçersiz QR kodu.");
        return MapToTableDto(table);
    }

    // ── Mapper ───────────────────────────────────────────────────────────────

    private static TableDto MapToTableDto(Table t) => new()
    {
        Id = t.Id,
        RestaurantId = t.RestaurantId,
        Name = t.Name,
        Capacity = t.Capacity,
        QrToken = t.QrToken,
        IsActive = t.IsActive,
        CreatedAt = t.CreatedAt
    };
}
