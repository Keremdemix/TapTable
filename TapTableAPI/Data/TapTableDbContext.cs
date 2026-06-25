using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Reflection.Emit;
using TapTable.Api.Data.Entities;

namespace TapTable.Api.Data;

public class TapTableDbContext : DbContext
{
    public TapTableDbContext(DbContextOptions<TapTableDbContext> options) : base(options) { }

    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<User> Users => Set<User>();
    public DbSet<RestaurantTable> RestaurantTables => Set<RestaurantTable>();
    public DbSet<TableLayout> TableLayouts => Set<TableLayout>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<MenuItem> MenuItems => Set<MenuItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<QrSession> QrSessions => Set<QrSession>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ── Role ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Role>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(50).IsRequired();
            e.HasIndex(x => x.Name).IsUnique();
        });

        // ── Restaurant ────────────────────────────────────────────────────────
        modelBuilder.Entity<Restaurant>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(150).IsRequired();
            e.Property(x => x.Address).HasMaxLength(300);
            e.Property(x => x.Phone).HasMaxLength(50);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");

        });

        // ── User ──────────────────────────────────────────────────────────────
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.FullName).HasMaxLength(150).IsRequired();
            e.Property(x => x.Email).HasMaxLength(150).IsRequired();
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.PasswordHash).HasMaxLength(500).IsRequired();
            e.Property(x => x.IsActive).HasDefaultValue(true);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
            e.Property(x => x.UpdatedAt).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Restaurant)
             .WithMany(r => r.Users)
             .HasForeignKey(x => x.RestaurantId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Role)
             .WithMany(r => r.Users)
             .HasForeignKey(x => x.RoleId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── RestaurantTable ───────────────────────────────────────────────────
        modelBuilder.Entity<RestaurantTable>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Capacity).HasDefaultValue(4);
            e.Property(x => x.QrCodeUrl).HasMaxLength(500);

            e.Property(x => x.Status)
             .HasConversion<string>()
             .HasMaxLength(50)
             .HasDefaultValue(TableStatus.Available);

            e.Property(x => x.IsActive).HasDefaultValue(true);

            // Aynı restoranda iki tane "Masa 5" olamaz — ama sadece aktif masalar arasında
            e.HasIndex(x => new { x.RestaurantId, x.TableNumber })
             .IsUnique()
             .HasFilter("[IsActive] = 1");

            e.HasOne(x => x.Restaurant)
             .WithMany(r => r.Tables)
             .HasForeignKey(x => x.RestaurantId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── TableLayout ───────────────────────────────────────────────────────
        modelBuilder.Entity<TableLayout>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Width).HasDefaultValue(100);
            e.Property(x => x.Height).HasDefaultValue(100);
            e.Property(x => x.Shape).HasMaxLength(20).HasDefaultValue("rectangle");

            // 1:1 — her masanın tek bir layout'u olabilir
            e.HasIndex(x => x.TableId).IsUnique();

            e.HasOne(x => x.Table)
             .WithOne(t => t.Layout)
             .HasForeignKey<TableLayout>(x => x.TableId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // ── Category ──────────────────────────────────────────────────────────
        modelBuilder.Entity<Category>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(100).IsRequired();
            e.Property(x => x.SortOrder).HasDefaultValue(0);
            e.Property(x => x.IsActive).HasDefaultValue(true);

            e.HasOne(x => x.Restaurant)
             .WithMany(r => r.Categories)
             .HasForeignKey(x => x.RestaurantId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── MenuItem ──────────────────────────────────────────────────────────
        modelBuilder.Entity<MenuItem>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).HasMaxLength(150).IsRequired();
            e.Property(x => x.Description).HasMaxLength(500);
            e.Property(x => x.IsActive).HasDefaultValue(true);
            e.Property(x => x.Price).HasColumnType("decimal(18,2)");
            e.Property(x => x.ImageUrl).HasMaxLength(500);
            e.Property(x => x.IsAvailable).HasDefaultValue(true);
            e.Property(x => x.SortOrder).HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
            e.Property(x => x.UpdatedAt).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Category)
             .WithMany(c => c.MenuItems)
             .HasForeignKey(x => x.CategoryId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Order ─────────────────────────────────────────────────────────────
        modelBuilder.Entity<Order>(e =>
        {
            e.HasKey(x => x.Id);

            e.Property(x => x.Status)
             .HasConversion<string>()
             .HasMaxLength(50)
             .HasDefaultValue(OrderStatus.Pending);

            e.Property(x => x.PaymentStatus)
             .HasConversion<string>()
             .HasMaxLength(50)
             .HasDefaultValue(OrderPaymentStatus.Unpaid);

            e.Property(x => x.TotalPrice).HasColumnType("decimal(18,2)").HasDefaultValue(0);
            e.Property(x => x.Note).HasMaxLength(500);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
            e.Property(x => x.UpdatedAt).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Table)
             .WithMany(t => t.Orders)
             .HasForeignKey(x => x.TableId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Waiter)
             .WithMany(u => u.Orders)
             .HasForeignKey(x => x.WaiterId)
             .IsRequired(false)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // ── OrderItem ─────────────────────────────────────────────────────────
        modelBuilder.Entity<OrderItem>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Quantity).IsRequired();
            e.Property(x => x.UnitPrice).HasColumnType("decimal(18,2)");
            e.Property(x => x.Note).HasMaxLength(300);

            e.Property(x => x.Status)
             .HasConversion<string>()
             .HasMaxLength(50)
             .HasDefaultValue(OrderItemStatus.Pending);

            e.HasOne(x => x.Order)
             .WithMany(o => o.Items)
             .HasForeignKey(x => x.OrderId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.MenuItem)
             .WithMany(m => m.OrderItems)
             .HasForeignKey(x => x.MenuItemId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── Payment ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Payment>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Amount).HasColumnType("decimal(18,2)");

            e.Property(x => x.Method)
             .HasConversion<string>()
             .HasMaxLength(30);

            e.Property(x => x.SplitType)
             .HasConversion<string>()
             .HasMaxLength(20)
             .HasDefaultValue(SplitType.Full);


            e.Property(x => x.Status)
             .HasConversion<string>()
             .HasMaxLength(50)
             .HasDefaultValue(PaymentStatus.Pending);

            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Order)
             .WithMany(o => o.Payments)
             .HasForeignKey(x => x.OrderId)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }
}