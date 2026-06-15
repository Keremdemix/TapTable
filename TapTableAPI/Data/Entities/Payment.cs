namespace TapTable.Api.Data.Entities;

public class Payment
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = "Card";   // Card | Cash | ApplePay | GooglePay
    public string SplitType { get; set; } = "Full"; // Full | Equal | Custom
    public string? StripePaymentIntentId { get; set; }
    public string Status { get; set; } = "Pending"; // Pending | Succeeded | Failed | Refunded
    public DateTime? PaidAt { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation
    public Order Order { get; set; } = null!;
}