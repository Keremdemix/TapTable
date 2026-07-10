namespace TapTable.Api.DTOs.Response.Customer;

public class CustomerSessionResponseDto
{
    public int RestaurantId { get; set; }
    public int TableId { get; set; }
    public int TableNumber { get; set; }
    public string RestaurantName { get; set; } = null!;
    public string? LogoUrl { get; set; }
    public string PrimaryColorHex { get; set; } = null!;
    public string AccentColorHex { get; set; } = null!;
}