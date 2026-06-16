using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Payment;

public class CreatePaymentIntentRequest
{
    [Required]
    public int OrderId { get; set; }

    [Required]
    public string SplitType { get; set; } = "Full"; // Full | Equal | Custom

    // Equal split için kaç kişiye bölüneceği
    public int? SplitCount { get; set; }

    // Custom split için bu kişinin ödeyeceği tutar
    public decimal? CustomAmount { get; set; }
}
