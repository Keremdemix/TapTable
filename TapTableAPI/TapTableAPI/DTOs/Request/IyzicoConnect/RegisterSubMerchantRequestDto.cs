namespace TapTable.Api.DTOs.Request.IyzicoConnect;

public class RegisterSubMerchantRequestDto
{
    public string ContactName { get; set; } = null!;
    public string ContactSurname { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string GsmNumber { get; set; } = null!;
    public string Iban { get; set; } = null!;
    public string LegalCompanyTitle { get; set; } = null!;
    public string TaxOffice { get; set; } = null!;
    public string TaxNumber { get; set; } = null!;
    public string Address { get; set; } = null!;
}