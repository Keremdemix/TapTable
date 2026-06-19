using TapTable.Api.DTOs.Response.StripeConnect;

namespace TapTable.Api.Services.Interfaces;

public interface IStripeConnectService
{
    Task<StripeOnboardingResponseDto> StartOnboardingAsync(int restaurantId);
    Task<StripeAccountStatusResponseDto> GetStatusAsync(int restaurantId);
    Task HandleAccountUpdatedWebhookAsync(string json, string signatureHeader);
}