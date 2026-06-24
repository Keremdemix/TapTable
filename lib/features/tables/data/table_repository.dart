import '../../../core/network/api_client.dart';
import 'table_models.dart';

class TableRepository {
  final ApiClient _apiClient;
  TableRepository(this._apiClient);

  Future<List<TableResponseDto>> getTables() async {
    final list = await _apiClient.getList('/tables');
    return list.map((j) => TableResponseDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<TableResponseDto> createTable({required int tableNumber, required int capacity}) async {
    final json = await _apiClient.post('/tables', data: {
      'tableNumber': tableNumber,
      'capacity': capacity,
    });
    return TableResponseDto.fromJson(json);
  }

  Future<TableResponseDto> updateTable({
    required int id,
    required int tableNumber,
    required int capacity,
    required bool isActive,
  }) async {
    final json = await _apiClient.put('/tables/$id', data: {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'isActive': isActive,
      'qrCodeUrl': null, // null → mevcut URL korunur
    });
    return TableResponseDto.fromJson(json);
  }

  Future<void> deleteTable(int id) => _apiClient.delete('/tables/$id');

  Future<RegenerateQrResponseDto> regenerateQr(int id) async {
    final json = await _apiClient.post('/tables/$id/regenerate-qr');
    return RegenerateQrResponseDto.fromJson(json);
  }
}