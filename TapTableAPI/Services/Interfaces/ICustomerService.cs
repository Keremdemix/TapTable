using TapTable.Api.DTOs.Response.Customer;

namespace TapTable.Api.Services.Interfaces;

public interface ICustomerService
{
    /// <summary>
    /// QR okutulduğunda çağrılır — masanın aktif sessionKey'ini döner.
    /// Aktif session yoksa kendiliğinden bir yenisi açılır (self-healing).
    /// </summary>
    Task<CustomerSessionResponseDto> ResolveSessionAsync(string token);
}