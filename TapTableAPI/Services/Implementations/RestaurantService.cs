using TapTable.Api.Data;
using TapTable.Api.Services.Interfaces;

public class RestaurantService : IRestaurantService
{
    private readonly TapTableDbContext _context;
    private readonly IImageUploadService _imageUploadService;

    public RestaurantService(TapTableDbContext context, IImageUploadService imageUploadService)
    {
        _context = context;
        _imageUploadService = imageUploadService;
    }

    public async Task<RestaurantBrandingResponse?> GetBrandingAsync(int restaurantId)
    {
        var restaurant = await _context.Restaurants.FindAsync(restaurantId);

        if (restaurant == null)
            return null;

        return new RestaurantBrandingResponse
        {
            LogoUrl = restaurant.LogoUrl,
            PrimaryColorHex = restaurant.PrimaryColorHex,
            AccentColorHex = restaurant.AccentColorHex
        };
    }

    public async Task<bool> UpdateBrandingAsync(
        int restaurantId,
        UpdateRestaurantBrandingRequest request)
    {
        var restaurant = await _context.Restaurants.FindAsync(restaurantId);

        if (restaurant == null)
            return false;

        var oldLogoUrl = restaurant.LogoUrl;

        restaurant.PrimaryColorHex = request.PrimaryColorHex;
        restaurant.AccentColorHex = request.AccentColorHex;

        if (request.Logo is not null)
        {
            // Yeni logo yüklendi — Cloudinary'ye gönder, DB'ye yeni URL yazılır
            var newLogoUrl = await _imageUploadService.UploadAsync(
                request.Logo, $"restaurants/{restaurantId}/branding");

            restaurant.LogoUrl = newLogoUrl;
        }
        else if (request.RemoveLogo)
        {
            // Kullanıcı logoyu tamamen kaldırdı
            restaurant.LogoUrl = null;
        }
        // İkisi de yoksa mevcut LogoUrl dokunulmadan kalır (sadece renk güncelleniyor)

        await _context.SaveChangesAsync();

        // Logo değiştiyse ya da kaldırıldıysa eskisini Cloudinary'den sil
        if (!string.IsNullOrWhiteSpace(oldLogoUrl) &&
            (request.Logo is not null || request.RemoveLogo))
        {
            await _imageUploadService.DeleteByUrlAsync(oldLogoUrl, restaurantId);
        }

        return true;
    }
}