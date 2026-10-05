using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Response.Customer;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CustomerService : ICustomerService
{
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;
    private readonly IRestaurantRepository _restaurantRepository;

    public CustomerService(
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IRestaurantRepository restaurantRepository)
    {
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _restaurantRepository = restaurantRepository;
    }

    /// <summary>
    /// QR'daki token artık masaya SABİT bağlı bir QrToken — SessionKey değil.
    /// Bu sayede ödeme sonrası SessionKey rotate olsa bile fiziksel QR
    /// kod hiç değişmeden çalışmaya devam eder: masa bulunur, o masanın
    /// güncel aktif session'ı varsa kullanılır, yoksa yeni bir tane
    /// (find-or-create) oluşturulur.
    /// </summary>
    public async Task<CustomerSessionResponseDto> ResolveSessionAsync(string qrToken)
    {
        if (string.IsNullOrWhiteSpace(qrToken))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var table = await _tableRepository.GetByQrTokenAsync(qrToken)
            ?? throw new UnauthorizedAccessException("Geçersiz QR kod.");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        var session = await _qrSessionRepository.GetActiveByTableIdAsync(table.Id);

        if (session is null)
        {
            session = new QrSession
            {
                TableId = table.Id,
                RestaurantId = table.RestaurantId,
                SessionKey = Guid.NewGuid().ToString("N"),
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };
            await _qrSessionRepository.CreateAsync(session);
        }

        var restaurant = await _restaurantRepository.GetByIdAsync(table.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        return new CustomerSessionResponseDto
        {
            RestaurantId = restaurant.Id,
            TableId = table.Id,
            TableNumber = table.TableNumber,
            RestaurantName = restaurant.Name,
            LogoUrl = restaurant.LogoUrl,
            PrimaryColorHex = restaurant.PrimaryColorHex,
            AccentColorHex = restaurant.AccentColorHex,
            SessionKey = session.SessionKey
        };
    }
}