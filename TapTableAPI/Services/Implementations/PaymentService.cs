using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class PaymentService : IPaymentService
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;
    private readonly IRestaurantRepository _restaurantRepository;

    public PaymentService(
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IRestaurantRepository restaurantRepository)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _restaurantRepository = restaurantRepository;

    }

    // ── Garson — manuel ödeme ────────────────────────────────────────────

    public async Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request)
    {
        if (request.Method == PaymentMethod.Iyzico)
            throw new ArgumentException("Manuel ödeme için Iyzico seçilemez.");

        if (request.Amount <= 0)
            throw new ArgumentException("Tutar sıfırdan büyük olmalı.");

        var order = await _orderRepository.GetByIdAsync(request.OrderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {request.OrderId}");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var payment = new Payment
        {
            OrderId = order.Id,
            Amount = request.Amount,
            Method = request.Method,
            SplitType = SplitType.Full,
            Status = PaymentStatus.Succeeded, // garson zaten parayı fiziksel olarak aldı
            CreatedAt = DateTime.UtcNow
        };

        var created = await _paymentRepository.CreateAsync(payment);
        await SettleOrderIfFullyPaidAsync(order);

        return MapToDto(created);
    }

    public async Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId)
    {
        var payments = await _paymentRepository.GetByOrderIdAsync(orderId, restaurantId);
        return payments.Select(MapToDto);
    }

    // ── Müşteri — Iyzico ─────────────────────────────────────────────────

       public async Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey)
    {
        var table = await ValidateSessionAsync(tableId, sessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);

        return new BillSummaryResponseDto
        {
            OrderId = order.Id,
            TableNumber = table.TableNumber,
            Items = order.Items.Select(i => new BillItemDto
            {
                Name = i.MenuItem?.Name ?? string.Empty,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                LineTotal = i.UnitPrice * i.Quantity
            }).ToList(),
            TotalPrice = order.TotalPrice,
            PaidAmount = paidSoFar,
            RemainingAmount = order.TotalPrice - paidSoFar,
            PaymentStatus = order.PaymentStatus.ToString()
        };
    }
  
    // ── Helpers ──────────────────────────────────────────────────────────

    private async Task SettleOrderIfFullyPaidAsync(Order order)
    {
        var totalPaid = await _paymentRepository.GetSucceededTotalAsync(order.Id);

        order.PaymentStatus = totalPaid >= order.TotalPrice
            ? OrderPaymentStatus.Paid
            : OrderPaymentStatus.PartiallyPaid;

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
        {
            order.Status = OrderStatus.Completed;

            var table = await _tableRepository.GetByIdAsync(order.TableId, order.Table.RestaurantId);
            if (table is not null)
            {
                table.Status = TableStatus.Available;
                await _tableRepository.UpdateAsync(table);
            }
        }

        await _orderRepository.UpdateAsync(order);
    }

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

        return table;
    }

    private static PaymentResponseDto MapToDto(Payment p) => new()
    {
        Id = p.Id,
        OrderId = p.OrderId,
        Amount = p.Amount,
        Method = p.Method.ToString(),
        SplitType = p.SplitType.ToString(),
        Status = p.Status.ToString(),
        IyzicoPaymentId = p.IyzicoPaymentId,
        CreatedAt = p.CreatedAt
    };
}