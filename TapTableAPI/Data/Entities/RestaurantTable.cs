namespace TapTable.Api.Data.Entities;

public class RestaurantTable
{
    public int Id { get; set; }
    public int RestaurantId { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string QrCodeUrl { get; set; } = null!;
    public TableStatus Status { get; set; } = TableStatus.Available;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public TableLayout? Layout { get; set; }
    // Navigation
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