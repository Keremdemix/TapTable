using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CloudinaryImageUploadService : IImageUploadService
{
    private readonly Cloudinary _cloudinary;
    private readonly ILogger<CloudinaryImageUploadService> _logger;

    public CloudinaryImageUploadService(
        IConfiguration configuration,
        ILogger<CloudinaryImageUploadService> logger)
    {
        var account = new Account(
            configuration["Cloudinary:CloudName"],
            configuration["Cloudinary:ApiKey"],
            configuration["Cloudinary:ApiSecret"]
        );
        _cloudinary = new Cloudinary(account) { Api = { Secure = true } };
        _logger = logger;
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
                .Crop("limit")
                .Quality("auto")
                .FetchFormat("webp"),
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
        var result = await _cloudinary.DestroyAsync(deleteParams);

        if (result.Result != "ok" && result.Result != "not found")
        {
            _logger.LogWarning(
                "Cloudinary silme başarısız. PublicId: {PublicId}, Sonuç: {Result}",
                publicId, result.Result);
        }
    }

    /// <summary>
    /// Cloudinary secure URL'inden public_id çıkarıp siler.
    /// restaurantId verilirse, URL'nin o restorana ait olup olmadığını doğrular
    /// (başka bir restoranın görselinin yanlışlıkla silinmesini önler).
    /// </summary>
    public async Task<bool> DeleteByUrlAsync(string url, int? restaurantId = null)
    {
        var publicId = ExtractPublicId(url);
        if (publicId is null)
        {
            _logger.LogWarning("Public ID çıkarılamadı. URL: {Url}", url);
            return false;
        }

        if (restaurantId is not null &&
            !publicId.Contains($"restaurants/{restaurantId}/", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning(
                "Yetkisiz silme girişimi engellendi. RestaurantId: {RestaurantId}, PublicId: {PublicId}",
                restaurantId, publicId);
            return false;
        }

        await DeleteAsync(publicId);
        return true;
    }

    private static string? ExtractPublicId(string url)
    {
        try
        {
            var uri = new Uri(url);
            var segments = uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries);

            var uploadIndex = Array.IndexOf(segments, "upload");
            if (uploadIndex == -1 || uploadIndex + 1 >= segments.Length)
                return null;

            var rest = segments.Skip(uploadIndex + 1).ToArray();

            // Versiyon segmentini atla (v1234567890)
            if (rest.Length > 0 && rest[0].Length > 1 && rest[0][0] == 'v' &&
                rest[0][1..].All(char.IsDigit))
            {
                rest = rest.Skip(1).ToArray();
            }

            var path = string.Join('/', rest);

            var lastDot = path.LastIndexOf('.');
            if (lastDot > -1) path = path[..lastDot];

            return string.IsNullOrWhiteSpace(path) ? null : path;
        }
        catch
        {
            return null;
        }
    }
}