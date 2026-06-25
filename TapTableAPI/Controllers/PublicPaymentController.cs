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

    /// <summary>
    /// GET /api/public/payments/{tableId}/bill?sessionKey=...
    /// </summary>
    [HttpGet("{tableId:int}/bill")]
    public async Task<IActionResult> GetBill(int tableId, [FromQuery] string sessionKey)
    {
        var bill = await _paymentService.GetBillAsync(tableId, sessionKey);
        return Ok(bill);
    }
}