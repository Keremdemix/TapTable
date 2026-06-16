namespace TapTableAPI.DTOs.Response.Order;

public class OrderResponse
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public int TableNumber { get; set; }
    public int? WaiterId { get; set; }
    public string? WaiterName { get; set; }
    public string Status { get; set; } = null!;
    public string PaymentStatus { get; set; } = null!;
    public decimal TotalPrice { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<OrderItemResponse> Items { get; set; } = new();
}

public class OrderItemResponse
{
    public int Id { get; set; }
    public int MenuItemId { get; set; }
    public string MenuItemName { get; set; } = null!;
    public string? MenuItemImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal SubTotal => UnitPrice * Quantity;
    public string? Note { get; set; }
}

public class OrderSummaryResponse
{
    public int Id { get; set; }
    public int TableNumber { get; set; }
    public string Status { get; set; } = null!;
    public string PaymentStatus { get; set; } = null!;
    public decimal TotalPrice { get; set; }
    public int ItemCount { get; set; }
    public DateTime CreatedAt { get; set; }
}
