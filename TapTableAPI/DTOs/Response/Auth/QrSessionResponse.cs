using TapTableAPI.DTOs.Response.Menu;

namespace TapTable.Api.DTOs.Response.Customer;

/// <summary>
/// QR okutulunca dönen response.
/// Müşteriye token verilmez — menü ve masa bilgisi direkt gelir.
/// </summary>
public class QrSessionResponse
{
    public TableInfo Table { get; set; } = null!;
    public RestaurantInfo Restaurant { get; set; } = null!;
    public List<CategoryResponse> Menu { get; set; } = new();
}

public class TableInfo
{
    public int Id { get; set; }
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
}

public class RestaurantInfo
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
}