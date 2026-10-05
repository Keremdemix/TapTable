using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Menu;
using TapTable.Api.DTOs.Response.Menu;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;
using TapTableAPI.Repositories.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class MenuService : IMenuService
{
    private readonly ICategoryRepository _categoryRepository;
    private readonly IMenuItemRepository _menuItemRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;

    public MenuService(
        ICategoryRepository categoryRepository,
        IMenuItemRepository menuItemRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository)
    {
        _categoryRepository = categoryRepository;
        _menuItemRepository = menuItemRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
    }

    // ── Kategori — Admin ─────────────────────────────────────────────────

    public async Task<IEnumerable<CategoryResponseDto>> GetCategoriesAsync(int restaurantId)
    {
        var categories = await _categoryRepository.GetAllAsync(restaurantId);

        var result = new List<CategoryResponseDto>();
        foreach (var category in categories)
        {
            var itemCount = await _menuItemRepository.CountByCategoryAsync(category.Id);
            result.Add(MapToDto(category, itemCount));
        }

        return result;
    }

    public async Task<CategoryResponseDto> CreateCategoryAsync(int restaurantId, CreateCategoryRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ArgumentException("Kategori adı boş olamaz.");

        var category = new Category
        {
            RestaurantId = restaurantId,
            Name = request.Name.Trim(),
            SortOrder = request.SortOrder,
            IsActive = true
        };

        var created = await _categoryRepository.CreateAsync(category);
        return MapToDto(created, 0);
    }

    public async Task<CategoryResponseDto> UpdateCategoryAsync(int categoryId, int restaurantId, UpdateCategoryRequestDto request)
    {
        var category = await _categoryRepository.GetByIdAsync(categoryId, restaurantId)
            ?? throw new KeyNotFoundException($"Kategori bulunamadı: {categoryId}");

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ArgumentException("Kategori adı boş olamaz.");

        category.Name = request.Name.Trim();
        category.SortOrder = request.SortOrder;
        category.IsActive = request.IsActive;

        var updated = await _categoryRepository.UpdateAsync(category);
        var itemCount = await _menuItemRepository.CountByCategoryAsync(categoryId);
        return MapToDto(updated, itemCount);
    }

    public async Task DeleteCategoryAsync(int categoryId, int restaurantId)
    {
        var category = await _categoryRepository.GetByIdAsync(categoryId, restaurantId)
            ?? throw new KeyNotFoundException($"Kategori bulunamadı: {categoryId}");

        var itemCount = await _menuItemRepository.CountByCategoryAsync(categoryId);
        if (itemCount > 0)
            throw new InvalidOperationException("Bu kategoride aktif ürünler var. Önce ürünleri silin veya başka kategoriye taşıyın.");

        await _categoryRepository.DeleteAsync(category);
    }

    // ── Ürün — Admin ─────────────────────────────────────────────────────

    public async Task<IEnumerable<MenuItemResponseDto>> GetMenuItemsAsync(int restaurantId, int? categoryId = null)
    {
        var items = await _menuItemRepository.GetAllAsync(restaurantId, categoryId);
        return items.Select(MapToDto);
    }

    public async Task<MenuItemResponseDto> GetMenuItemAsync(int itemId, int restaurantId)
    {
        var item = await _menuItemRepository.GetByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        return MapToDto(item);
    }

    public async Task<MenuItemResponseDto> CreateMenuItemAsync(int restaurantId, CreateMenuItemRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ArgumentException("Ürün adı boş olamaz.");

        if (request.Price < 0)
            throw new ArgumentException("Fiyat negatif olamaz.");

        // Kategori bu restorana mı ait, kontrol et — yoksa başka restoranın
        // kategorisine ürün eklenebilir
        var category = await _categoryRepository.GetByIdAsync(request.CategoryId, restaurantId)
            ?? throw new KeyNotFoundException($"Kategori bulunamadı: {request.CategoryId}");

        var item = new MenuItem
        {
            CategoryId = category.Id,
            Name = request.Name.Trim(),
            Description = request.Description,
            Price = request.Price,
            ImageUrl = request.ImageUrl,
            SortOrder = request.SortOrder,
            IsAvailable = true,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _menuItemRepository.CreateAsync(item);
        created.Category = category;
        return MapToDto(created);
    }

    public async Task<MenuItemResponseDto> UpdateMenuItemAsync(int itemId, int restaurantId, UpdateMenuItemRequestDto request)
    {
        var item = await _menuItemRepository.GetByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ArgumentException("Ürün adı boş olamaz.");

        if (request.Price < 0)
            throw new ArgumentException("Fiyat negatif olamaz.");

        if (request.CategoryId != item.CategoryId)
        {
            var newCategory = await _categoryRepository.GetByIdAsync(request.CategoryId, restaurantId)
                ?? throw new KeyNotFoundException($"Kategori bulunamadı: {request.CategoryId}");
            item.CategoryId = newCategory.Id;
            item.Category = newCategory;
        }

        item.Name = request.Name.Trim();
        item.Description = request.Description;
        item.Price = request.Price;
        item.ImageUrl = request.ImageUrl;
        item.SortOrder = request.SortOrder;
        item.IsAvailable = request.IsAvailable;
        item.IsActive = request.IsActive;

        var updated = await _menuItemRepository.UpdateAsync(item);
        return MapToDto(updated);
    }

    public async Task<MenuItemResponseDto> SetAvailabilityAsync(int itemId, int restaurantId, bool isAvailable)
    {
        var item = await _menuItemRepository.GetByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        item.IsAvailable = isAvailable;
        var updated = await _menuItemRepository.UpdateAsync(item);
        return MapToDto(updated);
    }

    public async Task DeleteMenuItemAsync(int itemId, int restaurantId)
    {
        var item = await _menuItemRepository.GetByIdAsync(itemId, restaurantId)
            ?? throw new KeyNotFoundException($"Ürün bulunamadı: {itemId}");

        await _menuItemRepository.DeleteAsync(item);
    }

    // ── Müşteri — Public ─────────────────────────────────────────────────

    public async Task<PublicMenuResponseDto> GetPublicMenuByTokenAsync(string token)
    {
        var session = await _qrSessionRepository.GetActiveByKeyAsync(token)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        var table = await _tableRepository.GetByIdAsync(session.TableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {session.TableId}");

        var categories = await _categoryRepository.GetPublicMenuAsync(table.RestaurantId);

        return new PublicMenuResponseDto
        {
            RestaurantId = table.RestaurantId,
            RestaurantName = table.Restaurant?.Name ?? string.Empty,
            Categories = categories.Select(c => new PublicCategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Items = c.MenuItems.Select(m => new PublicMenuItemDto
                {
                    Id = m.Id,
                    Name = m.Name,
                    Description = m.Description,
                    Price = m.Price,
                    ImageUrl = m.ImageUrl
                }).ToList()
            }).ToList()
        };
    }
    // ── Helpers ──────────────────────────────────────────────────────────

    private static CategoryResponseDto MapToDto(Category c, int itemCount) => new()
    {
        Id = c.Id,
        RestaurantId = c.RestaurantId,
        Name = c.Name,
        SortOrder = c.SortOrder,
        IsActive = c.IsActive,
        MenuItemCount = itemCount
    };

    private static MenuItemResponseDto MapToDto(MenuItem m) => new()
    {
        Id = m.Id,
        CategoryId = m.CategoryId,
        CategoryName = m.Category?.Name ?? string.Empty,
        Name = m.Name,
        Description = m.Description,
        Price = m.Price,
        ImageUrl = m.ImageUrl,
        IsAvailable = m.IsAvailable,
        IsActive = m.IsActive,
        SortOrder = m.SortOrder,
        CreatedAt = m.CreatedAt,
        UpdatedAt = m.UpdatedAt
    };
}