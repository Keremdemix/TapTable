using TapTable.Api.DTOs.Menu;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class MenuService : IMenuService
{
    private readonly IMenuRepository _menuRepository;

    public MenuService(IMenuRepository menuRepository)
    {
        _menuRepository = menuRepository;
    }

    public async Task<IEnumerable<MenuDto>> GetMenusAsync(int restaurantId)
    {
        var menus = await _menuRepository.GetMenusByRestaurantAsync(restaurantId);
        return menus.Select(MapToMenuDto);
    }

    public async Task<MenuDto> GetMenuByIdAsync(int menuId, int restaurantId)
    {
        var menu = await _menuRepository.GetMenuByIdAsync(menuId, restaurantId)
            ?? throw new KeyNotFoundException($"Menü bulunamadı: {menuId}");
        return MapToMenuDto(menu);
    }

    public async Task<MenuDto> CreateMenuAsync(int restaurantId, CreateMenuDto request)
    {
        var menu = new Menu
        {
            RestaurantId = restaurantId,
            Name = request.Name,
            Description = request.Description,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        var created = await _menuRepository.CreateMenuAsync(menu);
        return MapToMenuDto(created);
    }

    public async Task<MenuDto> UpdateMenuAsync(int menuId, int restaurantId, UpdateMenuDto request)
    {
        var menu = await _menuRepository.GetMenuByIdAsync(menuId, restaurantId)
            ?? throw new KeyNotFoundException($"Menü bulunamadı: {menuId}");

        menu.Name = request.Name;
        menu.Description = request.Description;
        menu.IsActive = request.IsActive;
        menu.UpdatedAt = DateTime.UtcNow;

        var updated = await _menuRepository.UpdateMenuAsync(menu);
        return MapToMenuDto(updated);
    }

    public async Task DeleteMenuAsync(int menuId, int restaurantId)
    {
        var menu = await _menuRepository.GetMenuByIdAsync(menuId, restaurantId)
            ?? throw new KeyNotFoundException($"Menü bulunamadı: {menuId}");
        await _menuRepository.DeleteMenuAsync(menu);
    }

    public async Task<IEnumerable<MenuItemDto>> GetMenuItemsAsync(int menuId, int restaurantId)
    {
        var items = await _menuRepository.GetMenuItemsByMenuAsync(menuId, restaurantId);
        return items.Select(MapToMenuItemDto);
    }

    public async Task<MenuItemDto> GetMenuItemByIdAsync(int itemId, int restaurantId)
    {
        var item = await _menuRepository.GetMenuItemByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");
        return MapToMenuItemDto(item);
    }

    public async Task<MenuItemDto> CreateMenuItemAsync(int restaurantId, CreateMenuItemDto request)
    {
        var item = new MenuItem
        {
            MenuId = request.MenuId,
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            ImageUrl = request.ImageUrl,
            IsAvailable = true,
            CreatedAt = DateTime.UtcNow
        };
        var created = await _menuRepository.CreateMenuItemAsync(item);
        return MapToMenuItemDto(created);
    }

    public async Task<MenuItemDto> UpdateMenuItemAsync(int itemId, int restaurantId, UpdateMenuItemDto request)
    {
        var item = await _menuRepository.GetMenuItemByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        item.Name = request.Name;
        item.Description = request.Description;
        item.Price = request.Price;
        item.ImageUrl = request.ImageUrl;
        item.IsAvailable = request.IsAvailable;
        item.UpdatedAt = DateTime.UtcNow;

        var updated = await _menuRepository.UpdateMenuItemAsync(item);
        return MapToMenuItemDto(updated);
    }

    public async Task DeleteMenuItemAsync(int itemId, int restaurantId)
    {
        var item = await _menuRepository.GetMenuItemByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");
        await _menuRepository.DeleteMenuItemAsync(item);
    }

    public async Task<MenuItemDto> ToggleAvailabilityAsync(int itemId, int restaurantId)
    {
        var item = await _menuRepository.GetMenuItemByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        item.IsAvailable = !item.IsAvailable;
        item.UpdatedAt = DateTime.UtcNow;

        var updated = await _menuRepository.UpdateMenuItemAsync(item);
        return MapToMenuItemDto(updated);
    }

    // ── Mappers ──────────────────────────────────────────────────────────────

    private static MenuDto MapToMenuDto(Menu m) => new()
    {
        Id = m.Id,
        Name = m.Name,
        Description = m.Description,
        IsActive = m.IsActive,
        CreatedAt = m.CreatedAt
    };

    private static MenuItemDto MapToMenuItemDto(MenuItem i) => new()
    {
        Id = i.Id,
        MenuId = i.MenuId,
        Name = i.Name,
        Description = i.Description,
        Price = i.Price,
        ImageUrl = i.ImageUrl,
        IsAvailable = i.IsAvailable,
        CreatedAt = i.CreatedAt
    };
}
