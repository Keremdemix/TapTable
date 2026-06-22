using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IQrSessionRepository
{
    Task<QrSession?> GetActiveByTableIdAsync(int tableId);
    Task<QrSession?> GetBySessionKeyAsync(string sessionKey);
    Task<QrSession?> GetActiveByKeyAsync(string sessionKey);
    Task<QrSession> RotateSessionAsync(int tableId, int restaurantId);

    Task CreateAsync(QrSession session);
    Task UpdateAsync(QrSession session);
    Task CloseActiveSessionAsync(int tableId);
}