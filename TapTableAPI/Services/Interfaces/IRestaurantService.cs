namespace TapTable.Api.Services.Interfaces;

public interface IRestaurantService
{
    Task<RestaurantBrandingResponse?> GetBrandingAsync(int restaurantId);
    Task<bool> UpdateBrandingAsync(int restaurantId, UpdateRestaurantBrandingRequest request);
}