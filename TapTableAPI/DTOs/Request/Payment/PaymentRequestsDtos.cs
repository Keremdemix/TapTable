using TapTable.Api.Data.Entities;

namespace TapTable.Api.DTOs.Request.Payment;

// Garson — POS'tan kart ya da nakit aldıktan sonra sisteme işler
public class RecordManualPaymentRequestDto
{
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; } // Cash veya Card
}

/*
public class CreatePaymentIntentRequestDto
{
    public string SessionKey { get; set; } = null!;
}*/