using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.DTOs.Request.IyzicoConnect;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/iyzico-connect")]
[Authorize(Roles = "Admin")]
public class IyzicoSubMerchantController : ControllerBase
{
    private readonly IIyzicoSubMerchantService _service;

    public IyzicoSubMerchantController(IIyzicoSubMerchantService service)
        => _service = service;

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    [HttpGet("status")]
    public async Task<IActionResult> GetStatus()
    {
        var result = await _service.GetStatusAsync(RestaurantId);
        return Ok(result);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterSubMerchantRequestDto dto)
    {
        var result = await _service.RegisterAsync(RestaurantId, dto);
        return Ok(result);
    }
}