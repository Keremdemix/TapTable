using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Extensions;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/public/menu")]
public class PublicMenuController : ControllerBase
{
    private readonly IMenuService _menuService;

    public PublicMenuController(IMenuService menuService)
    {
        _menuService = menuService;
    }

    /// GET /api/public/menu (token: header veya query)
    [HttpGet]
    public async Task<IActionResult> GetMenu()
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var menu = await _menuService.GetPublicMenuByTokenAsync(token);
        return Ok(menu);
    }
}