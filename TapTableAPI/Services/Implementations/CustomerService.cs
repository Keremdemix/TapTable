using TapTable.Api.DTOs.Response.Customer;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CustomerService : ICustomerService
{
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;
    private readonly IRestaurantRepository _restaurantRepository;

    public CustomerService(
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IRestaurantRepository restaurantRepository)
    {
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _restaurantRepository = restaurantRepository;
    }

    public async Task<CustomerSessionResponseDto> ResolveSessionAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrSessionRepository.GetActiveByKeyAsync(token)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        var table = await _tableRepository.GetByIdAsync(session.TableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {session.TableId}");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        var restaurant = await _restaurantRepository.GetByIdAsync(session.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        return new CustomerSessionResponseDto
        {
            RestaurantId = restaurant.Id,
            TableId = table.Id,
            TableNumber = table.TableNumber,
            RestaurantName = restaurant.Name,
            LogoUrl = restaurant.LogoUrl,
            PrimaryColorHex = restaurant.PrimaryColorHex,
            AccentColorHex = restaurant.AccentColorHex
        };
    }
}