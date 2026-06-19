using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/stripe-connect")]
[AllowAnonymous]
public class StripeConnectWebhookController : ControllerBase
{
    private readonly IStripeConnectService _stripeConnectService;

    public StripeConnectWebhookController(IStripeConnectService stripeConnectService)
    {
        _stripeConnectService = stripeConnectService;
    }

    /// <summary>
    /// Stripe Dashboard → Webhooks → "Connect" sekmesinde bu URL'i tanımlayın.
    /// POST /api/stripe-connect/webhook
    /// </summary>
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook()
    {
        using var reader = new StreamReader(Request.Body);
        var json = await reader.ReadToEndAsync();
        var signature = Request.Headers["Stripe-Signature"].ToString();

        await _stripeConnectService.HandleAccountUpdatedWebhookAsync(json, signature);
        return Ok();
    }
}