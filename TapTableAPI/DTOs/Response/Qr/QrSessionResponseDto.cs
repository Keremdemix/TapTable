namespace TapTable.Api.DTOs.Qr;

public class QrSessionResponseDto
{
    public int Id { get; set; }
    public int TableId { get; set; }
    public string SessionKey { get; set; } = null!;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    public string QrUrl { get; set; } = null!;
}