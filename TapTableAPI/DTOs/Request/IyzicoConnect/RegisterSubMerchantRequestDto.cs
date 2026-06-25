namespace TapTable.Api.DTOs.Response.IyzicoConnect;

public class IyzicoSubMerchantStatusResponseDto
{
    public bool HasSubMerchant { get; set; }
    public bool IsApproved { get; set; }
    public string? SubMerchantKey { get; set; }
}