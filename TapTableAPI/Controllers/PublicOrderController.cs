using Microsoft.AspNetCore.Mvc;
using TapTable.Api.DTOs.Request.Order;
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

    /// <summary>
    /// Müşteri sipariş gönderir — aktif sipariş varsa üzerine eklenir
    /// POST /api/public/orders/{tableId}
    /// </summary>
    [HttpPost("{tableId:int}")]
    public async Task<IActionResult> PlaceOrder(int tableId, [FromBody] PlaceOrderRequestDto request)
    {
        var order = await _orderService.PlaceOrderAsync(tableId, request);
        return Ok(order);
    }

    /// <summary>
    /// GET /api/public/orders/{tableId}/active?sessionKey=...
    /// </summary>
    [HttpGet("{tableId:int}/active")]
    public async Task<IActionResult> GetActive(int tableId, [FromQuery] string sessionKey)
    {
        var order = await _orderService.GetActiveOrderAsync(tableId, sessionKey);
        return Ok(order);
    }

    /// <summary>
    /// GET /api/public/orders/{tableId}/{orderId}?sessionKey=...
    /// </summary>
    [HttpGet("{tableId:int}/{orderId:int}")]
    public async Task<IActionResult> Track(int tableId, int orderId, [FromQuery] string sessionKey)
    {
        var order = await _orderService.TrackOrderAsync(tableId, sessionKey, orderId);
        return Ok(order);
    }
}