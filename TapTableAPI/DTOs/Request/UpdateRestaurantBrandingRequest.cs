using Microsoft.AspNetCore.Http;

public class UpdateRestaurantBrandingRequest
{
    /// <summary>Yeni logo seçildiyse dolu gelir; sadece renk güncelleniyorsa null.</summary>
    public IFormFile? Logo { get; set; }

    /// <summary>Kullanıcı logoyu tamamen kaldırmak istiyorsa true (yeni Logo göndermeden).</summary>
    public bool RemoveLogo { get; set; } = false;

    public string PrimaryColorHex { get; set; } = null!;
    public string AccentColorHex { get; set; } = null!;
}