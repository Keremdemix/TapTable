using TapTable.Api.DTOs.Request.Qr;
using TapTable.Api.DTOs.Response.Customer;

public interface IQrSessionService
{
    Task<QrSessionResponseDto> GetActiveSessionAsync(int tableId);
    Task<QrSessionResponseDto> CreateSessionAsync(CreateQrSessionRequestDto request);
    Task<CustomerSessionResponseDto> ResolveSessionAsync(string token);
}