namespace TapTableAPI.DTOs.Response.Table;

public class TableResponse
{
    public int Id { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string? QrCodeUrl { get; set; }
    public string Status { get; set; } = null!;   // Available | Occupied | Reserved
    public TableLayoutResponse? Layout { get; set; }
    public ActiveOrderInfo? ActiveOrder { get; set; }
}

public class TableLayoutResponse
{
    public int PositionX { get; set; }
    public int PositionY { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public string Shape { get; set; } = null!;
}

public class ActiveOrderInfo
{
    public int OrderId { get; set; }
    public string OrderStatus { get; set; } = null!;
    public decimal TotalPrice { get; set; }
    public int ItemCount { get; set; }
}
