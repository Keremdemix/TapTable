namespace TapTable.Api.DTOs.Response.Payment;

public class PaymentResponseDto
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = null!;
    public string SplitType { get; set; } = null!;
    public string Status { get; set; } = null!;
    public string? StripePaymentIntentId { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class PaymentIntentResponseDto
{
    public int PaymentId { get; set; }
    public string ClientSecret { get; set; } = null!;
    public string PublishableKey { get; set; } = null!;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = null!;
}

public class BillItemDto
{
    public string Name { get; set; } = null!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}

public class BillSummaryResponseDto
{
    public int OrderId { get; set; }
    public int TableNumber { get; set; }
    public List<BillItemDto> Items { get; set; } = new();
    public decimal TotalPrice { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public string PaymentStatus { get; set; } = null!;
}