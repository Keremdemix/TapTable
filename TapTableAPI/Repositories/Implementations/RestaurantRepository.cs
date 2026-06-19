using Microsoft.EntityFrameworkCore;
using TapTable.Api.Data;
using TapTable.Api.Data.Entities;
using TapTable.Api.Repositories.Interfaces;

namespace TapTable.Api.Repositories.Implementations;

public class RestaurantRepository : IRestaurantRepository
{
    private readonly TapTableDbContext _context;

    public RestaurantRepository(TapTableDbContext context)
    {
        _context = context;
    }

    public async Task<Restaurant?> GetByIdAsync(int id)
    {
        return await _context.Restaurants.FirstOrDefaultAsync(r => r.Id == id);
    }

    public async Task<Restaurant?> GetByStripeAccountIdAsync(string stripeAccountId)
    {
        return await _context.Restaurants.FirstOrDefaultAsync(r => r.StripeAccountId == stripeAccountId);
    }

    public async Task<Restaurant> UpdateAsync(Restaurant restaurant)
    {
        _context.Restaurants.Update(restaurant);
        await _context.SaveChangesAsync();
        return restaurant;
    }
}