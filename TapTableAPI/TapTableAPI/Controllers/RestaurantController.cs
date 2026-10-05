using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TapTable.Api.Services.Interfaces;

[ApiController]
[Route("api/restaurants")]
[Authorize(Roles = "Admin")]
public class RestaurantsController : ControllerBase
{
    private readonly IRestaurantService _restaurantService;

    public RestaurantsController(IRestaurantService restaurantService)
    {
        _restaurantService = restaurantService;
    }

    [HttpGet("{restaurantId}/branding")]
    [AllowAnonymous]
    public async Task<IActionResult> GetBranding(int restaurantId)
    {
        var branding = await _restaurantService.GetBrandingAsync(restaurantId);

        if (branding == null)
            return NotFound();

        return Ok(branding);
    }

    /// <summary>
    /// PUT /api/restaurants/{restaurantId}/branding
    /// multipart/form-data: logo (opsiyonel dosya), removeLogo, primaryColorHex, accentColorHex
    /// </summary>
    [HttpPut("{restaurantId}/branding")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UpdateBranding(
        int restaurantId,
        [FromForm] UpdateRestaurantBrandingRequest request)
    {
        var success = await _restaurantService.UpdateBrandingAsync(restaurantId, request);

        if (!success)
            return NotFound();

        return NoContent();
    }
}