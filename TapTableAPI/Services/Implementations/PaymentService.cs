using Stripe;
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
    private readonly string _publishableKey;
    private readonly string _webhookSecret;
    private readonly string _currency;

    public PaymentService(
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IConfiguration configuration)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _publishableKey = configuration["Stripe:PublishableKey"] ?? string.Empty;
        _webhookSecret = configuration["Stripe:WebhookSecret"] ?? string.Empty;
        _currency = configuration["Stripe:Currency"] ?? "try";
    }

    // ── Garson — manuel ödeme ────────────────────────────────────────────

    public async Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request)
    {
        if (request.Method == PaymentMethod.Stripe)
            throw new ArgumentException("Manuel ödeme için Stripe seçilemez.");

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

    // ── Müşteri — Stripe ─────────────────────────────────────────────────

    public async Task<PaymentIntentResponseDto> CreateStripeIntentAsync(int tableId, CreatePaymentIntentRequestDto request)
    {
        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);
        var remaining = order.TotalPrice - paidSoFar;

        if (remaining <= 0)
            throw new InvalidOperationException("Ödenecek tutar kalmadı.");

        var options = new PaymentIntentCreateOptions
        {
            Amount = (long)(remaining * 100), // en küçük para birimi (kuruş)
            Currency = _currency,
            Metadata = new Dictionary<string, string>
            {
                { "orderId", order.Id.ToString() },
                { "tableId", table.Id.ToString() }
            },
            AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions { Enabled = true }
        };

        var intentService = new PaymentIntentService();
        var intent = await intentService.CreateAsync(options);

        var payment = new Payment
        {
            OrderId = order.Id,
            Amount = remaining,
            Method = PaymentMethod.Stripe,
            SplitType = SplitType.Full,
            Status = PaymentStatus.Pending,
            StripePaymentIntentId = intent.Id,
            CreatedAt = DateTime.UtcNow
        };
        var createdPayment = await _paymentRepository.CreateAsync(payment);

        return new PaymentIntentResponseDto
        {
            PaymentId = createdPayment.Id,
            ClientSecret = intent.ClientSecret,
            PublishableKey = _publishableKey,
            Amount = remaining,
            Currency = _currency
        };
    }

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

    // ── Stripe → backend ─────────────────────────────────────────────────

    public async Task HandleStripeWebhookAsync(string json, string stripeSignatureHeader)
    {
        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, stripeSignatureHeader, _webhookSecret);
        }
        catch (StripeException)
        {
            throw new UnauthorizedAccessException("Geçersiz Stripe imzası.");
        }

        switch (stripeEvent.Type)
        {
            case "payment_intent.succeeded":
                {
                    var intent = stripeEvent.Data.Object as PaymentIntent;
                    if (intent is null) break;

                    var payment = await _paymentRepository.GetByStripeIntentIdAsync(intent.Id);
                    if (payment is null || payment.Status == PaymentStatus.Succeeded) break; // idempotent

                    payment.Status = PaymentStatus.Succeeded;
                    await _paymentRepository.UpdateAsync(payment);

                    var order = await _orderRepository.GetByIdInternalAsync(payment.OrderId);
                    if (order is not null)
                        await SettleOrderIfFullyPaidAsync(order);

                    break;
                }
            case "payment_intent.payment_failed":
                {
                    var intent = stripeEvent.Data.Object as PaymentIntent;
                    if (intent is null) break;

                    var payment = await _paymentRepository.GetByStripeIntentIdAsync(intent.Id);
                    if (payment is null) break;

                    payment.Status = PaymentStatus.Failed;
                    await _paymentRepository.UpdateAsync(payment);
                    break;
                }
        }
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
        StripePaymentIntentId = p.StripePaymentIntentId,
        CreatedAt = p.CreatedAt
    };
}