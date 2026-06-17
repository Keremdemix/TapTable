using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface ITableRepository
{
    Task<RestaurantTable?> GetByIdAsync(int id, int restaurantId);
    Task<RestaurantTable?> GetByIdAsync(int id); // restoran bilinmeden, QR/public akýþ için
    Task<IEnumerable<RestaurantTable>> GetAllAsync(int restaurantId);
    Task<RestaurantTable> CreateAsync(RestaurantTable table);
    Task<RestaurantTable> UpdateAsync(RestaurantTable table);
    Task DeleteAsync(RestaurantTable table);
}