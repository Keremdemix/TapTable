using Iyzipay.Model;
using Iyzipay.Request;
using TapTable.Api.DTOs.Request.IyzicoConnect;
using TapTable.Api.DTOs.Response.IyzicoConnect;
using TapTable.Api.Helpers;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;

namespace TapTable.Api.Services.Implementations;

public class IyzicoSubMerchantService : IIyzicoSubMerchantService
{
    private readonly IRestaurantRepository _restaurantRepository;
    private readonly IConfiguration _configuration;

    public IyzicoSubMerchantService(IRestaurantRepository restaurantRepository, IConfiguration configuration)
    {
        _restaurantRepository = restaurantRepository;
        _configuration = configuration;
    }

    public async Task<IyzicoSubMerchantStatusDto> GetStatusAsync(int restaurantId)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        return new IyzicoSubMerchantStatusDto
        {
            HasSubMerchant = !string.IsNullOrEmpty(restaurant.IyzicoSubMerchantKey),
            IsApproved = restaurant.IsIyzicoApproved
        };
    }

    public async Task<IyzicoSubMerchantStatusDto> RegisterAsync(int restaurantId, RegisterSubMerchantRequestDto dto)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(restaurantId)
            ?? throw new KeyNotFoundException($"Restoran bulunamadı: {restaurantId}");

        var options = IyzicoOptionsFactory.Build(_configuration);
        var hasExisting = !string.IsNullOrEmpty(restaurant.IyzicoSubMerchantKey);

        if (hasExisting)
        {
            var updateRequest = new UpdateSubMerchantRequest
            {
                Locale = Locale.TR.ToString(),
                ConversationId = Guid.NewGuid().ToString(),
                SubMerchantKey = restaurant.IyzicoSubMerchantKey,
                Name = dto.LegalCompanyTitle,
                Email = dto.Email,
                GsmNumber = dto.GsmNumber,
                Address = dto.Address,
                Iban = dto.Iban,
                ContactName = dto.ContactName,
                ContactSurname = dto.ContactSurname,
                TaxOffice = dto.TaxOffice,
                Currency = Currency.TRY.ToString()
            };

            // ⚠️ Update metodu SubMerchant model sınıfında, request sınıfında değil
            var updated = await SubMerchant.Update(updateRequest, options);
            if (updated.Status != "success")
                throw new InvalidOperationException($"iyzico güncelleme hatası: {updated.ErrorMessage}");
        }
        else
        {
            var externalId = $"restaurant-{restaurant.Id}";

            var createRequest = new CreateSubMerchantRequest
            {
                Locale = Locale.TR.ToString(),
                ConversationId = Guid.NewGuid().ToString(),
                SubMerchantExternalId = externalId,
                SubMerchantType = "LIMITED_OR_JOINT_STOCK_COMPANY",
                Name = dto.LegalCompanyTitle,
                Email = dto.Email,
                GsmNumber = dto.GsmNumber,
                Address = dto.Address,
                Iban = dto.Iban,
                ContactName = dto.ContactName,
                ContactSurname = dto.ContactSurname,
                LegalCompanyTitle = dto.LegalCompanyTitle,
                TaxOffice = dto.TaxOffice,
                TaxNumber = dto.TaxNumber,
                Currency = Currency.TRY.ToString()
            };

            var created = await SubMerchant.Create(createRequest, options);
            if (created.Status != "success")
                throw new InvalidOperationException($"iyzico kayıt hatası: {created.ErrorMessage}");

            restaurant.IyzicoSubMerchantKey = created.SubMerchantKey;
            restaurant.IyzicoSubMerchantExternalId = externalId;
        }

        restaurant.IsIyzicoApproved = true;
        await _restaurantRepository.UpdateAsync(restaurant);

        return new IyzicoSubMerchantStatusDto { HasSubMerchant = true, IsApproved = true };
    }
}