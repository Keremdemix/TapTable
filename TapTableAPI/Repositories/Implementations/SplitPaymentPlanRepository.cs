using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class SplitPaymentPlanRepository : ISplitPaymentPlanRepository
{
    private readonly TapTableDbContext _context;

    public SplitPaymentPlanRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<SplitPaymentPlan?> GetActiveByOrderIdAsync(int orderId)
    {
        return await _context.SplitPaymentPlans
            .FirstOrDefaultAsync(p => p.OrderId == orderId && p.Status == SplitPlanStatus.Active);
    }

    public async Task<SplitPaymentPlan?> GetByIdAsync(int id)
    {
        return await _context.SplitPaymentPlans
            .Include(p => p.Order).ThenInclude(o => o.Table)
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<SplitPaymentPlan> CreateAsync(SplitPaymentPlan plan)
    {
        _context.SplitPaymentPlans.Add(plan);
        await _context.SaveChangesAsync();
        return plan;
    }

    public async Task<SplitPaymentPlan> UpdateAsync(SplitPaymentPlan plan)
    {
        plan.UpdatedAt = DateTime.UtcNow;
        _context.SplitPaymentPlans.Update(plan);
        await _context.SaveChangesAsync();
        return plan;
    }
}