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

    public async Task<Order?> GetOrderByIdAsync(int id)
    {
        return await _context.Orders
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .Include(o => o.Items)
                .ThenInclude(i => i.MenuItem)
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == id);
    }

    public async Task<List<Order>> GetOrdersByTableAsync(int tableId)
    {
        return await _context.Orders
            .Include(o => o.Items)
                .ThenInclude(i => i.MenuItem)
            .Where(o => o.TableId == tableId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
    }

    public async Task<List<Order>> GetActiveOrdersAsync(int restaurantId)
    {
        return await _context.Orders
            .Include(o => o.Table)
            .Include(o => o.Waiter)
            .Include(o => o.Items)
                .ThenInclude(i => i.MenuItem)
            .Where(o =>
                o.Table.RestaurantId == restaurantId &&
                o.Status != "Delivered" &&
                o.Status != "Cancelled")
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
    }

    public async Task<Order> CreateOrderAsync(Order order)
    {
        order.CreatedAt = DateTime.UtcNow;
        order.UpdatedAt = DateTime.UtcNow;
        _context.Orders.Add(order);
        return order;
    }

    public async Task UpdateOrderAsync(Order order)
    {
        order.UpdatedAt = DateTime.UtcNow;
        _context.Orders.Update(order);
    }

    public async Task AddOrderItemAsync(OrderItem item)
    {
        _context.OrderItems.Add(item);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
