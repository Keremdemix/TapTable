namespace TapTable.Api.DTOs.Response.Menu;

public class PublicMenuResponseDto
{
    public int RestaurantId { get; set; }
    public string RestaurantName { get; set; } = null!;
    public List<PublicCategoryDto> Categories { get; set; } = new();
}

public class PublicCategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public List<PublicMenuItemDto> Items { get; set; } = new();
}

public class PublicMenuItemDto
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
}