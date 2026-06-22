using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using TapTable.Api.Configuration;
using TapTable.Api.Data;
using TapTable.Api.Repositories.Implementations;
// Bunlar class'ların varsa aç:
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Implementations;
using TapTable.Api.Services.Interfaces;
using TapTableAPI.Repositories.Interfaces;

var builder = WebApplication.CreateBuilder(args);

//
// ── Database ────────────────────────────────────────────────────────────────
//
builder.Services.AddDbContext<TapTableDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));

//
// ── JWT Settings Bind (Seçenek B) ───────────────────────────────────────────
//
builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("Jwt"));

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtSettings = jwtSection.Get<JwtSettings>()
    ?? throw new InvalidOperationException("Jwt configuration missing.");

//
// ── JWT Authentication ─────────────────────────────────────────────────────
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

        // SignalR token support
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

//
// ── CORS ────────────────────────────────────────────────────────────────────
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
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

//
// ── Controllers & OpenAPI ──────────────────────────────────────────────────
//
//builder.Services.AddControllers();
//builder.Services.AddOpenApi("v1");

//
// ── SignalR ────────────────────────────────────────────────────────────────
//
builder.Services.AddSignalR();

//
// ── Repositories ───────────────────────────────────────────────────────────
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
// ── Services ───────────────────────────────────────────────────────────────
//
builder.Services.AddScoped<ITableService, TableService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IQrSessionService, QrSessionService>();
builder.Services.AddScoped<IMenuService, MenuService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IStripeConnectService, StripeConnectService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
//
// ── Build ──────────────────────────────────────────────────────────────────
//
var app = builder.Build();

//
// ── Middleware Pipeline ────────────────────────────────────────────────────
//
if (app.Environment.IsDevelopment())
{
    //app.MapOpenApi();
    //app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutter");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// app.MapHub<OrderHub>("/hubs/orders");

app.Run();