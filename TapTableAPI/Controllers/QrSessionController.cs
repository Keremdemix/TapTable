using Microsoft.AspNetCore.Mvc;
using TapTable.Api.DTOs.Request.Qr;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/qr")]
public class QrController : ControllerBase
{
    private readonly IQrSessionService _qrService;

    public QrController(IQrSessionService qrService)
    {
        _qrService = qrService;
    }

    [HttpGet("active/{tableId}")]
    public async Task<IActionResult> GetActive(int tableId)
    {
        var result = await _qrService.GetActiveSessionAsync(tableId);
        return Ok(result);
    }

    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateQrSessionRequestDto request)
    {
        var result = await _qrService.CreateSessionAsync(request);
        return Ok(result);
    }
}