using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class PaymentRepository : IPaymentRepository
{
    private readonly TapTableDbContext _context;

    public PaymentRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<Payment?> GetPaymentByIdAsync(int id)
    {
        return await _context.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<Payment?> GetPaymentByStripeIntentIdAsync(string intentId)
    {
        return await _context.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.StripePaymentIntentId == intentId);
    }

    public async Task<List<Payment>> GetPaymentsByOrderAsync(int orderId)
    {
        return await _context.Payments
            .Where(p => p.OrderId == orderId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();
    }

    public async Task<Payment> CreatePaymentAsync(Payment payment)
    {
        payment.CreatedAt = DateTime.UtcNow;
        _context.Payments.Add(payment);
        return payment;
    }

    public async Task UpdatePaymentAsync(Payment payment)
    {
        _context.Payments.Update(payment);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
