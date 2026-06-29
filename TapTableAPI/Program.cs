using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using TapTable.Api.Configuration;
using TapTable.Api.Data;
using TapTable.Api.Repositories.Implementations;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Implementations;
using TapTable.Api.Services.Interfaces;
using TapTableAPI.Repositories.Interfaces;
using System.Text.Json.Serialization;
// ⚠️ Aşağıdaki satırı SİLİN ve IAuthRepository.cs dosyasının namespace'ini
// "TapTable.Api.Repositories.Interfaces" olacak şekilde düzeltin.
// using TapTableAPI.Repositories.Interfaces;

var builder = WebApplication.CreateBuilder(args);

//
// ── Database ────────────────────────────────────────────────────────────────
//
builder.Services.AddDbContext<TapTableDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));

//
// ── JWT Settings Bind ────────────────────────────────────────────────────────
//
builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("Jwt"));

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtSettings = jwtSection.Get<JwtSettings>()
    ?? throw new InvalidOperationException("Jwt configuration missing.");

//
// ── JWT Authentication ───────────────────────────────────────────────────────
//
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = jwtSettings.Issuer,
            ValidAudience = jwtSettings.Audience,

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSettings.SecretKey)
            ),

            ClockSkew = TimeSpan.Zero
        };

        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken)
                    && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
Console.WriteLine("JWT SECRET => " + builder.Configuration["Jwt:SecretKey"]);
//
// ── CORS ──────────────────────────────────────────────────────────────────────
//
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:3000",
                "http://localhost:5000"
            )
            .AllowAnyOrigin()   // DEV — Flutter web her seferinde farklı port seçiyor
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

//
// ── Controllers & OpenAPI ──────────────────────────────────────────────────────
//
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();             // Flutter olmadan Postman/Swagger ile test edebilmek için

//
// ── SignalR ──────────────────────────────────────────────────────────────────
//
builder.Services.AddSignalR();

//
// ── Repositories ───────────────────────────────────────────────────────────────
//
builder.Services.AddScoped<ITableRepository, TableRepository>();
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IQrSessionRepository, QrSessionRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IMenuItemRepository, MenuItemRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<IRestaurantRepository, RestaurantRepository>();

//
// ── Services ───────────────────────────────────────────────────────────────────
//
builder.Services.AddScoped<ITableService, TableService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IQrSessionService, QrSessionService>();
builder.Services.AddScoped<IMenuService, MenuService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IIyzicoSubMerchantService, IyzicoSubMerchantService>();
//
// ── Build ────────────────────────────────────────────────────────────────────────
//
var app = builder.Build();

//
// ── Middleware Pipeline ──────────────────────────────────────────────────────────
//
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutter");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();   // ✅ GERİ AÇILDI — bu olmadan controller'lar route'lanmaz

// app.MapHub<OrderHub>("/hubs/orders"); // OrderHub henüz yazılmadı, yorumda kalsın

app.Run();