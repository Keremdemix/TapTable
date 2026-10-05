namespace TapTable.Api.DTOs.Request.Table;

public class UpdateTableLayoutItemDto
{
    public int TableId { get; set; }
    public int PositionX { get; set; }
    public int PositionY { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public string Shape { get; set; } = null!;
}

public class UpdateLayoutRequestDto
{
    public List<UpdateTableLayoutItemDto> Layouts { get; set; } = new();
}