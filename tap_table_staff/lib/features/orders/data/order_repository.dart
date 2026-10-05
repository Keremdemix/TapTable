import '../../../core/network/api_client.dart';
import 'order_models.dart';

class OrderRepository {
  final ApiClient _apiClient;
  OrderRepository(this._apiClient);

  Future<List<OrderResponseDto>> getOrders({
    String? status,
    int? tableId,
  }) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (tableId != null) query['tableId'] = tableId;

    final list = await _apiClient.getList(
      '/orders',
      query: query.isEmpty ? null : query,
    );
    return list
        .map((json) => OrderResponseDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrderResponseDto> updateItemStatus({
    required int orderId,
    required int itemId,
    required OrderItemStatus status,
  }) async {
    final json = await _apiClient.patch(
      '/orders/$orderId/items/$itemId/status',
      data: {'status': _statusName(status)},
    );
    return OrderResponseDto.fromJson(json);
  }

  String _statusName(OrderItemStatus status) => switch (status) {
    OrderItemStatus.pending => 'Pending',
    OrderItemStatus.preparing => 'Preparing',
    OrderItemStatus.ready => 'Ready',
    OrderItemStatus.served => 'Served',
    OrderItemStatus.cancelled => 'Cancelled',
  };

  Future<OrderResponseDto> createOrderByStaff({
    required int tableId,
    required List<OrderItemInput> items,
    String? note,
  }) async {
    final json = await _apiClient.post(
      '/orders',
      data: {
        'tableId': tableId,
        'items': items.map((i) => i.toJson()).toList(),
        'note': note,
      },
    );
    return OrderResponseDto.fromJson(json);
  }

  Future<OrderResponseDto> serveReadyItems(int tableId) async {
    final json = await _apiClient.patch(
      '/orders/tables/$tableId/serve-ready-items',
    );
    return OrderResponseDto.fromJson(json);
  }
}
