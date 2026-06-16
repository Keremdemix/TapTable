using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class CustomerRepository : ICustomerRepository
{
    private readonly TapTableDbContext _context;

    public CustomerRepository(TapTableDbContext context)
    {
        _context = context;
    }

    // QR okutulunca masa + restoran bilgisi
    public async Task<RestaurantTable?> GetTableWithRestaurantAsync(int tableId)
    {
        return await _context.RestaurantTables
            .Include(t => t.Restaurant)
            .FirstOrDefaultAsync(t => t.Id == tableId && t.IsActive);
    }

    // Sadece aktif ve müsait ürünleri döner
    public async Task<List<Category>> GetMenuWithItemsAsync(int restaurantId)
    {
        return await _context.Categories
            .Include(c => c.MenuItems.Where(m => m.IsAvailable))
            .Where(c => c.RestaurantId == restaurantId && c.IsActive)
            .OrderBy(c => c.SortOrder)
            .ToListAsync();
    }
}
