using TapTableAPI.DTOs.Response.Auth;

namespace TapTable.Api.DTOs.Auth;

public class AuthResponseDto
{
    public string AccessToken { get; set; } = null!;
    public string RefreshToken { get; set; } = null!;
    public int ExpiresIn { get; set; }
    public UserProfileDto User { get; set; } = null!;
}