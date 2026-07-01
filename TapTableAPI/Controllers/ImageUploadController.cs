using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Controllers;

[ApiController]
[Route("api/images")]
[Authorize(Roles = "Admin")]
public class ImageUploadController : ControllerBase
{
    private readonly IImageUploadService _imageUploadService;

    public ImageUploadController(IImageUploadService imageUploadService)
    {
        _imageUploadService = imageUploadService;
    }

    private int RestaurantId =>
        int.Parse(User.FindFirstValue("restaurantId")!);

    /// <summary>
    /// Ürün görseli yükle — Cloudinary'ye gönderir, URL döner
    /// POST /api/images/menu-item
    /// Content-Type: multipart/form-data
    /// Form field: file
    /// </summary>
    [HttpPost("menu-item")]
    public async Task<IActionResult> UploadMenuItem(IFormFile file)
    {
        var url = await _imageUploadService.UploadAsync(file, $"restaurants/{RestaurantId}/menu-items");
        return Ok(new { url });
    }
}