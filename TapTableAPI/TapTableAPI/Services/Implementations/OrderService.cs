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

    public async Task<OrderResponseDto> PlaceOrderAsync(string token, PlaceOrderRequestDto request)
    {
        var table = await ValidateTokenAsync(token);
        var order = await CreateOrAppendOrderAsync(table, waiterId: null, request.Items, request.Note);
        return MapToDto(order);
    }

    public async Task<OrderResponseDto?> GetActiveOrderAsync(string token)
    {
        var table = await ValidateTokenAsync(token);
        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id);
        return order is null ? null : MapToDto(order);
    }

    public async Task<OrderResponseDto> TrackOrderAsync(string token, int orderId)
    {
        var table = await ValidateTokenAsync(token);

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

        var derivedStatus = DeriveOrderStatus(order.Items);
        if (derivedStatus.HasValue && order.Status != derivedStatus.Value)
        {
            order.Status = derivedStatus.Value;
            order = await _orderRepository.UpdateAsync(order);
        }

        // Ödeme zaten alınmışsa ve bu değişiklikle birlikte artık tüm
        // (iptal hariç) ürünler Served olduysa siparişi kapat ve masayı boşalt.
        order = await TryCompleteIfPaidAndServedAsync(order, restaurantId);

        return MapToDto(order);
    }

    /// <summary>
    /// Garson masa detayında "Teslim Edildi" dediğinde çağrılır. O masaya ait
    /// aktif siparişte SADECE Ready durumundaki ürünleri Served yapar, diğer
    /// durumdaki (Pending/Preparing/Served/Cancelled) ürünlere dokunmaz.
    /// PATCH /api/orders/tables/{tableId}/serve-ready-items
    /// </summary>
    public async Task<OrderResponseDto> ServeReadyItemsByTableAsync(int tableId, int restaurantId)
    {
        var order = await _orderRepository.GetActiveOrderByTableAsync(tableId)
            ?? throw new KeyNotFoundException($"Bu masada aktif sipariş yok: {tableId}");

        if (order.Table.RestaurantId != restaurantId)
            throw new UnauthorizedAccessException("Bu masaya erişim yetkiniz yok.");

        var readyItems = order.Items.Where(i => i.Status == OrderItemStatus.Ready).ToList();
        if (readyItems.Count > 0)
        {
            foreach (var item in readyItems)
                item.Status = OrderItemStatus.Served;

            var derivedStatus = DeriveOrderStatus(order.Items);
            if (derivedStatus.HasValue)
                order.Status = derivedStatus.Value;

            order = await _orderRepository.UpdateAsync(order);
        }

        // Ödeme zaten Paid ise ve artık tüm ürünler Served olduysa siparişi
        // kapat ve masayı boşalt (bkz. TryCompleteIfPaidAndServedAsync).
        order = await TryCompleteIfPaidAndServedAsync(order, restaurantId);

        return MapToDto(order);
    }

    /// <summary>
    /// Garson/Admin siparişin genel durumunu ELLE değiştirir (örn. Cancelled).
    /// Completed durumuna manuel geçiş de destekleniyor, ancak normal akışta
    /// sipariş Paid + tüm ürünler Served olduğunda zaten otomatik kapanır
    /// (bkz. TryCompleteIfPaidAndServedAsync) — bu metot elle müdahale içindir.
    /// PATCH /api/orders/{id}/status
    /// </summary>
    public async Task<OrderResponseDto> UpdateOrderStatusAsync(int orderId, int restaurantId, OrderStatus status)
    {
        var order = await _orderRepository.GetByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        order.Status = status;

        // Sipariş elle kapatılıyorsa (ödendi/iptal) masa tekrar müsait olsun.
        if (status == OrderStatus.Completed || status == OrderStatus.Cancelled)
        {
            var table = await _tableRepository.GetByIdAsync(order.TableId, restaurantId);
            if (table is not null)
            {
                table.Status = TableStatus.Available;
                await _tableRepository.UpdateAsync(table);
            }

            await _qrSessionRepository.RotateSessionAsync(order.TableId, restaurantId);
        }

        var updated = await _orderRepository.UpdateAsync(order);
        return MapToDto(updated);
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    /// Sipariş durumunu, içindeki ürünlerin durumlarından türetir.
    /// İptal edilen ürünler hesaba katılmaz (tamamen iptal edilmiş bir sipariş
    /// ayrı bir akışla — UpdateOrderStatusAsync ile — Cancelled yapılır).
    private static OrderStatus? DeriveOrderStatus(ICollection<OrderItem> items)
    {
        var relevant = items.Where(i => i.Status != OrderItemStatus.Cancelled).ToList();
        if (relevant.Count == 0)
            return null; // hepsi iptal — burada karar vermiyoruz

        if (relevant.All(i => i.Status == OrderItemStatus.Served))
            return OrderStatus.Served;

        if (relevant.All(i => i.Status == OrderItemStatus.Ready || i.Status == OrderItemStatus.Served))
            return OrderStatus.Ready;

        if (relevant.Any(i => i.Status == OrderItemStatus.Preparing || i.Status == OrderItemStatus.Ready || i.Status == OrderItemStatus.Served))
            return OrderStatus.Preparing;

        return OrderStatus.Pending;
    }

    /// Bir sipariş "kapanabilir" (Completed + masa Available) sayılması için
    /// HEM ödemesi Paid olmalı HEM DE (iptal hariç) tüm ürünler Served olmalı.
    /// Bu iki koşuldan biri eksikse sipariş açık, masa Dolu kalmaya devam eder.
    private static bool AllRelevantItemsServed(ICollection<OrderItem> items)
    {
        var relevant = items.Where(i => i.Status != OrderItemStatus.Cancelled).ToList();
        return relevant.Count > 0 && relevant.All(i => i.Status == OrderItemStatus.Served);
    }

    /// Ödeme zaten Paid ise ve tüm (iptal hariç) ürünler artık Served ise
    /// siparişi Completed yapar, masayı Available'a çevirir ve QR session'ı
    /// döndürür. Bu, hem "önce ödeme sonra teslim" hem "önce teslim sonra
    /// ödeme" sıralarının ikisinde de doğru anda masayı kapatmasını sağlar —
    /// çağıran taraf (item status update veya PaymentService) hangisi son
    /// gerçekleşirse bu metodu tetikler.
    private async Task<Order> TryCompleteIfPaidAndServedAsync(Order order, int restaurantId)
    {
        if (order.Status == OrderStatus.Completed) return order;
        if (order.PaymentStatus != OrderPaymentStatus.Paid) return order;
        if (!AllRelevantItemsServed(order.Items)) return order;

        order.Status = OrderStatus.Completed;

        var table = await _tableRepository.GetByIdAsync(order.TableId, restaurantId);
        if (table is not null)
        {
            table.Status = TableStatus.Available;
            await _tableRepository.UpdateAsync(table);
        }

        await _qrSessionRepository.RotateSessionAsync(order.TableId, restaurantId);

        return await _orderRepository.UpdateAsync(order);
    }

    private async Task<RestaurantTable> ValidateTokenAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrSessionRepository.GetActiveByKeyAsync(token)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        var table = await _tableRepository.GetByIdAsync(session.TableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {session.TableId}");

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
            MenuItemImageUrl = i.MenuItem?.ImageUrl,
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