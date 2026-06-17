using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.DTOs.Request.Table;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/tables")]
[Authorize(Roles = "Admin")]
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

    /// <summary>
    /// Yeni masa ekle → QR URL otomatik üretilir → ilk session açılır
    /// POST /api/tables
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTableRequestDto request)
    {
        var table = await _tableService.CreateTableAsync(RestaurantId, request);
        return CreatedAtAction(nameof(GetById), new { id = table.Id }, table);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateTableRequestDto request)
    {
        var table = await _tableService.UpdateTableAsync(id, RestaurantId, request);
        return Ok(table);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        await _tableService.DeleteTableAsync(id, RestaurantId);
        return NoContent();
    }

    /// <summary>
    /// Admin QR URL'i manuel değiştirir
    /// PUT /api/tables/{id}/qr-url
    /// Body: { "url": "https://..." }
    /// </summary>
    [HttpPut("{id:int}/qr-url")]
    public async Task<IActionResult> SetQrUrl(int id, [FromBody] SetQrUrlRequestDto request)
    {
        var table = await _tableService.SetQrUrlAsync(id, RestaurantId, request.Url);
        return Ok(table);
    }

    /// <summary>
    /// Admin QR URL'i siler
    /// DELETE /api/tables/{id}/qr-url
    /// </summary>
    [HttpDelete("{id:int}/qr-url")]
    public async Task<IActionResult> DeleteQrUrl(int id)
    {
        var table = await _tableService.DeleteQrUrlAsync(id, RestaurantId);
        return Ok(table);
    }

    /// <summary>
    /// Admin yeni fiziksel QR basmak istediğinde çağırır.
    /// QR URL değişmez — sadece yeni SessionKey üretilir, eski session kapanır.
    /// POST /api/tables/{id}/regenerate-qr
    /// </summary>
    [HttpPost("{id:int}/regenerate-qr")]
    public async Task<IActionResult> RegenerateQr(int id)
    {
        var result = await _tableService.RegenerateQrAsync(id, RestaurantId);
        return Ok(result);
    }
}