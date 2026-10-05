public class QrSessionResponseDto
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public string SessionKey { get; set; } = null!;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public string QrUrl { get; set; } = null!;

    public RestaurantBrandingDto Restaurant { get; set; } = null!;
}

public class RestaurantBrandingDto
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? LogoUrl { get; set; }
    public string PrimaryColorHex { get; set; } = null!;
    public string AccentColorHex { get; set; } = null!;
}