namespace TapTable.Api.Data.Entities;

/// <summary>
/// Bir siparişin "Bölerek Öde" (eşit bölüşüm) ile ödenmesi durumunda oluşur.
/// Bir siparişte aynı anda en fazla bir Active plan olabilir — bu kural
/// PaymentService içinde uygulanır (veritabanı seviyesinde zorlanmıyor).
/// Plan Active olduğu sürece siparişte "Seçerek Öde" ve "Hepsini Öde"
/// kilitlenir; sadece kalan paylar Equal tipinde Payment kayıtlarıyla
/// ödenebilir. En az bir pay ödendiyse (SharesPaid > 0) plan iptal edilemez.
/// </summary>
public class SplitPaymentPlan
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int TotalPeople { get; set; }

    // Plan oluşturulduğu andaki ödenecek tutar (snapshot) — sipariş daha
    // sonra değişse bile bu plan hep aynı tutarı böler.
    public decimal TotalAmount { get; set; }

    // Sadece Succeeded (onaylanmış) paylar sayılır.
    public int SharesPaid { get; set; }
    public SplitPlanStatus Status { get; set; } = SplitPlanStatus.Active;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public Order Order { get; set; } = null!;
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}

public enum SplitPlanStatus
{
    Active,
    Completed,
    Cancelled
}