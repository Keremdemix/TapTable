using TapTable.Api.DTOs.Request.IyzicoConnect;
using TapTable.Api.DTOs.Response.IyzicoConnect;

namespace TapTable.Api.Services.Interfaces;

public interface IIyzicoSubMerchantService
{
    Task<IyzicoSubMerchantStatusResponseDto> GetStatusAsync(int restaurantId);
    Task<IyzicoSubMerchantStatusResponseDto> RegisterAsync(int restaurantId, RegisterSubMerchantRequestDto dto);
}