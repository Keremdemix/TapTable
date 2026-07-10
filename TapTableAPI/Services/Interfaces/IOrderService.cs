using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Order;
using TapTable.Api.DTOs.Response.Order;

namespace TapTable.Api.Services.Interfaces;

public interface IOrderService
{
    // Müşteri — Public (QR session)
    Task<OrderResponseDto> PlaceOrderAsync(string token, PlaceOrderRequestDto request);
    Task<OrderResponseDto?> GetActiveOrderAsync(string token);
    Task<OrderResponseDto> TrackOrderAsync(string token, int orderId);

    // Personel — Waiter/Kitchen/Admin
    Task<OrderResponseDto> CreateOrderByStaffAsync(int restaurantId, int? waiterId, StaffCreateOrderRequestDto request);
    Task<IEnumerable<OrderResponseDto>> GetOrdersAsync(int restaurantId, OrderStatus? status, int? tableId);
    Task<OrderResponseDto> GetOrderAsync(int orderId, int restaurantId);
    Task<OrderResponseDto> UpdateOrderItemStatusAsync(int orderId, int itemId, int restaurantId, OrderItemStatus status);
    Task<OrderResponseDto> UpdateOrderStatusAsync(int orderId, int restaurantId, OrderStatus status);
}