using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Qr;
using TapTable.Api.DTOs.Response.Customer;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class QrSessionService : IQrSessionService
{
    private readonly IQrSessionRepository _qrRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IRestaurantRepository _restaurantRepository;
    private readonly string _customerBaseUrl;

    public QrSessionService(
        IQrSessionRepository qrRepository,
        ITableRepository tableRepository,
        IRestaurantRepository restaurantRepository,
        IConfiguration configuration)
    {
        _qrRepository = qrRepository;
        _tableRepository = tableRepository;
        _restaurantRepository = restaurantRepository;
        _customerBaseUrl = configuration["App:CustomerBaseUrl"]
            ?? "https://customer.taptable.com";
    }

    public async Task<QrSessionResponseDto> GetActiveSessionAsync(int tableId)
    {
        var session = await _qrRepository.GetActiveByTableIdAsync(tableId)
            ?? throw new KeyNotFoundException("Aktif oturum bulunamadı.");

        var restaurant = await _restaurantRepository.GetByIdAsync(session.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        return Map(session, restaurant);
    }

    public async Task<QrSessionResponseDto> CreateSessionAsync(CreateQrSessionRequestDto request)
    {
        var table = await _tableRepository.GetByIdAsync(request.TableId)
            ?? throw new KeyNotFoundException("Masa bulunamadı.");

        var session = new QrSession
        {
            TableId = request.TableId,
            RestaurantId = table.RestaurantId,
            SessionKey = Guid.NewGuid().ToString("N"),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        await _qrRepository.CreateAsync(session);

        var restaurant = await _restaurantRepository.GetByIdAsync(table.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        return Map(session, restaurant);
    }

    /// <summary>
    /// Müşteri app'in tek giriş noktası — token'dan aktif oturumu bulur,
    /// masa/restoran bilgisini token üzerinden çözer. Hiçbir tableId
    /// istemciden kabul edilmez.
    /// </summary>
    public async Task<CustomerSessionResponseDto> ResolveSessionAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrRepository.GetActiveByKeyAsync(token)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        var table = await _tableRepository.GetByIdAsync(session.TableId)
            ?? throw new KeyNotFoundException("Masa bulunamadı.");

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

    private QrSessionResponseDto Map(QrSession s, Restaurant r)
    {
        return new QrSessionResponseDto
        {
            Id = s.Id,
            TableId = s.TableId,
            SessionKey = s.SessionKey,
            IsActive = s.IsActive,
            CreatedAt = s.CreatedAt,
            QrUrl = $"{_customerBaseUrl}/menu?token={s.SessionKey}",
            Restaurant = new RestaurantBrandingDto
            {
                Id = r.Id,
                Name = r.Name,
                LogoUrl = r.LogoUrl,
                PrimaryColorHex = r.PrimaryColorHex,
                AccentColorHex = r.AccentColorHex
            }
        };
    }
}