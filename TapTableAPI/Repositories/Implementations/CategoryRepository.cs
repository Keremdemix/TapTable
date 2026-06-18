using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;
using TapTableAPI.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class CategoryRepository : ICategoryRepository
{
    private readonly TapTableDbContext _context;

    public CategoryRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<Category?> GetByIdAsync(int id, int restaurantId)
    {
        return await _context.Categories
            .FirstOrDefaultAsync(c => c.Id == id && c.RestaurantId == restaurantId && c.IsActive);
    }

    public async Task<IEnumerable<Category>> GetAllAsync(int restaurantId)
    {
        return await _context.Categories
            .Where(c => c.RestaurantId == restaurantId && c.IsActive)
            .OrderBy(c => c.SortOrder)
            .ToListAsync();
    }

    public async Task<Category> CreateAsync(Category category)
    {
        _context.Categories.Add(category);
        await _context.SaveChangesAsync();
        return category;
    }

    public async Task<Category> UpdateAsync(Category category)
    {
        _context.Categories.Update(category);
        await _context.SaveChangesAsync();
        return category;
    }

    public async Task DeleteAsync(Category category)
    {
        category.IsActive = false;
        await _context.SaveChangesAsync();
    }

    public async Task<IEnumerable<Category>> GetPublicMenuAsync(int restaurantId)
    {
        return await _context.Categories
            .Where(c => c.RestaurantId == restaurantId && c.IsActive)
            .Include(c => c.MenuItems.Where(m => m.IsActive && m.IsAvailable))
            .OrderBy(c => c.SortOrder)
            .ToListAsync();
    }
}