using Microsoft.AspNetCore.Mvc;
using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/public/payments")]
public class PublicPaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PublicPaymentController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpGet("{tableId:int}/bill")]
    public async Task<IActionResult> GetBill(int tableId, [FromQuery] string sessionKey)
    {
        var bill = await _paymentService.GetBillAsync(tableId, sessionKey);
        return Ok(bill);
    }

    /// <summary>
    /// Müşteri ödeme başlatır — dönen paymentPageUrl bir WebView'da açılır
    /// POST /api/public/payments/{tableId}/iyzico-checkout
    /// </summary>
    [HttpPost("{tableId:int}/iyzico-checkout")]
    public async Task<IActionResult> CreateCheckout(int tableId, [FromBody] InitiateIyzicoPaymentRequestDto request)
    {
        var buyerIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "85.34.78.112";
        var result = await _paymentService.CreateIyzicoCheckoutAsync(tableId, request, buyerIp);
        return Ok(result);
    }

    /// <summary>
    /// iyzico'nun ödeme sonrası POST ile çağırdığı callback — kullanıcı tarafından değil iyzico tarafından çağrılır.
    /// POST /api/public/payments/iyzico-callback
    /// </summary>
    [HttpPost("iyzico-callback")]
    public async Task<IActionResult> IyzicoCallback([FromForm] string token)
    {
        var success = await _paymentService.HandleIyzicoCallbackAsync(token);

        var html = success
            ? "<html><body><h2>Ödemeniz alındı, bu sekmeyi kapatabilirsiniz.</h2></body></html>"
            : "<html><body><h2>Ödeme başarısız oldu, lütfen tekrar deneyin.</h2></body></html>";

        return Content(html, "text/html");
    }
}