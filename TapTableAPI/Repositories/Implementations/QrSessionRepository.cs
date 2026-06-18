using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class QrSessionRepository : IQrSessionRepository
{
    private readonly TapTableDbContext _context;

    public QrSessionRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<QrSession?> GetActiveByTableIdAsync(int tableId)
    {
        return await _context.QrSessions
            .FirstOrDefaultAsync(x => x.TableId == tableId && x.IsActive);
    }

    public async Task<QrSession?> GetBySessionKeyAsync(string sessionKey)
    {
        return await _context.QrSessions
            .FirstOrDefaultAsync(x => x.SessionKey == sessionKey);
    }

    public async Task CreateAsync(QrSession session)
    {
        _context.QrSessions.Add(session);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(QrSession session)
    {
        _context.QrSessions.Update(session);
        await _context.SaveChangesAsync();
    }

    public async Task CloseActiveSessionAsync(int tableId)
    {
        var session = await _context.QrSessions
            .FirstOrDefaultAsync(x => x.TableId == tableId && x.IsActive);

        if (session is null) return;

        session.IsActive = false;
        session.ExpiresAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
    public async Task<QrSession?> GetActiveByKeyAsync(string sessionKey)
    {
        return await _context.QrSessions
            .FirstOrDefaultAsync(s => s.SessionKey == sessionKey && s.IsActive);
    }
}