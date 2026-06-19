using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;

namespace TapTable.Api.Services.Interfaces;

public interface IPaymentService
{
    // Garson — manuel ödeme girişi
    Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request);
    Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId);

    // Müşteri — Stripe akışı
    Task<PaymentIntentResponseDto> CreateStripeIntentAsync(int tableId, CreatePaymentIntentRequestDto request);
    Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey);

    // Stripe → backend
    Task HandleStripeWebhookAsync(string json, string stripeSignatureHeader);
}