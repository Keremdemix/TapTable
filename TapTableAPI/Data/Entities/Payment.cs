using Iyzipay.Model;

namespace TapTable.Api.Data.Entities;

public class Payment
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }
    public SplitType SplitType { get; set; } = SplitType.Full;
    public string? IyzicoPaymentId { get; set; }
    public string? IyzicoPaymentTransactionId { get; set; }   // onay (escrow release) API'si bunu istiyor
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime CreatedAt { get; set; }

    // YENİ — SplitType.Equal ("Bölerek Öde") için: bu ödemenin bağlı olduğu
    // plan ve kaç payı karşıladığı (bir kişi birden fazla pay ödeyebilir).
    public int? SplitPaymentPlanId { get; set; }
    public int SharesCovered { get; set; } = 1;

    public Order Order { get; set; } = null!;
    public SplitPaymentPlan? SplitPaymentPlan { get; set; }

    // YENİ — SplitType.ByItem ("Seçerek Öde") için: bu ödemenin karşıladığı
    // sipariş kalemleri ve adetleri.
    public ICollection<PaymentItem> PaymentItems { get; set; } = new List<PaymentItem>();
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
    ByItem
}

public enum PaymentStatus
{
    Pending,
    Succeeded,
    Failed,
    Refunded
}