namespace TapTableAPI.DTOs.Response.Auth;

public class UserProfileDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Role { get; set; } = null!;
    public int RestaurantId { get; set; }
    public string? RestaurantName { get; set; }
}