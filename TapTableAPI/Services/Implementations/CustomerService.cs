using TapTable.Api.DTOs.Customer;
using TapTable.Api.DTOs.Menu;
using TapTable.Api.DTOs.Order;
using TapTable.Api.DTOs.Payment;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CustomerService : ICustomerService
{
    private readonly ICustomerRepository _customerRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly IPaymentService _paymentService;

    public CustomerService(
        ICustomerRepository customerRepository,
        ITableRepository tableRepository,
        IOrderRepository orderRepository,
        IPaymentService paymentService)
    {
        _customerRepository = customerRepository;
        _tableRepository = tableRepository;
        _orderRepository = orderRepository;
        _paymentService = paymentService;
    }

    public async Task<CustomerSessionDto> StartSessionAsync(string qrToken)
    {
        var table = await _tableRepository.GetTableByQrTokenAsync(qrToken)
            ?? throw new KeyNotFoundException("Geçersiz QR kodu.");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        return new CustomerSessionDto
        {
            TableId = table.Id,
            TableName = table.Name,
            RestaurantId = table.RestaurantId,
            QrToken = qrToken
        };
    }

    public async Task<MenuWithItemsDto> GetMenuAsync(string qrToken)
    {
        var table = await ResolveTableAsync(qrToken);

        var menus = await _customerRepository.GetMenuWithItemsAsync(table.RestaurantId);

        return new MenuWithItemsDto
        {
            RestaurantId = table.RestaurantId,
            Menus = menus.Select(m => new MenuWithItemsItemDto
            {
                Id = m.Id,
                Name = m.Name,
                Description = m.Description,
                Items = m.Items
                    .Where(i => i.IsAvailable)
                    .Select(i => new MenuItemDto
                    {
                        Id = i.Id,
                        MenuId = i.MenuId,
                        Name = i.Name,
                        Description = i.Description,
                        Price = i.Price,
                        ImageUrl = i.ImageUrl,
                        IsAvailable = i.IsAvailable,
                        CreatedAt = i.CreatedAt
                    }).ToList()
            }).ToList()
        };
    }

    public async Task<OrderDto> PlaceOrderAsync(string qrToken, CustomerPlaceOrderDto request)
    {
        var table = await ResolveTableAsync(qrToken);

        // Masada aktif sipariş varsa üzerine ekle, yoksa yeni oluştur
        var activeOrder = await _orderRepository.GetActiveOrderByTableAsync(table.Id, table.RestaurantId);

        if (activeOrder is not null)
        {
            var addDto = new AddOrderItemsDto
            {
                Items = request.Items.Select(i => new CreateOrderItemDto
                {
                    MenuItemId = i.MenuItemId,
                    Quantity = i.Quantity,
                    Notes = i.Notes
                }).ToList()
            };
            var updated = await _customerRepository.AddItemsToOrderAsync(activeOrder.Id, addDto);
            return MapToOrderDto(updated);
        }

        var createDto = new CreateOrderDto
        {
            Items = request.Items.Select(i => new CreateOrderItemDto
            {
                MenuItemId = i.MenuItemId,
                Quantity = i.Quantity,
                Notes = i.Notes
            }).ToList(),
            Notes = request.Notes
        };
        var created = await _customerRepository.CreateOrderAsync(table.RestaurantId, table.Id, createDto);
        return MapToOrderDto(created);
    }

    public async Task<OrderDto?> GetMyActiveOrderAsync(string qrToken)
    {
        var table = await ResolveTableAsync(qrToken);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id, table.RestaurantId);
        return order is null ? null : MapToOrderDto(order);
    }

    public async Task<OrderDto> TrackOrderAsync(string qrToken, int orderId)
    {
        var table = await ResolveTableAsync(qrToken);

        var order = await _orderRepository.GetOrderByIdAsync(orderId, table.RestaurantId)
            ?? throw new KeyNotFoundException("Sipariş bulunamadı.");

        // Güvenlik: sadece kendi masasının siparişine bakabilir
        if (order.TableId != table.Id)
            throw new UnauthorizedAccessException("Bu siparişe erişim yetkiniz yok.");

        return MapToOrderDto(order);
    }

    public async Task<PaymentSummaryDto> GetBillAsync(string qrToken)
    {
        var table = await ResolveTableAsync(qrToken);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id, table.RestaurantId)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        return new PaymentSummaryDto
        {
            OrderId = order.Id,
            TableName = order.TableName,
            Items = order.Items.Select(i => new BillItemDto
            {
                Name = i.MenuItemName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                Total = i.UnitPrice * i.Quantity
            }).ToList(),
            TotalAmount = order.TotalAmount
        };
    }

    public async Task<PaymentIntentDto> RequestPaymentAsync(string qrToken)
    {
        var table = await ResolveTableAsync(qrToken);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id, table.RestaurantId)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        return await _paymentService.CreatePaymentIntentAsync(
            order.Id,
            table.RestaurantId,
            new CreatePaymentIntentDto()
        );
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private async Task<Data.Entities.Table> ResolveTableAsync(string qrToken)
    {
        var table = await _tableRepository.GetTableByQrTokenAsync(qrToken)
            ?? throw new KeyNotFoundException("Geçersiz QR kodu.");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        return table;
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
