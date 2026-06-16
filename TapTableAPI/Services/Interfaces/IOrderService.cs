using TapTable.Api.DTOs.Order;

namespace TapTable.Api.Services.Interfaces;

public interface IOrderService
{
    // Mutfak / garson ekranı
    Task<IEnumerable<OrderDto>> GetActiveOrdersAsync(int restaurantId);
    Task<IEnumerable<OrderDto>> GetOrderHistoryAsync(int restaurantId, OrderFilterDto filter);
    Task<OrderDto> GetOrderByIdAsync(int orderId, int restaurantId);

    // Müşteri sipariş akışı
    Task<OrderDto> CreateOrderAsync(int restaurantId, int tableId, CreateOrderDto request);
    Task<OrderDto> AddItemsToOrderAsync(int orderId, int restaurantId, AddOrderItemsDto request);
    Task<OrderDto> UpdateOrderItemStatusAsync(int orderId, int itemId, int restaurantId, UpdateOrderItemStatusDto request);
    Task<OrderDto> UpdateOrderStatusAsync(int orderId, int restaurantId, UpdateOrderStatusDto request);
    Task CancelOrderAsync(int orderId, int restaurantId);

    // Masa bazlı
    Task<OrderDto?> GetActiveOrderByTableAsync(int tableId, int restaurantId);
}
