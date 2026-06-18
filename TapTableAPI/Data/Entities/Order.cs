namespace TapTable.Api.Data.Entities;

public class Order
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public int? WaiterId { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public OrderPaymentStatus PaymentStatus { get; set; } = OrderPaymentStatus.Unpaid;
    public decimal TotalPrice { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public RestaurantTable Table { get; set; } = null!;
    public User? Waiter { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}

public enum OrderStatus
{
    Pending,
    Preparing,
    Ready,
    Served,
    Completed,
    Cancelled
}

public enum OrderPaymentStatus
{
    Unpaid,
    PartiallyPaid,
    Paid
}