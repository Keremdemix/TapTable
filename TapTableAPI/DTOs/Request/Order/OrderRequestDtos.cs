using TapTable.Api.Data.Entities;

namespace TapTable.Api.DTOs.Request.Order;

public class OrderItemRequestDto
{
    public int MenuItemId { get; set; }
    public int Quantity { get; set; }
    public string? Note { get; set; }
}

// Müşteri — QR session ile gönderir
public class PlaceOrderRequestDto
{
    public List<OrderItemRequestDto> Items { get; set; } = new();
    public string? Note { get; set; }
}
// Garson — kendisi sisteme girer
public class StaffCreateOrderRequestDto
{
    public int TableId { get; set; }
    public List<OrderItemRequestDto> Items { get; set; } = new();
    public string? Note { get; set; }
}

public class UpdateOrderItemStatusRequestDto
{
    public OrderItemStatus Status { get; set; }
}

public class UpdateOrderStatusRequestDto
{
    public OrderStatus Status { get; set; }
}