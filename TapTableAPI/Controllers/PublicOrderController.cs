using Microsoft.AspNetCore.Mvc;
using TapTable.Api.DTOs.Request.Order;
using TapTable.Api.Extensions;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/public/orders")]
public class PublicOrderController : ControllerBase
{
    private readonly IOrderService _orderService;

    public PublicOrderController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    /// POST /api/public/orders
    [HttpPost]
    public async Task<IActionResult> PlaceOrder([FromBody] PlaceOrderRequestDto request)
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var order = await _orderService.PlaceOrderAsync(token, request);
        return Ok(order);
    }

    /// GET /api/public/orders/active
    [HttpGet("active")]
    public async Task<IActionResult> GetActive()
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var order = await _orderService.GetActiveOrderAsync(token);
        return Ok(order);
    }

    /// GET /api/public/orders/{orderId}
    [HttpGet("{orderId:int}")]
    public async Task<IActionResult> Track(int orderId)
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var order = await _orderService.TrackOrderAsync(token, orderId);
        return Ok(order);
    }
}