using TapTable.Api.DTOs.Request.Menu;
using TapTable.Api.DTOs.Response.Menu;

namespace TapTable.Api.Services.Interfaces;

public interface IMenuService
{
    // Kategori — Admin
    Task<IEnumerable<CategoryResponseDto>> GetCategoriesAsync(int restaurantId);
    Task<CategoryResponseDto> CreateCategoryAsync(int restaurantId, CreateCategoryRequestDto request);
    Task<CategoryResponseDto> UpdateCategoryAsync(int categoryId, int restaurantId, UpdateCategoryRequestDto request);
    Task DeleteCategoryAsync(int categoryId, int restaurantId);

    // Ürün — Admin
    Task<IEnumerable<MenuItemResponseDto>> GetMenuItemsAsync(int restaurantId, int? categoryId = null);
    Task<MenuItemResponseDto> GetMenuItemAsync(int itemId, int restaurantId);
    Task<MenuItemResponseDto> CreateMenuItemAsync(int restaurantId, CreateMenuItemRequestDto request);
    Task<MenuItemResponseDto> UpdateMenuItemAsync(int itemId, int restaurantId, UpdateMenuItemRequestDto request);
    Task<MenuItemResponseDto> SetAvailabilityAsync(int itemId, int restaurantId, bool isAvailable);
    Task DeleteMenuItemAsync(int itemId, int restaurantId);
    Task<PublicMenuResponseDto> GetPublicMenuByTokenAsync(string token);

}