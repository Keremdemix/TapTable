using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IRestaurantRepository
{
    Task<Restaurant?> GetByIdAsync(int id);
    Task<Restaurant> UpdateAsync(Restaurant restaurant);
}