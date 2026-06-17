namespace TapTable.Api.DTOs.Request.Menu;

public class CreateMenuItemRequestDto
{
    public int CategoryId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; }
}

public class UpdateMenuItemRequestDto
{
    public int CategoryId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; }
    public bool IsAvailable { get; set; }
    public bool IsActive { get; set; }
}

public class SetAvailabilityRequestDto
{
    public bool IsAvailable { get; set; }
}