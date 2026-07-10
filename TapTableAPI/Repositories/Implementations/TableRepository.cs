using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class TableRepository : ITableRepository
{
    private readonly TapTableDbContext _context;

    public TableRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<RestaurantTable?> GetByIdAsync(int id, int restaurantId)
    {
        return await _context.RestaurantTables
            .FirstOrDefaultAsync(t => t.Id == id
                                   && t.RestaurantId == restaurantId
                                   && t.IsActive);
    }

    public async Task<IEnumerable<RestaurantTable>> GetAllAsync(int restaurantId)
    {
        return await _context.RestaurantTables
            .Include(t => t.Layout)              // ← EKLENDİ
            .Where(t => t.RestaurantId == restaurantId && t.IsActive)
            .OrderBy(t => t.TableNumber)
            .ToListAsync();
    }

    public async Task<RestaurantTable> CreateAsync(RestaurantTable table)
    {
        _context.RestaurantTables.Add(table);
        await _context.SaveChangesAsync();
        return table;
    }

    public async Task<RestaurantTable> UpdateAsync(RestaurantTable table)
    {
        table.UpdatedAt = DateTime.UtcNow;
        _context.RestaurantTables.Update(table);
        await _context.SaveChangesAsync();
        return table;
    }

    public async Task DeleteAsync(RestaurantTable table)
    {
        table.IsActive = false;
        table.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
    public async Task<RestaurantTable?> GetByIdAsync(int id)
    {
        return await _context.RestaurantTables
            .Include(t => t.Restaurant)
            .FirstOrDefaultAsync(t => t.Id == id && t.IsActive);
    }
    public async Task<RestaurantTable?> GetByQrTokenAsync(string qrToken)
    {
        return await _context.RestaurantTables
            .Include(t => t.Restaurant)
            .FirstOrDefaultAsync(t => t.QrToken == qrToken && t.IsActive);
    }
}