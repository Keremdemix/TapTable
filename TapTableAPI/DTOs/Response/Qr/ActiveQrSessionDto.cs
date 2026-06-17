namespace TapTable.Api.DTOs.Response.Qr;

public class ActiveQrSessionDto
{
    public int TableId { get; set; }
    public string SessionToken { get; set; } = null!;
}