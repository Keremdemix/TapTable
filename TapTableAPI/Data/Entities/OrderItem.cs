using Iyzipay.Model;

namespace TapTable.Api.Data.Entities;

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int MenuItemId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public string? Note { get; set; }
    public OrderItemStatus Status { get; set; } = OrderItemStatus.Pending;

    // YENİ: "Seçerek Öde" akışında bu kalemden kaç adedin ödendiğini
    // takip eder. Quantity - PaidQuantity = henüz ödenmemiş (seçilebilir) adet.
    public int PaidQuantity { get; set; } = 0;

    public Order Order { get; set; } = null!;
    public MenuItem MenuItem { get; set; } = null!;

    // YENİ: bu kalemden hangi ödemelerin (Payment) kaçar adet karşıladığı.
    public ICollection<PaymentItem> PaymentItems { get; set; } = new List<PaymentItem>();
}

public enum OrderItemStatus
{
    Pending,
    Preparing,
    Ready,
    Served,
    Cancelled
}