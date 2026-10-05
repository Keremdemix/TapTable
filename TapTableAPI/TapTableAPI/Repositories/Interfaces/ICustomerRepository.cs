using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface ICustomerRepository
{
    Task<RestaurantTable?> GetTableWithRestaurantAsync(int tableId);
    Task<List<Category>> GetMenuWithItemsAsync(int restaurantId);
}
