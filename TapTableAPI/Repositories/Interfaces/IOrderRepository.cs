using TapTable.Api.Data.Entities;

public interface IOrderRepository
{
    Task<Order?> GetActiveOrderByTableAsync(int tableId);
    Task<Order?> GetByIdAsync(int orderId, int restaurantId);
    Task<Order?> GetByIdInternalAsync(int orderId); // restoran filtresi yok — sadece webhook gibi güvenilir iç akýþlar için
    Task<IEnumerable<Order>> GetAllAsync(int restaurantId, OrderStatus? status, int? tableId);
    Task<Order> CreateAsync(Order order);
    Task<Order> UpdateAsync(Order order);
    Task<OrderItem?> GetItemAsync(int orderId, int itemId, int restaurantId);
    Task UpdateItemStatusAsync(OrderItem item);
    Task<Order?> GetLatestByTableAsync(int tableId);
}