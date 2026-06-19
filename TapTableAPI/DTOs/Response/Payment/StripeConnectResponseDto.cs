namespace TapTable.Api.DTOs.Response.StripeConnect;

public class StripeOnboardingResponseDto
{
    public string OnboardingUrl { get; set; } = null!;
}

public class StripeAccountStatusResponseDto
{
    public bool HasAccount { get; set; }
    public bool OnboardingCompleted { get; set; }
    public bool ChargesEnabled { get; set; }
}