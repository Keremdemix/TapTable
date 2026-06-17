using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IQrSessionRepository
{
    Task<QrSession?> GetActiveByTableIdAsync(int tableId);
    Task<QrSession?> GetBySessionKeyAsync(string sessionKey);

    Task CreateAsync(QrSession session);
    Task UpdateAsync(QrSession session);
}