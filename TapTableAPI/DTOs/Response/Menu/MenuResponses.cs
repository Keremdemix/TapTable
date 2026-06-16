namespace TapTableAPI.DTOs.Response.Menu;

public class CategoryResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public int SortOrder { get; set; }
    public List<MenuItemResponse> Items { get; set; } = new();
}

public class MenuItemResponse
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsAvailable { get; set; }
    public int SortOrder { get; set; }
}
