using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Auth;

public class LoginRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = null!;

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = null!;
}
