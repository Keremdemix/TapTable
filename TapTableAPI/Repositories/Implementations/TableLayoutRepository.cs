using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class TableLayoutRepository : ITableLayoutRepository
{
    private readonly TapTableDbContext _context;

    public TableLayoutRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<TableLayout?> GetByTableIdAsync(int tableId)
    {
        return await _context.TableLayouts.FirstOrDefaultAsync(l => l.TableId == tableId);
    }

    public async Task<TableLayout> CreateAsync(TableLayout layout)
    {
        _context.TableLayouts.Add(layout);
        await _context.SaveChangesAsync();
        return layout;
    }

    public async Task<TableLayout> UpdateAsync(TableLayout layout)
    {
        _context.TableLayouts.Update(layout);
        await _context.SaveChangesAsync();
        return layout;
    }
}