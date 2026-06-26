using TapTable.Api.DTOs.Request.IyzicoConnect;
using TapTable.Api.DTOs.Response.IyzicoConnect;

namespace TapTable.Api.Services.Interfaces;

public interface IIyzicoSubMerchantService
{
    Task<IyzicoSubMerchantStatusDto> GetStatusAsync(int restaurantId);
    Task<IyzicoSubMerchantStatusDto> RegisterAsync(int restaurantId, RegisterSubMerchantRequestDto dto);
}