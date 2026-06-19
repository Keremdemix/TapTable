using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetByIdAsync(int id, int restaurantId);
    Task<Payment?> GetByStripeIntentIdAsync(string intentId);
    Task<IEnumerable<Payment>> GetByOrderIdAsync(int orderId, int restaurantId);
    Task<decimal> GetSucceededTotalAsync(int orderId);
    Task<Payment> CreateAsync(Payment payment);
    Task<Payment> UpdateAsync(Payment payment);
}