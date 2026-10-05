namespace TapTable.Api.DTOs.Request.Payment;

public class CreateSplitPlanRequestDto
{
    public string SessionKey { get; set; } = null!;
    public int TotalPeople { get; set; }
}

public class PaySplitShareRequestDto
{
    public string SessionKey { get; set; } = null!;
    public int Shares { get; set; } = 1;
}

public class CancelSplitPlanRequestDto
{
    public string SessionKey { get; set; } = null!;
}

public class PaySelectedItemsRequestDto
{
    public string SessionKey { get; set; } = null!;
    public List<PaySelectedItemLineDto> Items { get; set; } = new();
}

public class PaySelectedItemLineDto
{
    public int OrderItemId { get; set; }
    public int Quantity { get; set; }
}