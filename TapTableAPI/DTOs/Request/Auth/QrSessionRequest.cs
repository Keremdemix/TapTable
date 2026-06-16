using System.ComponentModel.DataAnnotations;

namespace TapTable.Api.DTOs.Request.Customer;

/// <summary>
/// Müşteri QR kodu okutunca URL'den gelen parametre.
/// Herhangi bir kimlik doğrulama gerekmez.
/// Örnek QR URL: https://taptable.app/menu?tableId=5
/// </summary>
public class QrSessionRequest
{
    [Required]
    public int TableId { get; set; }
}