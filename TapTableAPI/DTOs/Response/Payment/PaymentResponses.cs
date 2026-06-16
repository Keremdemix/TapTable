namespace TapTableAPI.DTOs.Response.Payment;

public class PaymentIntentResponse
{
    public string ClientSecret { get; set; } = null!;   // Flutter'a gönderilir, Stripe SDK kullanır
    public string PaymentIntentId { get; set; } = null!;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "try";
}

public class PaymentResponse
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public string Method { get; set; } = null!;
    public string SplitType { get; set; } = null!;
    public string Status { get; set; } = null!;
    public DateTime? PaidAt { get; set; }
}
