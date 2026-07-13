using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/payments")]
[Authorize(Roles = "Admin,Waiter")]
public class PaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    /// <summary>
    /// Garson POS'tan kart/nakit aldıktan sonra sisteme işler
    /// POST /api/payments/manual
    /// </summary>
    [HttpPost("manual")]
    public async Task<IActionResult> RecordManual([FromBody] RecordManualPaymentRequestDto request)
    {
        var payment = await _paymentService.RecordManualPaymentAsync(RestaurantId, request);
        return Ok(payment);
    }

    [HttpGet("order/{orderId:int}")]
    public async Task<IActionResult> GetByOrder(int orderId)
    {
        var payments = await _paymentService.GetPaymentsForOrderAsync(orderId, RestaurantId);
        return Ok(payments);
    }

    [HttpPost("test-confirm/{paymentId:int}")]
    public async Task<IActionResult> ConfirmTestPayment(int paymentId)
    {
        var payment = await _paymentService.ConfirmTestPaymentAsync(paymentId);
        return Ok(payment);
    }
}