using Iyzipay;
using Iyzipay.Model;
using Iyzipay.Request;
using IyzicoOptions = Iyzipay.Options;
using TapTable.Api.DTOs.Request.IyzicoConnect;
using TapTable.Api.DTOs.Response.IyzicoConnect;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class IyzicoSubMerchantService : IIyzicoSubMerchantService
{
    private readonly IRestaurantRepository _restaurantRepository;
    private readonly IyzicoOptions _iyzicoOptions;

    public IyzicoSubMerchantService(
        IRestaurantRepository restaurantRepository,
        IConfiguration configuration)
    {
        _restaurantRepository = restaurantRepository;
        _iyzicoOptions = new IyzicoOptions
        {
            ApiKey = configuration["Iyzico:ApiKey"]!,
            SecretKey = configuration["Iyzico:SecretKey"]!,
            BaseUrl = configuration["Iyzico:BaseUrl"]!
        };
    }

    public async Task<IyzicoSubMerchantStatusResponseDto> GetStatusAsync(int restaurantId)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        return new IyzicoSubMerchantStatusResponseDto
        {
            HasSubMerchant = !string.IsNullOrEmpty(restaurant.IyzicoSubMerchantKey),
            IsApproved = restaurant.IyzicoSubMerchantApproved,
            SubMerchantKey = restaurant.IyzicoSubMerchantKey
        };
    }

    public async Task<IyzicoSubMerchantStatusResponseDto> RegisterAsync(
        int restaurantId,
        RegisterSubMerchantRequestDto dto)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        var request = new CreateSubMerchantRequest
        {
            Locale = Locale.TR.ToString(),
            ConversationId = $"restaurant_{restaurantId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
            SubMerchantExternalId = $"restaurant_{restaurantId}",
            SubMerchantType = SubMerchantType.LIMITED_OR_JOINT_STOCK_COMPANY.ToString(),
            Address = dto.Address,
            TaxOffice = dto.TaxOffice,
            TaxNumber = dto.TaxNumber,
            LegalCompanyTitle = dto.LegalCompanyTitle,
            Email = dto.Email,
            GsmNumber = dto.GsmNumber,
            Name = dto.LegalCompanyTitle,
            Iban = dto.Iban,
            Currency = Currency.TRY.ToString(),
            ContactName = dto.ContactName,
            ContactSurname = dto.ContactSurname,
        };

        var result = await Task.Run(() => SubMerchant.Create(request, _iyzicoOptions));

        if (result.Status != "success")
            throw new InvalidOperationException($"iyzico hatası: {result.ErrorMessage}");

        restaurant.IyzicoSubMerchantKey = result.SubMerchantKey;
        restaurant.IyzicoSubMerchantApproved = true;
        await _restaurantRepository.UpdateAsync(restaurant);

        return new IyzicoSubMerchantStatusResponseDto
        {
            HasSubMerchant = true,
            IsApproved = true,
            SubMerchantKey = result.SubMerchantKey
        };
    }
}