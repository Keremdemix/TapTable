using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface ITableLayoutRepository
{
    Task<TableLayout?> GetByTableIdAsync(int tableId);
    Task<TableLayout> CreateAsync(TableLayout layout);
    Task<TableLayout> UpdateAsync(TableLayout layout);
}