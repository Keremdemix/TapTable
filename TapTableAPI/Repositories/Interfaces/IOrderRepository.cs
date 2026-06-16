using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IOrderRepository
{
    Task<Order?> GetOrderByIdAsync(int id);
    Task<List<Order>> GetOrdersByTableAsync(int tableId);
    Task<List<Order>> GetActiveOrdersAsync(int restaurantId);
    Task<Order> CreateOrderAsync(Order order);
    Task UpdateOrderAsync(Order order);
    Task AddOrderItemAsync(OrderItem item);

    Task SaveChangesAsync();
}
