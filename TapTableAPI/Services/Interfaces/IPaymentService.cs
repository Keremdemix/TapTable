using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;

namespace TapTable.Api.Services.Interfaces;

public interface IPaymentService
{
    Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request);
    Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId);
    Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey); // müşteri hesap görüntüleme kalıyor
}