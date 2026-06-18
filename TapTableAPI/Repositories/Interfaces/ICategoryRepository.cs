using TapTable.Api.Data.Entities;

namespace TapTableAPI.Repositories.Interfaces;

public interface ICategoryRepository
{
    Task<Category?> GetByIdAsync(int id, int restaurantId);
    Task<IEnumerable<Category>> GetAllAsync(int restaurantId);
    Task<Category> CreateAsync(Category category);
    Task<Category> UpdateAsync(Category category);
    Task DeleteAsync(Category category); // soft delete

    /// <summary>
    /// Müşteri menüsü — sadece aktif kategoriler, içlerinde sadece aktif+mevcut ürünler
    /// </summary>
    Task<IEnumerable<Category>> GetPublicMenuAsync(int restaurantId);
}