using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using System.Text;
using TapTable.Api.Configuration;
using TapTable.Api.Data;

// Bunlar class'ların varsa aç:
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Repositories.Implementations;
using TapTable.Api.Services.Interfaces;
using TapTable.Api.Services.Implementations;

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
builder.Services.AddControllers();
builder.Services.AddOpenApi("v1");

//
// ── SignalR ────────────────────────────────────────────────────────────────
//
builder.Services.AddSignalR();

//
// ── Repositories ───────────────────────────────────────────────────────────
//
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IQrSessionRepository, QrSessionRepository>();

//
// ── Services ───────────────────────────────────────────────────────────────
//
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IQrSessionService, QrSessionService>();

//
// ── Build ──────────────────────────────────────────────────────────────────
//
var app = builder.Build();

//
// ── Middleware Pipeline ────────────────────────────────────────────────────
//
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutter");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// app.MapHub<OrderHub>("/hubs/orders");

app.Run();