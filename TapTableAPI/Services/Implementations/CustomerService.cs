using TapTable.Api.DTOs.Response.Customer;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class CustomerService : ICustomerService
{
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;

    public CustomerService(
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository)
    {
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
    }

    public async Task<CustomerSessionResponseDto> StartSessionAsync(int tableId)
    {
        var table = await _tableRepository.GetByIdAsync(tableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        if (!table.IsActive)
            throw new InvalidOperationException("Bu masa şu an aktif değil.");

        var session = await _qrSessionRepository.GetActiveByTableIdAsync(tableId);

        // Normalde her masanın aktif bir session'ı olmalı (masa oluşturulurken / sipariş
        // kapanırken otomatik açılıyor). Yoksa kendiliğinden bir yenisini açıyoruz —
        // müşteri bu yüzden hata almasın.
        session ??= await _qrSessionRepository.RotateSessionAsync(tableId, table.RestaurantId);

        return new CustomerSessionResponseDto
        {
            TableId = table.Id,
            TableNumber = table.TableNumber,
            RestaurantId = table.RestaurantId,
            RestaurantName = table.Restaurant?.Name ?? string.Empty,
            SessionKey = session.SessionKey,
            TableStatus = table.Status.ToString()
        };
    }
}