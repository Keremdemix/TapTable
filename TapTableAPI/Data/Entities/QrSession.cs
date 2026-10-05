namespace TapTable.Api.Data.Entities;

public class QrSession
{
    public int Id { get; set; }

    public int TableId { get; set; }
    public int RestaurantId { get; set; }

    public string SessionKey { get; set; } = null!;
    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }

    // Navigation
    public RestaurantTable Table { get; set; } = null!;
    public Restaurant Restaurant { get; set; } = null!;
}