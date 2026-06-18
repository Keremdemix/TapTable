namespace TapTable.Api.Data.Entities;

public class Order
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public int? WaiterId { get; set; }          // null = müşteri QR'dan verdi
    public string Status { get; set; } = "Pending";
    // Pending | Preparing | Ready | Delivered | Cancelled
    public string PaymentStatus { get; set; } = "Unpaid";
    // Unpaid | PartiallyPaid | Paid
    public decimal TotalPrice { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    // Navigation
    public RestaurantTable Table { get; set; } = null!;
    public User? Waiter { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}