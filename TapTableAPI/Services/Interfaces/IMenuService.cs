using TapTable.Api.DTOs.Menu;

namespace TapTable.Api.Services.Interfaces;

public interface IMenuService
{
    Task<IEnumerable<MenuDto>> GetMenusAsync(int restaurantId);
    Task<MenuDto> GetMenuByIdAsync(int menuId, int restaurantId);
    Task<MenuDto> CreateMenuAsync(int restaurantId, CreateMenuDto request);
    Task<MenuDto> UpdateMenuAsync(int menuId, int restaurantId, UpdateMenuDto request);
    Task DeleteMenuAsync(int menuId, int restaurantId);

    Task<IEnumerable<MenuItemDto>> GetMenuItemsAsync(int menuId, int restaurantId);
    Task<MenuItemDto> GetMenuItemByIdAsync(int itemId, int restaurantId);
    Task<MenuItemDto> CreateMenuItemAsync(int restaurantId, CreateMenuItemDto request);
    Task<MenuItemDto> UpdateMenuItemAsync(int itemId, int restaurantId, UpdateMenuItemDto request);
    Task DeleteMenuItemAsync(int itemId, int restaurantId);
    Task<MenuItemDto> ToggleAvailabilityAsync(int itemId, int restaurantId);
}
