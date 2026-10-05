namespace TapTableAPI.DTOs.Response.Auth;

public class LoginResponse
{
    public string Token { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public UserInfo User { get; set; } = null!;
}

public class UserInfo
{
    public int Id { get; set; }
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Role { get; set; } = null!;       // "Admin" | "Waiter" | "Kitchen"
    public int RestaurantId { get; set; }
}
