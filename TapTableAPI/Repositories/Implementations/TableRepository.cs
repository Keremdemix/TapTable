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

    public async Task<List<RestaurantTable>> GetTablesAsync(int restaurantId)
    {
        return await _context.RestaurantTables
            .Include(t => t.Layout)
            .Where(t => t.RestaurantId == restaurantId && t.IsActive)
            .OrderBy(t => t.TableNumber)
            .ToListAsync();
    }

    public async Task<RestaurantTable?> GetTableByIdAsync(int id)
    {
        return await _context.RestaurantTables
            .Include(t => t.Layout)
            .FirstOrDefaultAsync(t => t.Id == id);
    }

    public async Task<RestaurantTable?> GetTableWithActiveOrderAsync(int tableId)
    {
        return await _context.RestaurantTables
            .Include(t => t.Layout)
            .Include(t => t.Orders.Where(o =>
                o.Status != "Delivered" && o.Status != "Cancelled"))
                .ThenInclude(o => o.Items)
            .FirstOrDefaultAsync(t => t.Id == tableId);
    }

    public async Task<bool> TableNumberExistsAsync(int restaurantId, int tableNumber)
    {
        return await _context.RestaurantTables
            .AnyAsync(t => t.RestaurantId == restaurantId && t.TableNumber == tableNumber);
    }

    public async Task<RestaurantTable> CreateTableAsync(RestaurantTable table)
    {
        _context.RestaurantTables.Add(table);
        return table;
    }

    public async Task UpdateTableAsync(RestaurantTable table)
    {
        _context.RestaurantTables.Update(table);
    }

    public async Task UpsertLayoutAsync(TableLayout layout)
    {
        var existing = await _context.TableLayouts
            .FirstOrDefaultAsync(l => l.TableId == layout.TableId);

        if (existing is null)
            _context.TableLayouts.Add(layout);
        else
        {
            existing.PositionX = layout.PositionX;
            existing.PositionY = layout.PositionY;
            existing.Width     = layout.Width;
            existing.Height    = layout.Height;
            existing.Shape     = layout.Shape;
            _context.TableLayouts.Update(existing);
        }
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
