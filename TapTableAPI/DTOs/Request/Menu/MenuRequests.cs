using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Menu;

public class CreateMenuItemRequest
{
    [Required]
    public int CategoryId { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = null!;

    [MaxLength(500)]
    public string? Description { get; set; }

    [Required]
    [Range(0.01, 100000)]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public bool IsAvailable { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}

public class UpdateMenuItemRequest
{
    [MaxLength(150)]
    public string? Name { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    [Range(0.01, 100000)]
    public decimal? Price { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public bool? IsAvailable { get; set; }
    public int? SortOrder { get; set; }
}

public class CreateCategoryRequest
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = null!;

    public int SortOrder { get; set; } = 0;
}
