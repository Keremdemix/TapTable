using TapTable.Api.DTOs.Request.Qr;

public interface IQrSessionService
{
    Task<QrSessionResponseDto> GetActiveSessionAsync(int tableId);
    Task<QrSessionResponseDto> CreateSessionAsync(CreateQrSessionRequestDto request);
}