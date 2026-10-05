using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.DTOs.Request.Table;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/tables")]
[Authorize(Roles = "Admin,Waiter")]
public class TableController : ControllerBase
{
    private readonly ITableService _tableService;

    public TableController(ITableService tableService)
    {
        _tableService = tableService;
    }

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var tables = await _tableService.GetTablesAsync(RestaurantId);
        return Ok(tables);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var table = await _tableService.GetTableAsync(id, RestaurantId);
        return Ok(table);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateTableRequestDto request)
    {
        var table = await _tableService.CreateTableAsync(RestaurantId, request);
        return CreatedAtAction(nameof(GetById), new { id = table.Id }, table);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTableRequestDto request)
    {
        var table = await _tableService.UpdateTableAsync(id, RestaurantId, request);
        return Ok(table);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        await _tableService.DeleteTableAsync(id, RestaurantId);
        return NoContent();
    }

    [HttpPut("{id:int}/qr-url")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SetQrUrl(int id, [FromBody] SetQrUrlRequestDto request)
    {
        var table = await _tableService.SetQrUrlAsync(id, RestaurantId, request.Url);
        return Ok(table);
    }

    [HttpDelete("{id:int}/qr-url")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteQrUrl(int id)
    {
        var table = await _tableService.DeleteQrUrlAsync(id, RestaurantId);
        return Ok(table);
    }

    [HttpPost("{id:int}/regenerate-qr")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RegenerateQr(int id)
    {
        var result = await _tableService.RegenerateQrAsync(id, RestaurantId);
        return Ok(result);
    }

    /// <summary>
    /// Kat planı — masaların konum/boyut/şekil bilgisi. Admin ve Waiter görebilir.
    /// GET /api/tables/layout
    /// </summary>
    [HttpGet("layout")]
    public async Task<IActionResult> GetLayout()
    {
        var layout = await _tableService.GetLayoutAsync(RestaurantId);
        return Ok(layout);
    }

    /// <summary>
    /// Kat planını kaydet — sadece Admin (sürükle-bırak editörü).
    /// PUT /api/tables/layout 
    /// </summary>
    [HttpPut("layout")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SaveLayout([FromBody] UpdateLayoutRequestDto request)
    {
        await _tableService.SaveLayoutAsync(RestaurantId, request);
        return NoContent();
    }
}