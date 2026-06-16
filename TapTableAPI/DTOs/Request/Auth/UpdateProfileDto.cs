namespace TapTable.Api.DTOs.Auth;

using System.ComponentModel.DataAnnotations;

public class UpdateProfileDto
{
    [Required]
    public string FullName { get; set; } = null!;
}