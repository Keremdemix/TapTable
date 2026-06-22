using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/public/customer")]
public class CustomerController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomerController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    /// <summary>
    /// Flutter uygulaması QR'dan gelen tableId ile bu endpoint'i çağırır.
    /// Dönen sessionKey, sonraki tüm public çağrılarda (menü, sipariş, ödeme) kullanılır.
    /// GET /api/public/customer/session/{tableId}
    /// </summary>
    [HttpGet("session/{tableId:int}")]
    public async Task<IActionResult> StartSession(int tableId)
    {
        var session = await _customerService.StartSessionAsync(tableId);
        return Ok(session);
    }
}