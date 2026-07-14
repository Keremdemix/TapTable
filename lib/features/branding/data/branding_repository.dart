import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import 'branding_models.dart';

class BrandingRepository {
  final ApiClient _apiClient;
  BrandingRepository(this._apiClient);

  Future<RestaurantBrandingDto> getBranding(int restaurantId) async {
    final json = await _apiClient.get('/restaurants/$restaurantId/branding');
    return RestaurantBrandingDto.fromJson(json);
  }

  Future<void> updateBranding({
    required int restaurantId,
    required String primaryColorHex,
    required String accentColorHex,
    Uint8List? logoBytes,
    String? logoFileName,
    bool removeLogo = false,
  }) {
    return _apiClient.updateRestaurantBranding(
      restaurantId: restaurantId,
      primaryColorHex: primaryColorHex,
      accentColorHex: accentColorHex,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      removeLogo: removeLogo,
    );
  }
}