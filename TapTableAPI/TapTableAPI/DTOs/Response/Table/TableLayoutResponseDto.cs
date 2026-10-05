namespace TapTable.Api.DTOs.Response.Table;

public class TableLayoutResponseDto
{
    public int TableId { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string Status { get; set; } = null!;
    public int Width { get; set; }
    public int Height { get; set; }
    public string Shape { get; set; } = null!;
    public int PositionX { get; set; }
    public int PositionY { get; set; }
}