using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface ITableRepository
{
    Task<List<RestaurantTable>> GetTablesAsync(int restaurantId);
    Task<RestaurantTable?> GetTableByIdAsync(int id);
    Task<RestaurantTable?> GetTableWithActiveOrderAsync(int tableId);
    Task<bool> TableNumberExistsAsync(int restaurantId, int tableNumber);
    Task<RestaurantTable> CreateTableAsync(RestaurantTable table);
    Task UpdateTableAsync(RestaurantTable table);
    Task UpsertLayoutAsync(TableLayout layout);

    Task SaveChangesAsync();
}
