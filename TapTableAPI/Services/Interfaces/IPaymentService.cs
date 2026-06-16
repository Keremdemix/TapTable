using TapTable.Api.DTOs.Payment;

namespace TapTable.Api.Services.Interfaces;

public interface IPaymentService
{
    Task<PaymentIntentDto> CreatePaymentIntentAsync(int orderId, int restaurantId, CreatePaymentIntentDto request);
    Task<PaymentDto> ConfirmPaymentAsync(string stripePaymentIntentId);
    Task<PaymentDto> GetPaymentByOrderIdAsync(int orderId, int restaurantId);
    Task HandleStripeWebhookAsync(string payload, string stripeSignature);
    Task<IEnumerable<PaymentDto>> GetPaymentHistoryAsync(int restaurantId, PaymentFilterDto filter);
}
