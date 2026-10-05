using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Extensions;
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
    /// Flutter uygulaması açılışta bu endpoint'i çağırır — token header'dan
    /// (Authorization: Bearer / X-QR-Token) veya query'den (?token=/?t=) okunur.
    /// GET /api/public/customer/session
    /// </summary>
    [HttpGet("session")]
    public async Task<IActionResult> GetSession()
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var session = await _customerService.ResolveSessionAsync(token);
        return Ok(session);
    }
}