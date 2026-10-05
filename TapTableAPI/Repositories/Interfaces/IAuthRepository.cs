using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IAuthRepository
{
    Task<User?> GetUserByEmailAsync(string email);

    Task<User?> GetUserByIdAsync(int id);

    Task<User?> GetUserByRefreshTokenAsync(string refreshToken);

    Task UpdateUserAsync(User user);
}