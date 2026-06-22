namespace TapTable.Api.DTOs.Response.Customer;

public class CustomerSessionResponseDto
{
    public int TableId { get; set; }
    public int TableNumber { get; set; }
    public int RestaurantId { get; set; }
    public string RestaurantName { get; set; } = null!;
    public string SessionKey { get; set; } = null!;
    public string TableStatus { get; set; } = null!;
}