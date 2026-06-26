using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;

public interface IPaymentService
{
    Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request);
    Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId);
    Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey);
    Task<IyzicoCheckoutResponseDto> CreateIyzicoCheckoutAsync(int tableId, InitiateIyzicoPaymentRequestDto request, string buyerIp);
    Task<bool> HandleIyzicoCallbackAsync(string token);
}