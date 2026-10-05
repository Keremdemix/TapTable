namespace TapTable.Api.DTOs.Request.Table;

public class CreateTableRequestDto
{
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
}

public class SetQrUrlRequestDto
{
    public string Url { get; set; } = null!;
}

public class UpdateTableRequestDto
{
    public int TableNumber { get; set; }
    public int Capacity { get; set; }
    public bool IsActive { get; set; }

    /// <summary>
    /// Admin URL değiştirmek isterse doldurur.
    /// null gelirse mevcut URL korunur.
    /// boş string ("") gelirse URL silinir.
    /// </summary>
    public string? QrCodeUrl { get; set; }
}