namespace TapTable.Api.Data.Entities;

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int MenuItemId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public string? Note { get; set; }
    public OrderItemStatus Status { get; set; } = OrderItemStatus.Pending;

    public Order Order { get; set; } = null!;
    public MenuItem MenuItem { get; set; } = null!;
}

public enum OrderItemStatus
{
    Pending,
    Preparing,
    Ready,
    Served,
    Cancelled
}