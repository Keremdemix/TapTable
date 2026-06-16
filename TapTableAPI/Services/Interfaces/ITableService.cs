using TapTable.Api.DTOs.Table;

namespace TapTable.Api.Services.Interfaces;

public interface ITableService
{
    Task<IEnumerable<TableDto>> GetTablesAsync(int restaurantId);
    Task<TableDto> GetTableByIdAsync(int tableId, int restaurantId);
    Task<TableDto> CreateTableAsync(int restaurantId, CreateTableDto request);
    Task<TableDto> UpdateTableAsync(int tableId, int restaurantId, UpdateTableDto request);
    Task DeleteTableAsync(int tableId, int restaurantId);

    Task<TableLayoutDto> GetLayoutAsync(int restaurantId);
    Task<TableLayoutDto> UpsertLayoutAsync(int restaurantId, UpsertLayoutDto request);

    Task<string> GenerateQrCodeAsync(int tableId, int restaurantId);
    Task<TableDto> GetTableByQrTokenAsync(string qrToken);
}
