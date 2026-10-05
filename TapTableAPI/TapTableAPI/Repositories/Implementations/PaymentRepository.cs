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

    public async Task<Payment?> GetByIdAsync(int id, int restaurantId)
    {
        return await _context.Payments
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.Id == id && p.Order.Table.RestaurantId == restaurantId);
    }

    public async Task<IEnumerable<Payment>> GetByOrderIdAsync(int orderId, int restaurantId)
    {
        return await _context.Payments
            .Where(p => p.OrderId == orderId && p.Order.Table.RestaurantId == restaurantId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();
    }

    public async Task<decimal> GetSucceededTotalAsync(int orderId)
    {
        return await _context.Payments
            .Where(p => p.OrderId == orderId && p.Status == PaymentStatus.Succeeded)
            .SumAsync(p => p.Amount);
    }

    public async Task<Payment> CreateAsync(Payment payment)
    {
        _context.Payments.Add(payment);
        await _context.SaveChangesAsync();
        return payment;
    }

    public async Task<Payment> UpdateAsync(Payment payment)
    {
        _context.Payments.Update(payment);
        await _context.SaveChangesAsync();
        return payment;
    }
    public async Task<Payment?> GetByIyzicoTokenAsync(string token)
    {
        return await _context.Payments.FirstOrDefaultAsync(p => p.IyzicoPaymentId == token);
    }
    public async Task<Payment?> GetByIdWithDetailsAsync(int paymentId)
    {
        return await _context.Payments
            .Include(p => p.PaymentItems)
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.Id == paymentId);
    }
}