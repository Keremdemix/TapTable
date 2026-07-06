using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Extensions;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/customer/session")]
public class CustomerSessionController : ControllerBase
{
    private readonly IQrSessionService _qrSessionService;

    public CustomerSessionController(IQrSessionService qrSessionService)
    {
        _qrSessionService = qrSessionService;
    }

    /// GET /api/customer/session?token=... (veya X-QR-Token header'ı ile)
    [HttpGet]
    public async Task<IActionResult> GetSession()
    {
        var token = Request.GetQrToken();
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized();

        var session = await _qrSessionService.ResolveSessionAsync(token);
        return Ok(session);
    }
}