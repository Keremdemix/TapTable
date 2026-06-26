namespace TapTable.Api.Data.Entities;

public class Payment
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }
    public SplitType SplitType { get; set; } = SplitType.Full;
    public string? IyzicoPaymentId { get; set; } 
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime CreatedAt { get; set; }

    public Order Order { get; set; } = null!;
}

public enum PaymentMethod
{
    Cash,
    Card,   // garson POS
    Iyzico 
}

public enum SplitType
{
    Full,
    Equal,
    ByItem // şimdilik kullanılmıyor, ileride hesap bölme için
}

public enum PaymentStatus
{
    Pending,
    Succeeded,
    Failed,
    Refunded
}