using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.DTOs.Request.Menu;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/menu")]
[Authorize(Roles = "Admin")]
public class MenuController : ControllerBase
{
    private readonly IMenuService _menuService;

    public MenuController(IMenuService menuService)
    {
        _menuService = menuService;
    }

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    // ── Kategoriler ──────────────────────────────────────────────────────

    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await _menuService.GetCategoriesAsync(RestaurantId);
        return Ok(categories);
    }

    [HttpPost("categories")]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequestDto request)
    {
        var category = await _menuService.CreateCategoryAsync(RestaurantId, request);
        return Ok(category);
    }

    [HttpPut("categories/{id:int}")]
    public async Task<IActionResult> UpdateCategory(int id, [FromBody] UpdateCategoryRequestDto request)
    {
        var category = await _menuService.UpdateCategoryAsync(id, RestaurantId, request);
        return Ok(category);
    }

    [HttpDelete("categories/{id:int}")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        await _menuService.DeleteCategoryAsync(id, RestaurantId);
        return NoContent();
    }

    // ── Ürünler ──────────────────────────────────────────────────────────

    [HttpGet("items")]
    public async Task<IActionResult> GetItems([FromQuery] int? categoryId)
    {
        var items = await _menuService.GetMenuItemsAsync(RestaurantId, categoryId);
        return Ok(items);
    }

    [HttpGet("items/{id:int}")]
    public async Task<IActionResult> GetItem(int id)
    {
        var item = await _menuService.GetMenuItemAsync(id, RestaurantId);
        return Ok(item);
    }

    [HttpPost("items")]
    public async Task<IActionResult> CreateItem([FromBody] CreateMenuItemRequestDto request)
    {
        var item = await _menuService.CreateMenuItemAsync(RestaurantId, request);
        return Ok(item);
    }

    [HttpPut("items/{id:int}")]
    public async Task<IActionResult> UpdateItem(int id, [FromBody] UpdateMenuItemRequestDto request)
    {
        var item = await _menuService.UpdateMenuItemAsync(id, RestaurantId, request);
        return Ok(item);
    }

    [HttpPatch("items/{id:int}/availability")]
    public async Task<IActionResult> SetAvailability(int id, [FromBody] SetAvailabilityRequestDto request)
    {
        var item = await _menuService.SetAvailabilityAsync(id, RestaurantId, request.IsAvailable);
        return Ok(item);
    }

    [HttpDelete("items/{id:int}")]
    public async Task<IActionResult> DeleteItem(int id)
    {
        await _menuService.DeleteMenuItemAsync(id, RestaurantId);
        return NoContent();
    }
}