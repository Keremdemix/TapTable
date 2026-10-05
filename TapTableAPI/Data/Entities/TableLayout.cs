namespace TapTable.Api.Data.Entities;

public class TableLayout
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public int PositionX { get; set; }
    public int PositionY { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public string Shape { get; set; } = "rectangle"; // rectangle | circle

    // Navigation
    public RestaurantTable Table { get; set; } = null!;
}