namespace TapTable.Api.Data.Entities;

public class Role
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;

    // Navigation
    public ICollection<User> Users { get; set; } = new List<User>();
}