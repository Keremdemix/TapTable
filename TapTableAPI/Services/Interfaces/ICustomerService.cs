using TapTable.Api.DTOs.Customer;
using TapTable.Api.DTOs.Menu;
using TapTable.Api.DTOs.Order;

namespace TapTable.Api.Services.Interfaces;

public interface ICustomerService
{
    // QR ile masaya oturan müşteri akışı — login yok, her şey qrToken üzerinden
    Task<CustomerSessionDto> StartSessionAsync(string qrToken);
    Task<MenuWithItemsDto> GetMenuAsync(string qrToken);
    Task<OrderDto> PlaceOrderAsync(string qrToken, CustomerPlaceOrderDto request);
    Task<OrderDto?> GetMyActiveOrderAsync(string qrToken);       // masanın aktif siparişi
    Task<OrderDto> TrackOrderAsync(string qrToken, int orderId); // belirli siparişi takip et
    Task<PaymentSummaryDto> GetBillAsync(string qrToken);        // aktif siparişin hesabı
    Task<PaymentIntentDto> RequestPaymentAsync(string qrToken);  // ödeme başlat
}
