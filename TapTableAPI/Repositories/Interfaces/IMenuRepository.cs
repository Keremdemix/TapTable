using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IMenuRepository
{
    // Categories
    Task<List<Category>> GetCategoriesAsync(int restaurantId);
    Task<Category?> GetCategoryByIdAsync(int id);
    Task<Category> CreateCategoryAsync(Category category);
    Task DeleteCategoryAsync(Category category);

    // Menu Items
    Task<List<MenuItem>> GetMenuItemsAsync(int restaurantId);
    Task<List<MenuItem>> GetMenuItemsByCategoryAsync(int categoryId);
    Task<MenuItem?> GetMenuItemByIdAsync(int id);
    Task<MenuItem> CreateMenuItemAsync(MenuItem menuItem);
    Task UpdateMenuItemAsync(MenuItem menuItem);
    Task DeleteMenuItemAsync(MenuItem menuItem);

    Task SaveChangesAsync();
}
