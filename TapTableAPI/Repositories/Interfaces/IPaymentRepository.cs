using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetPaymentByIdAsync(int id);
    Task<Payment?> GetPaymentByStripeIntentIdAsync(string intentId);
    Task<List<Payment>> GetPaymentsByOrderAsync(int orderId);
    Task<Payment> CreatePaymentAsync(Payment payment);
    Task UpdatePaymentAsync(Payment payment);

    Task SaveChangesAsync();
}
