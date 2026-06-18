namespace TapTable.Api.DTOs.Response.Table;

public class TableResponseDto
{
    public int Id { get; set; }
    public int RestaurantId { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public string QrCodeUrl { get; set; } = null!;
    public string Status { get; set; } = null!;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// Admin QR yenilediğinde döner — yeni QR URL'i içerir
/// </summary>
public class RegenerateQrResponseDto
{
    public int TableId { get; set; }
    public int TableNumber { get; set; }
    public string QrCodeUrl { get; set; } = null!;
    public string NewSessionKey { get; set; } = null!;
}