namespace TapTable.Api.Data.Entities;

public class RestaurantTable
{
    public int Id { get; set; }
    public int RestaurantId { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string? QrCodeUrl { get; set; }
    public string Status { get; set; } = "Available"; // Available | Occupied | Reserved
    public bool IsActive { get; set; }

    // Navigation
    public Restaurant Restaurant { get; set; } = null!;
    public TableLayout? Layout { get; set; }
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}