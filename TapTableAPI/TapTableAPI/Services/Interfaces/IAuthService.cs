using TapTable.Api.DTOs.Auth;
using TapTable.Api.DTOs.Request.Auth;
using TapTableAPI.DTOs.Response.Auth;

namespace TapTable.Api.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponseDto> LoginAsync(LoginRequest request);
    Task<AuthResponseDto> RefreshTokenAsync(string refreshToken);
    Task LogoutAsync(int userId);
    Task<UserProfileDto> GetProfileAsync(int userId);
    Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileDto request);
    Task ChangePasswordAsync(int userId, ChangePasswordDto request);
}
