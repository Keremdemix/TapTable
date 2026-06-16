using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Table;

public class CreateTableRequest
{
    [Required]
    [Range(1, 9999)]
    public int TableNumber { get; set; }

    [Required]
    [Range(1, 20)]
    public int Capacity { get; set; }

    public TableLayoutRequest? Layout { get; set; }
}

public class UpdateTableLayoutRequest
{
    [Required]
    public List<TableLayoutRequest> Layouts { get; set; } = new();
}

public class TableLayoutRequest
{
    public int TableId { get; set; }
    public int PositionX { get; set; }
    public int PositionY { get; set; }
    public int Width { get; set; } = 100;
    public int Height { get; set; } = 100;
    public string Shape { get; set; } = "rectangle"; // rectangle | circle
}
