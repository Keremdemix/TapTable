namespace TapTable.Api.DTOs.Response.Payment;

/// <summary>
/// Müşterinin ödeme ekranında ihtiyaç duyduğu her şeyi tek seferde döner:
/// kalan tutar, kalem bazlı ödenmiş/ödenmemiş adetler ve varsa aktif
/// bölüşüm planı. Frontend "Seçerek Öde / Bölerek Öde / Hepsini Öde"
/// butonlarının hangisinin aktif/kilitli olacağına bu DTO'ya bakarak karar
/// verir (ActiveSplitPlan doluysa Seçerek Öde + Hepsini Öde kilitlenir).
/// </summary>
public class OrderPaymentStateResponseDto
{
    public int OrderId { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal RemainingAmount { get; set; }
    public string PaymentStatus { get; set; } = null!;
    public List<PaymentStateItemDto> Items { get; set; } = new();
    public SplitPaymentPlanResponseDto? ActiveSplitPlan { get; set; }
}

public class PaymentStateItemDto
{
    public int OrderItemId { get; set; }
    public string MenuItemName { get; set; } = null!;
    public string MenuItemImageUrl { get; set; } = null!;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public int PaidQuantity { get; set; }
    public int UnpaidQuantity => Quantity - PaidQuantity;
}

public class SplitPaymentPlanResponseDto
{
    public int Id { get; set; }
    public int TotalPeople { get; set; }
    public decimal TotalAmount { get; set; }
    public int SharesPaid { get; set; }
    public decimal AmountPerPerson => TotalPeople == 0 ? 0 : TotalAmount / TotalPeople;
    public string Status { get; set; } = null!;
}