using TapTable.Api.DTOs.Request.Table;
using TapTable.Api.DTOs.Response.Table;

namespace TapTable.Api.Services.Interfaces;

public interface ITableService
{
    Task<TableResponseDto> GetTableAsync(int tableId, int restaurantId);
    Task<IEnumerable<TableResponseDto>> GetTablesAsync(int restaurantId);

    /// <summary>
    /// Masa oluştur → kalıcı QR URL üret → ilk QrSession'ı otomatik aç
    /// </summary>
    Task<TableResponseDto> CreateTableAsync(int restaurantId, CreateTableRequestDto request);

    Task<TableResponseDto> UpdateTableAsync(int tableId, int restaurantId, UpdateTableRequestDto request);
    Task DeleteTableAsync(int tableId, int restaurantId);

    /// <summary>
    /// Admin QR URL'i manuel olarak değiştirir
    /// </summary>
    Task<TableResponseDto> SetQrUrlAsync(int tableId, int restaurantId, string newUrl);

    /// <summary>
    /// Admin QR URL'i siler — masa URL'siz kalır
    /// </summary>
    Task<TableResponseDto> DeleteQrUrlAsync(int tableId, int restaurantId);

    /// <summary>
    /// Admin yeni fiziksel QR basmak istediğinde:
    /// mevcut session'ı kapat → yeni session aç → aynı QR URL'i döndür
    /// </summary>
    Task<RegenerateQrResponseDto> RegenerateQrAsync(int tableId, int restaurantId);
}