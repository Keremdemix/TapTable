namespace TapTable.Api.DTOs.Request.IyzicoConnect;

public class RegisterSubMerchantRequestDto
{
    public string ContactName { get; set; } = null!;
    public string ContactSurname { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string GsmNumber { get; set; } = null!;      // +905xxxxxxxxx
    public string Iban { get; set; } = null!;           // TR...
    public string LegalCompanyTitle { get; set; } = null!;
    public string TaxOffice { get; set; } = null!;
    public string TaxNumber { get; set; } = null!;      // Vergi no
    public string Address { get; set; } = null!;
}