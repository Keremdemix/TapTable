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
    /// </summary>
    [HttpPost("menu-item")]
    public async Task<IActionResult> UploadMenuItem(IFormFile file)
    {
        var url = await _imageUploadService.UploadAsync(file, $"restaurants/{RestaurantId}/menu-items");
        return Ok(new { url });
    }

    /// <summary>
    /// Görseli Cloudinary'den siler.
    /// DELETE /api/images
    /// Body: { "url": "https://res.cloudinary.com/..." }
    /// </summary>
    [HttpDelete]
    public async Task<IActionResult> DeleteImage([FromBody] DeleteImageRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Url))
            return BadRequest("URL gerekli.");

        var deleted = await _imageUploadService.DeleteByUrlAsync(request.Url, RestaurantId);

        // Görsel zaten yoksa veya URL bize ait değilse bile client'a hata göstermeye gerek yok,
        // sessizce devam edebilir — ama yetkisiz erişim denemesi loglanıyor.
        return NoContent();
    }
}

public record DeleteImageRequest(string Url);