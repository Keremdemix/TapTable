namespace TapTable.Api.Data.Entities;

public class Restaurant
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public DateTime CreatedAt { get; set; }

    // ── Customer App Tema ────────────────────────────────────────────────
    public string? LogoUrl { get; set; }           // Cloudinary — restoran logosu
    public string PrimaryColorHex { get; set; } = "#1A1A1A";   // ana marka rengi (buton, appbar)
    public string AccentColorHex { get; set; } = "#FF6B35";    // vurgu rengi (fiyat, badge, CTA)

    // ── iyzico Pazaryeri (Marketplace) ──────────────────────────────────
    public string? IyzicoSubMerchantKey { get; set; }
    public string? IyzicoSubMerchantExternalId { get; set; }
    public bool IsIyzicoApproved { get; set; }

    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<RestaurantTable> Tables { get; set; } = new List<RestaurantTable>();
    public ICollection<Category> Categories { get; set; } = new List<Category>();
}