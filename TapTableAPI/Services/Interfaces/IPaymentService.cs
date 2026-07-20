using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;

namespace TapTable.Api.Services.Interfaces;

public interface IPaymentService
{
    Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request);
    Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId);

    Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey);
    Task<OrderPaymentStateResponseDto> GetOrderPaymentStateAsync(int tableId, string sessionKey);

    Task<SplitPaymentPlanResponseDto> CreateSplitPlanAsync(int tableId, CreateSplitPlanRequestDto request);
    Task CancelSplitPlanAsync(int tableId, int planId, CancelSplitPlanRequestDto request);

    // ── Artık üçü de doğrudan iyzico checkout döner — buyerIp gerekiyor ──
    Task<IyzicoCheckoutResponseDto> PaySplitShareAsync(int tableId, int planId, PaySplitShareRequestDto request, string buyerIp);
    Task<IyzicoCheckoutResponseDto> PaySelectedItemsAsync(int tableId, PaySelectedItemsRequestDto request, string buyerIp);
    Task<IyzicoCheckoutResponseDto> CreateIyzicoCheckoutAsync(int tableId, InitiateIyzicoPaymentRequestDto request, string buyerIp);
    Task<PaymentResponseDto> GetPaymentStatusAsync(int tableId, int paymentId, string sessionKey);
    Task<bool> HandleIyzicoCallbackAsync(string token);

    // GEÇİCİ — dev/sandbox fallback, normal akışta kullanılmıyor
    //Task<PaymentResponseDto> ConfirmTestPaymentAsync(int paymentId);
}