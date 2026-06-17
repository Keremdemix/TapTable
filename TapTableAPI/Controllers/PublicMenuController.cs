using Microsoft.AspNetCore.Mvc;
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

    /// <summary>
    /// Müşteri QR okuttuğunda menüyü getirir — kimlik doğrulama gerekmez
    /// GET /api/public/menu/{tableId}
    /// </summary>
    [HttpGet("{tableId:int}")]
    public async Task<IActionResult> GetMenu(int tableId)
    {
        var menu = await _menuService.GetPublicMenuByTableAsync(tableId);
        return Ok(menu);
    }
}