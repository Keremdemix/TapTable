using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IMenuItemRepository
{
    Task<MenuItem?> GetByIdAsync(int id, int restaurantId);
    Task<IEnumerable<MenuItem>> GetAllAsync(int restaurantId, int? categoryId = null);
    Task<MenuItem> CreateAsync(MenuItem item);
    Task<MenuItem> UpdateAsync(MenuItem item);
    Task DeleteAsync(MenuItem item); // soft delete
    Task<int> CountByCategoryAsync(int categoryId);
}