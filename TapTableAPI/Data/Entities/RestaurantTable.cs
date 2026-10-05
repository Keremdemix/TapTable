namespace TapTable.Api.Data.Entities;

public class RestaurantTable
{
    public int Id { get; set; }
    public int RestaurantId { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string QrCodeUrl { get; set; } = null!;

    // YENİ — QR kodun içine gömülen SABİT tanımlayıcı. SessionKey'in aksine
    // hiç değişmez; müşteri QR'ı okuttuğunda bununla masa bulunur, sonra
    // o masanın güncel aktif SessionKey'i (varsa) döndürülür ya da
    // (yoksa/rotate olduysa) yeni bir tanesi oluşturulur.
    public string QrToken { get; set; } = Guid.NewGuid().ToString("N");

    public TableStatus Status { get; set; } = TableStatus.Available;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public TableLayout? Layout { get; set; }
    public Restaurant Restaurant { get; set; } = null!;
    public ICollection<QrSession> QrSessions { get; set; } = new List<QrSession>();
}

public enum TableStatus
{
    Available,
    Occupied,
    Reserved,
    OutOfService
}