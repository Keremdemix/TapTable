using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/payments/stripe")]
[AllowAnonymous]
public class StripeWebhookController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public StripeWebhookController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    /// <summary>
    /// Stripe Dashboard'da bu URL'i webhook endpoint olarak tanımlayın.
    /// POST /api/payments/stripe/webhook
    /// </summary>
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook()
    {
        using var reader = new StreamReader(Request.Body);
        var json = await reader.ReadToEndAsync();
        var signature = Request.Headers["Stripe-Signature"].ToString();

        await _paymentService.HandleStripeWebhookAsync(json, signature);
        return Ok();
    }
}