using TapTable.Api.Data.Entities;

namespace TapTable.Api.Repositories.Interfaces;

public interface ISplitPaymentPlanRepository
{
    Task<SplitPaymentPlan?> GetActiveByOrderIdAsync(int orderId);
    Task<SplitPaymentPlan?> GetByIdAsync(int id);
    Task<SplitPaymentPlan> CreateAsync(SplitPaymentPlan plan);
    Task<SplitPaymentPlan> UpdateAsync(SplitPaymentPlan plan);
}