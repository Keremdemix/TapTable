using TapTable.Api.Data.Entities;
using TapTable.Api.Data.Enums;
using TapTable.Api.DTOs.Order;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class OrderService : IOrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly IMenuRepository _menuRepository;
    private readonly ITableRepository _tableRepository;

    public OrderService(
        IOrderRepository orderRepository,
        IMenuRepository menuRepository,
        ITableRepository tableRepository)
    {
        _orderRepository = orderRepository;
        _menuRepository = menuRepository;
        _tableRepository = tableRepository;
    }

    public async Task<IEnumerable<OrderDto>> GetActiveOrdersAsync(int restaurantId)
    {
        var orders = await _orderRepository.GetActiveOrdersAsync(restaurantId);
        return orders.Select(MapToOrderDto);
    }

    public async Task<IEnumerable<OrderDto>> GetOrderHistoryAsync(int restaurantId, OrderFilterDto filter)
    {
        var orders = await _orderRepository.GetOrderHistoryAsync(restaurantId, filter.StartDate, filter.EndDate, filter.Status);
        return orders.Select(MapToOrderDto);
    }

    public async Task<OrderDto> GetOrderByIdAsync(int orderId, int restaurantId)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");
        return MapToOrderDto(order);
    }

    public async Task<OrderDto> CreateOrderAsync(int restaurantId, int tableId, CreateOrderDto request)
    {
        var table = await _tableRepository.GetTableByIdAsync(tableId, restaurantId)
            ?? throw new KeyNotFoundException("Masa bulunamadı.");

        var orderItems = new List<OrderItem>();
        foreach (var itemRequest in request.Items)
        {
            var menuItem = await _menuRepository.GetMenuItemByIdAsync(itemRequest.MenuItemId, restaurantId)
                ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemRequest.MenuItemId}");

            if (!menuItem.IsAvailable)
                throw new InvalidOperationException($"'{menuItem.Name}' şu an mevcut değil.");

            orderItems.Add(new OrderItem
            {
                MenuItemId = menuItem.Id,
                MenuItemName = menuItem.Name,
                UnitPrice = menuItem.Price,
                Quantity = itemRequest.Quantity,
                Notes = itemRequest.Notes,
                Status = OrderItemStatus.Pending,
                CreatedAt = DateTime.UtcNow
            });
        }

        var order = new Order
        {
            RestaurantId = restaurantId,
            TableId = tableId,
            TableName = table.Name,
            Status = OrderStatus.Pending,
            Notes = request.Notes,
            Items = orderItems,
            TotalAmount = orderItems.Sum(i => i.UnitPrice * i.Quantity),
            CreatedAt = DateTime.UtcNow
        };

        var created = await _orderRepository.CreateOrderAsync(order);
        return MapToOrderDto(created);
    }

    public async Task<OrderDto> AddItemsToOrderAsync(int orderId, int restaurantId, AddOrderItemsDto request)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        if (order.Status is OrderStatus.Delivered or OrderStatus.Cancelled)
            throw new InvalidOperationException("Tamamlanmış veya iptal edilmiş siparişe ürün eklenemez.");

        foreach (var itemRequest in request.Items)
        {
            var menuItem = await _menuRepository.GetMenuItemByIdAsync(itemRequest.MenuItemId, restaurantId)
                ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemRequest.MenuItemId}");

            order.Items.Add(new OrderItem
            {
                OrderId = orderId,
                MenuItemId = menuItem.Id,
                MenuItemName = menuItem.Name,
                UnitPrice = menuItem.Price,
                Quantity = itemRequest.Quantity,
                Notes = itemRequest.Notes,
                Status = OrderItemStatus.Pending,
                CreatedAt = DateTime.UtcNow
            });
        }

        order.TotalAmount = order.Items.Sum(i => i.UnitPrice * i.Quantity);
        order.UpdatedAt = DateTime.UtcNow;

        var updated = await _orderRepository.UpdateOrderAsync(order);
        return MapToOrderDto(updated);
    }

    public async Task<OrderDto> UpdateOrderItemStatusAsync(int orderId, int itemId, int restaurantId, UpdateOrderItemStatusDto request)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        var item = order.Items.FirstOrDefault(i => i.Id == itemId)
            ?? throw new KeyNotFoundException($"Sipariş kalemi bulunamadı: {itemId}");

        item.Status = request.Status;
        item.UpdatedAt = DateTime.UtcNow;
        order.UpdatedAt = DateTime.UtcNow;

        var updated = await _orderRepository.UpdateOrderAsync(order);
        return MapToOrderDto(updated);
    }

    public async Task<OrderDto> UpdateOrderStatusAsync(int orderId, int restaurantId, UpdateOrderStatusDto request)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        order.Status = request.Status;
        order.UpdatedAt = DateTime.UtcNow;

        var updated = await _orderRepository.UpdateOrderAsync(order);
        return MapToOrderDto(updated);
    }

    public async Task CancelOrderAsync(int orderId, int restaurantId)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        if (order.Status == OrderStatus.Delivered)
            throw new InvalidOperationException("Teslim edilmiş sipariş iptal edilemez.");

        order.Status = OrderStatus.Cancelled;
        order.UpdatedAt = DateTime.UtcNow;
        await _orderRepository.UpdateOrderAsync(order);
    }

    public async Task<OrderDto?> GetActiveOrderByTableAsync(int tableId, int restaurantId)
    {
        var order = await _orderRepository.GetActiveOrderByTableAsync(tableId, restaurantId);
        return order is null ? null : MapToOrderDto(order);
    }

    // ── Mapper ───────────────────────────────────────────────────────────────

    private static OrderDto MapToOrderDto(Order o) => new()
    {
        Id = o.Id,
        RestaurantId = o.RestaurantId,
        TableId = o.TableId,
        TableName = o.TableName,
        Status = o.Status,
        Notes = o.Notes,
        TotalAmount = o.TotalAmount,
        Items = o.Items.Select(i => new OrderItemDto
        {
            Id = i.Id,
            MenuItemId = i.MenuItemId,
            MenuItemName = i.MenuItemName,
            UnitPrice = i.UnitPrice,
            Quantity = i.Quantity,
            Notes = i.Notes,
            Status = i.Status
        }).ToList(),
        CreatedAt = o.CreatedAt
    };
}
