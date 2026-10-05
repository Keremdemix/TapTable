namespace TapTable.Api.DTOs.Request.Menu;

public class CreateCategoryRequestDto
{
    public string Name { get; set; } = null!;
    public int SortOrder { get; set; }
}

public class UpdateCategoryRequestDto
{
    public string Name { get; set; } = null!;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
}