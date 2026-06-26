namespace TapTable.Api.DTOs.Request.Payment;

public class InitiateIyzicoPaymentRequestDto
{
    public string SessionKey { get; set; } = null!;
    public string BuyerName { get; set; } = null!;
    public string BuyerSurname { get; set; } = null!;
    public string BuyerGsmNumber { get; set; } = null!;
    public string? BuyerEmail { get; set; }
}