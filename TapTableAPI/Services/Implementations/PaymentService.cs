using Microsoft.Extensions.Options;
using Stripe;
using TapTable.Api.Configuration;
using TapTable.Api.Data.Entities;
using TapTable.Api.Data.Enums;
using TapTable.Api.DTOs.Payment;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class PaymentService : IPaymentService
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly StripeSettings _stripeSettings;

    public PaymentService(
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        IOptions<StripeSettings> stripeSettings)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _stripeSettings = stripeSettings.Value;
        StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
    }

    public async Task<PaymentIntentDto> CreatePaymentIntentAsync(int orderId, int restaurantId, CreatePaymentIntentDto request)
    {
        var order = await _orderRepository.GetOrderByIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {orderId}");

        var options = new PaymentIntentCreateOptions
        {
            Amount = (long)(order.TotalAmount * 100), // kuruş
            Currency = "try",
            Metadata = new Dictionary<string, string>
            {
                { "orderId", orderId.ToString() },
                { "restaurantId", restaurantId.ToString() }
            }
        };

        var service = new PaymentIntentService();
        var intent = await service.CreateAsync(options);

        return new PaymentIntentDto
        {
            ClientSecret = intent.ClientSecret,
            PaymentIntentId = intent.Id,
            Amount = order.TotalAmount
        };
    }

    public async Task<PaymentDto> ConfirmPaymentAsync(string stripePaymentIntentId)
    {
        var payment = await _paymentRepository.GetPaymentByStripeIntentIdAsync(stripePaymentIntentId)
            ?? throw new KeyNotFoundException("Ödeme kaydı bulunamadı.");

        payment.Status = PaymentStatus.Completed;
        payment.PaidAt = DateTime.UtcNow;
        payment.UpdatedAt = DateTime.UtcNow;

        var updated = await _paymentRepository.UpdatePaymentAsync(payment);
        return MapToPaymentDto(updated);
    }

    public async Task<PaymentDto> GetPaymentByOrderIdAsync(int orderId, int restaurantId)
    {
        var payment = await _paymentRepository.GetPaymentByOrderIdAsync(orderId, restaurantId)
            ?? throw new KeyNotFoundException($"Ödeme bulunamadı. Sipariş: {orderId}");
        return MapToPaymentDto(payment);
    }

    public async Task HandleStripeWebhookAsync(string payload, string stripeSignature)
    {
        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(payload, stripeSignature, _stripeSettings.WebhookSecret);
        }
        catch (StripeException)
        {
            throw new UnauthorizedAccessException("Geçersiz Stripe webhook imzası.");
        }

        if (stripeEvent.Type == Events.PaymentIntentSucceeded)
        {
            var intent = stripeEvent.Data.Object as PaymentIntent;
            if (intent is null) return;

            var payment = await _paymentRepository.GetPaymentByStripeIntentIdAsync(intent.Id);
            if (payment is null)
            {
                // İlk kez webhook geldi, ödeme kaydı oluştur
                _ = int.TryParse(intent.Metadata.GetValueOrDefault("orderId"), out var orderId);
                _ = int.TryParse(intent.Metadata.GetValueOrDefault("restaurantId"), out var restaurantId);

                payment = new Payment
                {
                    OrderId = orderId,
                    RestaurantId = restaurantId,
                    StripePaymentIntentId = intent.Id,
                    Amount = intent.Amount / 100m,
                    Status = PaymentStatus.Completed,
                    PaidAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow
                };
                await _paymentRepository.CreatePaymentAsync(payment);
            }
            else
            {
                payment.Status = PaymentStatus.Completed;
                payment.PaidAt = DateTime.UtcNow;
                payment.UpdatedAt = DateTime.UtcNow;
                await _paymentRepository.UpdatePaymentAsync(payment);
            }
        }
        else if (stripeEvent.Type == Events.PaymentIntentPaymentFailed)
        {
            var intent = stripeEvent.Data.Object as PaymentIntent;
            if (intent is null) return;

            var payment = await _paymentRepository.GetPaymentByStripeIntentIdAsync(intent.Id);
            if (payment is not null)
            {
                payment.Status = PaymentStatus.Failed;
                payment.UpdatedAt = DateTime.UtcNow;
                await _paymentRepository.UpdatePaymentAsync(payment);
            }
        }
    }

    public async Task<IEnumerable<PaymentDto>> GetPaymentHistoryAsync(int restaurantId, PaymentFilterDto filter)
    {
        var payments = await _paymentRepository.GetPaymentHistoryAsync(restaurantId, filter.StartDate, filter.EndDate);
        return payments.Select(MapToPaymentDto);
    }

    // ── Mapper ───────────────────────────────────────────────────────────────

    private static PaymentDto MapToPaymentDto(Payment p) => new()
    {
        Id = p.Id,
        OrderId = p.OrderId,
        StripePaymentIntentId = p.StripePaymentIntentId,
        Amount = p.Amount,
        Status = p.Status,
        PaidAt = p.PaidAt,
        CreatedAt = p.CreatedAt
    };
}
