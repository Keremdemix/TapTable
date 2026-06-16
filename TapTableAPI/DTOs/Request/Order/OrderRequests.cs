using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Order;

public class CreateOrderRequest
{
    [Required]
    public int TableId { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }

    [Required]
    [MinLength(1, ErrorMessage = "En az bir ürün seçilmelidir.")]
    public List<OrderItemRequest> Items { get; set; } = new();
}

public class OrderItemRequest
{
    [Required]
    public int MenuItemId { get; set; }

    [Required]
    [Range(1, 99)]
    public int Quantity { get; set; }

    [MaxLength(300)]
    public string? Note { get; set; }   // "az tuzlu", "domatessiz"
}

public class UpdateOrderStatusRequest
{
    [Required]
    public string Status { get; set; } = null!;
    // Pending | Preparing | Ready | Delivered | Cancelled
}

public class AddOrderItemRequest
{
    [Required]
    public int MenuItemId { get; set; }

    [Required]
    [Range(1, 99)]
    public int Quantity { get; set; }

    [MaxLength(300)]
    public string? Note { get; set; }
}
