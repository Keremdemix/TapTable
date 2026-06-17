using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Qr;
using TapTable.Api.DTOs.Request.Qr;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class QrSessionService : IQrSessionService
{
    private readonly IQrSessionRepository _qrRepository;

    public QrSessionService(IQrSessionRepository qrRepository)
    {
        _qrRepository = qrRepository;
    }

    public async Task<QrSessionResponseDto> GetActiveSessionAsync(int tableId)
    {
        var session = await _qrRepository.GetActiveByTableIdAsync(tableId)
            ?? throw new Exception("Active session not found");

        return Map(session);
    }

    public async Task<QrSessionResponseDto> CreateSessionAsync(CreateQrSessionRequestDto request)
    {
        var session = new QrSession
        {
            TableId = request.TableId,
            RestaurantId = 1, 
            SessionKey = Guid.NewGuid().ToString("N"),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        await _qrRepository.CreateAsync(session);

        return Map(session);
    }

    private static QrSessionResponseDto Map(QrSession s)
    {
        return new QrSessionResponseDto
        {
            Id = s.Id,
            TableId = s.TableId,
            SessionKey = s.SessionKey,
            IsActive = s.IsActive,
            CreatedAt = s.CreatedAt,
            QrUrl = $"https://taptable.com/menu?table={s.TableId}&session={s.SessionKey}"
        };
    }
}