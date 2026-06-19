using Stripe;
using TapTable.Api.DTOs.Response.StripeConnect;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class StripeConnectService : IStripeConnectService
{
    private readonly IRestaurantRepository _restaurantRepository;
    private readonly string _connectWebhookSecret;
    private readonly string _onboardingReturnUrl;
    private readonly string _onboardingRefreshUrl;

    public StripeConnectService(IRestaurantRepository restaurantRepository, IConfiguration configuration)
    {
        _restaurantRepository = restaurantRepository;
        _connectWebhookSecret = configuration["Stripe:ConnectWebhookSecret"] ?? string.Empty;
        _onboardingReturnUrl = configuration["App:StripeOnboardingReturnUrl"]
            ?? "https://admin.taptable.com/stripe/onboarding/complete";
        _onboardingRefreshUrl = configuration["App:StripeOnboardingRefreshUrl"]
            ?? "https://admin.taptable.com/stripe/onboarding/refresh";
    }

    public async Task<StripeOnboardingResponseDto> StartOnboardingAsync(int restaurantId)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        // Hesap yoksa oluştur
        if (string.IsNullOrEmpty(restaurant.StripeAccountId))
        {
            var accountService = new AccountService();
            var account = await accountService.CreateAsync(new AccountCreateOptions
            {
                Type = "express",
                Country = "TR", // TODO: restoranın ülkesine göre dinamik yapılabilir
                Capabilities = new AccountCapabilitiesOptions
                {
                    CardPayments = new AccountCapabilitiesCardPaymentsOptions { Requested = true },
                    Transfers = new AccountCapabilitiesTransfersOptions { Requested = true }
                },
                BusinessType = "company",
                Metadata = new Dictionary<string, string>
                {
                    { "restaurantId", restaurant.Id.ToString() }
                }
            });

            restaurant.StripeAccountId = account.Id;
            await _restaurantRepository.UpdateAsync(restaurant);
        }

        // Onboarding linki — kısa sürede geçersiz olur, her çağrıda yeni üretiyoruz
        var linkService = new AccountLinkService();
        var link = await linkService.CreateAsync(new AccountLinkCreateOptions
        {
            Account = restaurant.StripeAccountId,
            ReturnUrl = _onboardingReturnUrl,
            RefreshUrl = _onboardingRefreshUrl,
            Type = "account_onboarding"
        });

        return new StripeOnboardingResponseDto { OnboardingUrl = link.Url };
    }

    public async Task<StripeAccountStatusResponseDto> GetStatusAsync(int restaurantId)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        return new StripeAccountStatusResponseDto
        {
            HasAccount = !string.IsNullOrEmpty(restaurant.StripeAccountId),
            OnboardingCompleted = restaurant.StripeOnboardingCompleted,
            ChargesEnabled = restaurant.StripeChargesEnabled
        };
    }

    public async Task HandleAccountUpdatedWebhookAsync(string json, string signatureHeader)
    {
        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, _connectWebhookSecret);
        }
        catch (StripeException)
        {
            throw new UnauthorizedAccessException("Geçersiz Stripe imzası.");
        }

        if (stripeEvent.Type != "account.updated") return;

        var account = stripeEvent.Data.Object as Account;
        if (account is null) return;

        var restaurant = await _restaurantRepository.GetByStripeAccountIdAsync(account.Id);
        if (restaurant is null) return;

        restaurant.StripeChargesEnabled = account.ChargesEnabled;
        restaurant.StripeOnboardingCompleted = account.DetailsSubmitted;

        await _restaurantRepository.UpdateAsync(restaurant);
    }
}