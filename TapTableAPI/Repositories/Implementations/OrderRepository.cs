using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class OrderRepository : IOrderRepository
{
    private readonly TapTableDbContext _context;

    public OrderRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<Order?> GetActiveOrderByTableAsync(int tableId)
    {
        return await _context.Orders
            .Include(o => o.Items).ThenInclude(i => i.MenuItem)
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .Where(o => o.TableId == tableId
                     && o.Status != OrderStatus.Completed
                     && o.Status != OrderStatus.Cancelled)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<Order?> GetByIdAsync(int orderId, int restaurantId)
    {
        return await _context.Orders
            .Include(o => o.Items).ThenInclude(i => i.MenuItem)
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.Table.RestaurantId == restaurantId);
    }

    public async Task<IEnumerable<Order>> GetAllAsync(int restaurantId, OrderStatus? status, int? tableId)
    {
        var query = _context.Orders
            .Include(o => o.Items).ThenInclude(i => i.MenuItem)
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .Where(o => o.Table.RestaurantId == restaurantId);

        if (status.HasValue)
            query = query.Where(o => o.Status == status.Value);

        if (tableId.HasValue)
            query = query.Where(o => o.TableId == tableId.Value);

        return await query.OrderByDescending(o => o.CreatedAt).ToListAsync();
    }

    public async Task<Order> CreateAsync(Order order)
    {
        _context.Orders.Add(order);
        await _context.SaveChangesAsync();
        return order;
    }

    public async Task<Order> UpdateAsync(Order order)
    {
        order.UpdatedAt = DateTime.UtcNow;
        _context.Orders.Update(order);
        await _context.SaveChangesAsync();
        return order;
    }

    public async Task<OrderItem?> GetItemAsync(int orderId, int itemId, int restaurantId)
    {
        return await _context.OrderItems
            .Include(i => i.Order)
            .Include(i => i.MenuItem)
            .FirstOrDefaultAsync(i => i.Id == itemId
                                   && i.OrderId == orderId
                                   && i.Order.Table.RestaurantId == restaurantId);
    }

    public async Task UpdateItemStatusAsync(OrderItem item)
    {
        _context.OrderItems.Update(item);
        await _context.SaveChangesAsync();
    }
    public async Task<Order?> GetByIdInternalAsync(int orderId)
    {
        return await _context.Orders
            .Include(o => o.Items).ThenInclude(i => i.MenuItem)
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }
    public async Task<Order?> GetLatestByTableAsync(int tableId)
    {
        return await _context.Orders
            .Include(o => o.Items).ThenInclude(i => i.MenuItem)
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .Where(o => o.TableId == tableId)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();
    }
}