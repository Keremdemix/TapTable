using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Order;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/orders")]
[Authorize(Roles = "Admin,Waiter,Kitchen")]
public class OrderController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrderController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    private int? CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;

    [HttpGet]
    [Authorize(Roles = "Admin,Waiter,Kitchen")]
    public async Task<IActionResult> GetAll([FromQuery] OrderStatus? status, [FromQuery] int? tableId)
    {
        var orders = await _orderService.GetOrdersAsync(RestaurantId, status, tableId);
        return Ok(orders);
    }

    [HttpGet("{id:int}")]
    [Authorize(Roles = "Admin,Waiter,Kitchen")]
    public async Task<IActionResult> GetById(int id)
    {
        var order = await _orderService.GetOrderAsync(id, RestaurantId);
        return Ok(order);
    }

    /// <summary>
    /// Garson siparişi sisteme girer — masada aktif sipariş varsa üzerine eklenir
    /// POST /api/orders
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin,Waiter")]
    public async Task<IActionResult> Create([FromBody] StaffCreateOrderRequestDto request)
    {
        var order = await _orderService.CreateOrderByStaffAsync(RestaurantId, CurrentUserId, request);
        return Ok(order);
    }

    /// <summary>
    /// Mutfak ürün durumunu günceller (Preparing/Ready/Served)
    /// PATCH /api/orders/{orderId}/items/{itemId}/status
    /// </summary>
    [HttpPatch("{orderId:int}/items/{itemId:int}/status")]

    [Authorize(Roles = "Admin,Waiter,Kitchen")]
    public async Task<IActionResult> UpdateItemStatus(int orderId, int itemId, [FromBody] UpdateOrderItemStatusRequestDto request)
    {
        var order = await _orderService.UpdateOrderItemStatusAsync(orderId, itemId, RestaurantId, request.Status);
        return Ok(order);
    }

    /// <summary>
    /// Siparişin genel durumunu günceller (örn. Completed/Cancelled)
    /// PATCH /api/orders/{id}/status
    /// </summary>
    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "Admin,Waiter")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateOrderStatusRequestDto request)
    {
        var order = await _orderService.UpdateOrderStatusAsync(id, RestaurantId, request.Status);
        return Ok(order);
    }

    /// <summary>
    /// Garson "Teslim Edildi" der — o masadaki aktif siparişte Ready durumundaki
    /// TÜM ürünler Served'a geçer, diğer durumdaki ürünlere dokunulmaz.
    /// PATCH /api/orders/tables/{tableId}/serve-ready-items
    /// </summary>
    [HttpPatch("tables/{tableId:int}/serve-ready-items")]
    [Authorize(Roles = "Admin,Waiter")]
    public async Task<IActionResult> ServeReadyItemsByTable(int tableId)
    {
        var order = await _orderService.ServeReadyItemsByTableAsync(tableId, RestaurantId);
        return Ok(order);
    }
}