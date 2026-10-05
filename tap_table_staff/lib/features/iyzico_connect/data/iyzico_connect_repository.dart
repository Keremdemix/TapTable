import '../../../core/network/api_client.dart';
import 'iyzico_connect_models.dart';

class IyzicoConnectRepository {
  final ApiClient _apiClient;
  IyzicoConnectRepository(this._apiClient);

  Future<IyzicoSubMerchantStatusDto> getStatus() async {
    final json = await _apiClient.get('/iyzico-connect/status');
    return IyzicoSubMerchantStatusDto.fromJson(json);
  }

  Future<void> register(RegisterSubMerchantRequestDto dto) async {
    await _apiClient.post('/iyzico-connect/register', data: dto.toJson());
  }
}