using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class MenuRepository : IMenuRepository
{
    private readonly TapTableDbContext _context;

    public MenuRepository(TapTableDbContext context)
    {
        _context = context;
    }

    // ── Categories ────────────────────────────────────────────────────────────

    public async Task<List<Category>> GetCategoriesAsync(int restaurantId)
    {
        return await _context.Categories
            .Where(c => c.RestaurantId == restaurantId && c.IsActive)
            .OrderBy(c => c.SortOrder)
            .ToListAsync();
    }

    public async Task<Category?> GetCategoryByIdAsync(int id)
    {
        return await _context.Categories.FindAsync(id);
    }

    public async Task<Category> CreateCategoryAsync(Category category)
    {
        _context.Categories.Add(category);
        return category;
    }

    public async Task DeleteCategoryAsync(Category category)
    {
        _context.Categories.Remove(category);
    }

    // ── Menu Items ────────────────────────────────────────────────────────────

    public async Task<List<MenuItem>> GetMenuItemsAsync(int restaurantId)
    {
        return await _context.MenuItems
            .Include(m => m.Category)
            .Where(m => m.Category.RestaurantId == restaurantId)
            .OrderBy(m => m.Category.SortOrder)
            .ThenBy(m => m.SortOrder)
            .ToListAsync();
    }

    public async Task<List<MenuItem>> GetMenuItemsByCategoryAsync(int categoryId)
    {
        return await _context.MenuItems
            .Where(m => m.CategoryId == categoryId && m.IsAvailable)
            .OrderBy(m => m.SortOrder)
            .ToListAsync();
    }

    public async Task<MenuItem?> GetMenuItemByIdAsync(int id)
    {
        return await _context.MenuItems
            .Include(m => m.Category)
            .FirstOrDefaultAsync(m => m.Id == id);
    }

    public async Task<MenuItem> CreateMenuItemAsync(MenuItem menuItem)
    {
        menuItem.CreatedAt = DateTime.UtcNow;
        menuItem.UpdatedAt = DateTime.UtcNow;
        _context.MenuItems.Add(menuItem);
        return menuItem;
    }

    public async Task UpdateMenuItemAsync(MenuItem menuItem)
    {
        menuItem.UpdatedAt = DateTime.UtcNow;
        _context.MenuItems.Update(menuItem);
    }

    public async Task DeleteMenuItemAsync(MenuItem menuItem)
    {
        _context.MenuItems.Remove(menuItem);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
