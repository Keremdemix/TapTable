using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CloudinaryImageUploadService : IImageUploadService
{
    private readonly Cloudinary _cloudinary;

    public CloudinaryImageUploadService(IConfiguration configuration)
    {
        var account = new Account(
            configuration["Cloudinary:CloudName"],
            configuration["Cloudinary:ApiKey"],
            configuration["Cloudinary:ApiSecret"]
        );
        _cloudinary = new Cloudinary(account) { Api = { Secure = true } };
    }

    public async Task<string> UploadAsync(IFormFile file, string folder)
    {
        if (file.Length == 0)
            throw new ArgumentException("Dosya boş.");

        var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp" };
        if (!allowedTypes.Contains(file.ContentType.ToLower()))
            throw new ArgumentException("Sadece JPG, PNG ve WebP desteklenir.");

        if (file.Length > 5 * 1024 * 1024) // 5 MB
            throw new ArgumentException("Dosya boyutu 5 MB'ı aşamaz.");

        using var stream = file.OpenReadStream();
        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = $"taptable/{folder}",
            Transformation = new Transformation()
                .Width(800).Height(800)
                .Crop("limit")          // orijinal oranı koru, max 800x800
                .Quality("auto")        // Cloudinary otomatik kalite optimizasyonu
                .FetchFormat("webp"),   // WebP'ye dönüştür (daha küçük boyut)
            UseFilename = false,
            UniqueFilename = true,
            Overwrite = false
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if (result.Error is not null)
            throw new InvalidOperationException($"Cloudinary yükleme hatası: {result.Error.Message}");

        return result.SecureUrl.ToString();
    }

    public async Task DeleteAsync(string publicId)
    {
        if (string.IsNullOrWhiteSpace(publicId)) return;

        var deleteParams = new DeletionParams(publicId);
        await _cloudinary.DestroyAsync(deleteParams);
    }
}