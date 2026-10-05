using Microsoft.AspNetCore.Http;

namespace TapTable.Api.Services.Interfaces;

public interface IImageUploadService
{
    Task<string> UploadAsync(IFormFile file, string folder);
    Task DeleteAsync(string publicId);
    Task<bool> DeleteByUrlAsync(string url, int? restaurantId = null);
}