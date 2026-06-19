using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Order;
using TapTable.Api.DTOs.Response.Order;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class OrderService : IOrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly IMenuItemRepository _menuItemRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;

    public OrderService(
        IOrderRepository orderRepository,
        IMenuItemRepository menuItemRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository)
    {
        _orderRepository = orderRepository;
        _menuItemRepository = menuItemRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
    }

    // ── Müşteri — Public ─────────────────────────────────────────────────

    public async Task<OrderResponseDto> PlaceOrderAsync(int tableId, PlaceOrderRequestDto request)
    {
        var table = await ValidateSessionAsync(tableId, request.SessionKey);
        var order = await CreateOrAppendOrderAsync(table, waiterId: null, request.Items, request.Note);
        return MapToDto(order);
    }

    public async Task<OrderResponseDto?> GetActiveOrderAsync(int tableId, string sessionKey)
    {
        var table = await ValidateSessionAsync(tableId, sessionKey);
        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id);
        return order is null ? null : MapToDto(order);
    }

    public async Task<OrderResponseDto> TrackOrderAsync(int tableId, string sessionKey, int orderId)
    {
        var table = await ValidateSessionAsync(tableId, sessionKey);

        var order = await _orderRepository.GetByIdAsync(orderId, table.RestaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        if (order.TableId != table.Id)
            throw new UnauthorizedAccessException("Bu siparişe erişim yetkiniz yok.");

        return MapToDto(order);
    }

    // ── Personel — Waiter/Kitchen/Admin ─────────────────────────────────

    public async Task<OrderResponseDto> CreateOrderByStaffAsync(int restaurantId, int? waiterId, StaffCreateOrderRequestDto request)
    {
        var table = await _tableRepository.GetByIdAsync(request.TableId, restaurantId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {request.TableId}");

        var order = await CreateOrAppendOrderAsync(table, waiterId, request.Items, request.Note);
        return MapToDto(order);
    }

    public async Task<IEnumerable<OrderResponseDto>> GetOrdersAsync(int restaurantId, OrderStatus? status, int? tableId)
    {
        var orders = await _orderRepository.GetAllAsync(restaurantId, status, tableId);
        return orders.Select(MapToDto);
    }

    public async Task<OrderResponseDto> GetOrderAsync(int orderId, int restaurantId)
    {
        var order = await _orderRepository.GetByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        return MapToDto(order);
    }

    public async Task<OrderResponseDto> UpdateOrderItemStatusAsync(int orderId, int itemId, int restaurantId, OrderItemStatus status)
    {
        var item = await _orderRepository.GetItemAsync(orderId, itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş kalemi bulunamadı: {itemId}");

        item.Status = status;
        await _orderRepository.UpdateItemStatusAsync(item);

        var order = await _orderRepository.GetByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        return MapToDto(order);
    }

    public async Task<OrderResponseDto> UpdateOrderStatusAsync(int orderId, int restaurantId, OrderStatus status)
    {
        var order = await _orderRepository.GetByIdAsync(orderId, restaurantId)
        ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        if (status == OrderStatus.Completed && order.PaymentStatus != OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Ödeme tamamlanmadan sipariş kapatılamaz.");

        order.Status = status;

        // Sipariş kapanınca (ödendi/iptal) masa tekrar müsait olsun
        if (status == OrderStatus.Completed || status == OrderStatus.Cancelled)
        {
            var table = await _tableRepository.GetByIdAsync(order.TableId, restaurantId);
            if (table is not null)
            {
                table.Status = TableStatus.Available;
                await _tableRepository.UpdateAsync(table);
            }
        }

        var updated = await _orderRepository.UpdateAsync(order);
        return MapToDto(updated);
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private async Task<RestaurantTable> ValidateSessionAsync(int tableId, string sessionKey)
    {
        if (string.IsNullOrWhiteSpace(sessionKey))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrSessionRepository.GetActiveByKeyAsync(sessionKey)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        if (session.TableId != tableId)
            throw new UnauthorizedAccessException("Oturum bu masaya ait değil.");

        var table = await _tableRepository.GetByIdAsync(tableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        return table;
    }

    private async Task<Order> CreateOrAppendOrderAsync(
        RestaurantTable table,
        int? waiterId,
        List<OrderItemRequestDto> requestItems,
        string? note)
    {
        if (requestItems is null || requestItems.Count == 0)
            throw new ArgumentException("Sipariş en az bir ürün içermeli.");

        if (requestItems.Any(i => i.Quantity <= 0))
            throw new ArgumentException("Ürün adedi sıfırdan büyük olmalı.");

        // Fiyatlar ve mevcutluk DB'den doğrulanır — müşteriden gelen fiyata güvenilmez
        var menuItemIds = requestItems.Select(i => i.MenuItemId).Distinct();
        var menuItems = await _menuItemRepository.GetByIdsAsync(menuItemIds, table.RestaurantId);

        foreach (var requested in requestItems)
        {
            var menuItem = menuItems.FirstOrDefault(m => m.Id == requested.MenuItemId)
                ?? throw new KeyNotFoundException($"Ürün bulunamadı: {requested.MenuItemId}");

            if (!menuItem.IsAvailable)
                throw new InvalidOperationException($"'{menuItem.Name}' şu an mevcut değil.");
        }

        var newItems = requestItems.Select(requested =>
        {
            var menuItem = menuItems.First(m => m.Id == requested.MenuItemId);
            return new OrderItem
            {
                MenuItemId = menuItem.Id,
                Quantity = requested.Quantity,
                UnitPrice = menuItem.Price,
                Note = requested.Note,
                Status = OrderItemStatus.Pending
            };
        }).ToList();

        var activeOrder = await _orderRepository.GetActiveOrderByTableAsync(table.Id);

        if (activeOrder is null)
        {
            var order = new Order
            {
                TableId = table.Id,
                WaiterId = waiterId,
                Status = OrderStatus.Pending,
                PaymentStatus = OrderPaymentStatus.Unpaid,
                Note = note,
                CreatedAt = DateTime.UtcNow,
                Items = newItems
            };
            order.TotalPrice = order.Items.Sum(i => i.UnitPrice * i.Quantity);

            var created = await _orderRepository.CreateAsync(order);

            table.Status = TableStatus.Occupied;
            await _tableRepository.UpdateAsync(table);

            return created;
        }

        // Mevcut siparişe ekleme — ilk kez bir personel dokunuyorsa garson ataması yapılır
        if (waiterId.HasValue && activeOrder.WaiterId is null)
            activeOrder.WaiterId = waiterId;

        foreach (var item in newItems)
            activeOrder.Items.Add(item);

        if (!string.IsNullOrWhiteSpace(note))
            activeOrder.Note = note;

        activeOrder.TotalPrice = activeOrder.Items.Sum(i => i.UnitPrice * i.Quantity);

        return await _orderRepository.UpdateAsync(activeOrder);
    }

    // ── Mapper ───────────────────────────────────────────────────────────

    private static OrderResponseDto MapToDto(Order o) => new()
    {
        Id = o.Id,
        TableId = o.TableId,
        TableNumber = o.Table?.TableNumber ?? 0,
        WaiterId = o.WaiterId,
        WaiterName = o.Waiter?.FullName,
        Status = o.Status.ToString(),
        PaymentStatus = o.PaymentStatus.ToString(),
        TotalPrice = o.TotalPrice,
        Note = o.Note,
        Items = o.Items.Select(i => new OrderItemResponseDto
        {
            Id = i.Id,
            MenuItemId = i.MenuItemId,
            MenuItemName = i.MenuItem?.Name ?? string.Empty,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            LineTotal = i.UnitPrice * i.Quantity,
            Note = i.Note,
            Status = i.Status.ToString()
        }).ToList(),
        CreatedAt = o.CreatedAt,
        UpdatedAt = o.UpdatedAt
    };
}