using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class AuthRepository : IAuthRepository
{
    private readonly TapTableDbContext _context;

    public AuthRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetUserByEmailAsync(string email)
    {
        return await _context.Users
            .Include(u => u.Role)
            .Include(u => u.Restaurant)
            .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);
    }

    public async Task<User?> GetUserByIdAsync(int id)
    {
        return await _context.Users
            .Include(u => u.Role)
            .Include(u => u.Restaurant)
            .FirstOrDefaultAsync(u => u.Id == id && u.IsActive);
    }
}
