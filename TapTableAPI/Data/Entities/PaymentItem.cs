namespace TapTable.Api.Data.Entities;

/// <summary>
/// SplitType.ByItem ("Seçerek Öde") ödemelerinde, bir Payment'ın hangi
/// sipariş kalemlerinden kaç adedi karşıladığını tutar. Bir Payment birden
/// fazla OrderItem'ı (ve bir OrderItem'ın kısmi adedini) kapsayabilir.
/// </summary>
public class PaymentItem
{
    public int Id { get; set; }
    public int PaymentId { get; set; }
    public int OrderItemId { get; set; }
    public int Quantity { get; set; }

    public Payment Payment { get; set; } = null!;
    public OrderItem OrderItem { get; set; } = null!;
}