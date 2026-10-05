using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class MenuItemRepository : IMenuItemRepository
{
    private readonly TapTableDbContext _context;

    public MenuItemRepository(TapTableDbContext context)
    {
        _context = context;
    }

    // MenuItem'da RestaurantId yok, Category üzerinden join ile doğrulanıyor
    public async Task<MenuItem?> GetByIdAsync(int id, int restaurantId)
    {
        return await _context.MenuItems
            .Include(m => m.Category)
            .FirstOrDefaultAsync(m => m.Id == id
                                   && m.Category.RestaurantId == restaurantId
                                   && m.IsActive);
    }

    public async Task<List<MenuItem>> GetByIdsAsync(IEnumerable<int> ids, int restaurantId)
    {
        var idList = ids.ToList();
        return await _context.MenuItems
            .Include(m => m.Category)
            .Where(m => idList.Contains(m.Id) && m.Category.RestaurantId == restaurantId && m.IsActive)
            .ToListAsync();
    }

    public async Task<IEnumerable<MenuItem>> GetAllAsync(int restaurantId, int? categoryId = null)
    {
        var query = _context.MenuItems
            .Include(m => m.Category)
            .Where(m => m.Category.RestaurantId == restaurantId && m.IsActive);

        if (categoryId.HasValue)
            query = query.Where(m => m.CategoryId == categoryId.Value);

        return await query.OrderBy(m => m.SortOrder).ToListAsync();
    }

    public async Task<MenuItem> CreateAsync(MenuItem item)
    {
        _context.MenuItems.Add(item);
        await _context.SaveChangesAsync();
        return item;
    }

    public async Task<MenuItem> UpdateAsync(MenuItem item)
    {
        item.UpdatedAt = DateTime.UtcNow;
        _context.MenuItems.Update(item);
        await _context.SaveChangesAsync();
        return item;
    }

    public async Task DeleteAsync(MenuItem item)
    {
        item.IsActive = false;
        item.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    public async Task<int> CountByCategoryAsync(int categoryId)
    {
        return await _context.MenuItems
            .CountAsync(m => m.CategoryId == categoryId && m.IsActive);
    }
}