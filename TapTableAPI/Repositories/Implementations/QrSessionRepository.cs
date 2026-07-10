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
        if (string.IsNullOrWhiteSpace(sessionKey))
            return null;

        return await _context.QrSessions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SessionKey == sessionKey && s.IsActive);
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
    public async Task<QrSession> RotateSessionAsync(int tableId, int restaurantId)
    {
        var activeSessions = await _context.QrSessions
            .Where(s => s.TableId == tableId && s.IsActive)
            .ToListAsync();

        foreach (var s in activeSessions)
            s.IsActive = false;

        var newSession = new QrSession
        {
            TableId = tableId,
            RestaurantId = restaurantId,
            SessionKey = Guid.NewGuid().ToString("N"),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.QrSessions.Add(newSession);
        await _context.SaveChangesAsync();
        return newSession;
    }
    public async Task<QrSession?> GetByKeyIncludingInactiveAsync(string sessionKey)
    {
        return await _context.QrSessions
            .FirstOrDefaultAsync(s => s.SessionKey == sessionKey);
    }
}