namespace TapTable.Api.Data.Entities;

public class Restaurant
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public DateTime CreatedAt { get; set; }

    // ── iyzico Pazaryeri (Marketplace) ──────────────────────────────────
    public string? IyzicoSubMerchantKey { get; set; }         // iyzico'dan dönen, ödeme bölüştürmede kullanılan anahtar
    public string? IyzicoSubMerchantExternalId { get; set; }  // bizim ürettiğimiz, sorgu/güncelleme için kullanılan dış ID
    public bool IsIyzicoApproved { get; set; }

    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<RestaurantTable> Tables { get; set; } = new List<RestaurantTable>();
    public ICollection<Category> Categories { get; set; } = new List<Category>();
}