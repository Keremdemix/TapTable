namespace TapTable.Api.DTOs.Response.Payment;

public class IyzicoCheckoutResponseDto
{
    public int PaymentId { get; set; }
    public string Token { get; set; } = null!;
    public string PaymentPageUrl { get; set; } = null!;
}