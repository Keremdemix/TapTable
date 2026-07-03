using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Qr;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class QrSessionService : IQrSessionService
{
    private readonly IQrSessionRepository _qrRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IRestaurantRepository _restaurantRepository;

    public QrSessionService(
        IQrSessionRepository qrRepository,
        ITableRepository tableRepository,
        IRestaurantRepository restaurantRepository)
    {
        _qrRepository = qrRepository;
        _tableRepository = tableRepository;
        _restaurantRepository = restaurantRepository;
    }

    public async Task<QrSessionResponseDto> GetActiveSessionAsync(int tableId)
    {
        var session = await _qrRepository.GetActiveByTableIdAsync(tableId)
            ?? throw new Exception("Active session not found");

        var restaurant = await _restaurantRepository.GetByIdAsync(session.RestaurantId)
            ?? throw new Exception("Restaurant not found");

        return Map(session, restaurant);
    }

    public async Task<QrSessionResponseDto> CreateSessionAsync(CreateQrSessionRequestDto request)
    {
        var table = await _tableRepository.GetByIdAsync(request.TableId)
            ?? throw new Exception("Masa bulunamadı");

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
            ?? throw new Exception("Restaurant not found");

        return Map(session, restaurant);
    }

    private static QrSessionResponseDto Map(QrSession s, Restaurant r)
    {
        return new QrSessionResponseDto
        {
            Id = s.Id,
            TableId = s.TableId,
            SessionKey = s.SessionKey,
            IsActive = s.IsActive,
            CreatedAt = s.CreatedAt,
            QrUrl = $"https://taptable.com/menu?table={s.TableId}&session={s.SessionKey}",
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