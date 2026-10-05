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

    private string BuyerIp => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "85.34.78.112";

    [HttpGet("{tableId:int}/bill")]
    public async Task<IActionResult> GetBill(int tableId, [FromQuery] string sessionKey)
    {
        var bill = await _paymentService.GetBillAsync(tableId, sessionKey);
        return Ok(bill);
    }

    [HttpGet("{tableId:int}/state")]
    public async Task<IActionResult> GetPaymentState(int tableId, [FromQuery] string sessionKey)
    {
        var state = await _paymentService.GetOrderPaymentStateAsync(tableId, sessionKey);
        return Ok(state);
    }

    [HttpPost("{tableId:int}/split-plan")]
    public async Task<IActionResult> CreateSplitPlan(int tableId, [FromBody] CreateSplitPlanRequestDto request)
    {
        var plan = await _paymentService.CreateSplitPlanAsync(tableId, request);
        return Ok(plan);
    }

    [HttpPost("{tableId:int}/split-plan/{planId:int}/cancel")]
    public async Task<IActionResult> CancelSplitPlan(int tableId, int planId, [FromBody] CancelSplitPlanRequestDto request)
    {
        await _paymentService.CancelSplitPlanAsync(tableId, planId, request);
        return NoContent();
    }

    /// <summary>
    /// Bölüşüm planından pay(lar) öder — doğrudan iyzico checkout döner.
    /// POST /api/public/payments/{tableId}/split-plan/{planId}/pay-share
    /// </summary>
    [HttpPost("{tableId:int}/split-plan/{planId:int}/pay-share")]
    public async Task<IActionResult> PaySplitShare(int tableId, int planId, [FromBody] PaySplitShareRequestDto request)
    {
        var checkout = await _paymentService.PaySplitShareAsync(tableId, planId, request, BuyerIp);
        return Ok(checkout);
    }

    /// <summary>
    /// Seçilen sipariş kalemlerini öder — doğrudan iyzico checkout döner.
    /// POST /api/public/payments/{tableId}/pay-selected
    /// </summary>
    [HttpPost("{tableId:int}/pay-selected")]
    public async Task<IActionResult> PaySelectedItems(int tableId, [FromBody] PaySelectedItemsRequestDto request)
    {
        var checkout = await _paymentService.PaySelectedItemsAsync(tableId, request, BuyerIp);
        return Ok(checkout);
    }

    /// <summary>
    /// Kalan tutarın tamamı için iyzico checkout başlatır.
    /// POST /api/public/payments/{tableId}/iyzico-checkout
    /// </summary>
    [HttpPost("{tableId:int}/iyzico-checkout")]
    public async Task<IActionResult> CreateCheckout(int tableId, [FromBody] InitiateIyzicoPaymentRequestDto request)
    {
        var result = await _paymentService.CreateIyzicoCheckoutAsync(tableId, request, BuyerIp);
        return Ok(result);
    }

    [HttpPost("iyzico-callback")]
    public async Task<IActionResult> IyzicoCallback([FromForm] string token)
    {
        var success = await _paymentService.HandleIyzicoCallbackAsync(token);

        var html = success
            ? "<html><body><h2>Ödemeniz alındı, bu sekmeyi kapatabilirsiniz.</h2></body></html>"
            : "<html><body><h2>Ödeme başarısız oldu, lütfen tekrar deneyin.</h2></body></html>";

        return Content(html, "text/html");
    }
    /// <summary>
    /// Tek bir ödemenin ("benim ödemem") durumunu döner — session rotate
    /// edilmiş olsa bile çalışır.
    /// GET /api/public/payments/{tableId}/payment-status/{paymentId}
    /// </summary>
    [HttpGet("{tableId:int}/payment-status/{paymentId:int}")]
    public async Task<IActionResult> GetPaymentStatus(int tableId, int paymentId, [FromQuery] string sessionKey)
    {
        var payment = await _paymentService.GetPaymentStatusAsync(tableId, paymentId, sessionKey);
        return Ok(payment);
    }
}