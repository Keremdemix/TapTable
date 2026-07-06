import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'order_models.dart';

final activeOrderProvider =
    StreamProvider.autoDispose<OrderResponse?>((ref) async* {
  final apiClient = ref.read(apiClientProvider);

  while (true) {
    try {
      final json = await apiClient.get('/public/orders/active');
      yield OrderResponse.fromJson(json);
    } catch (_) {
      // Aktif sipariş yoksa backend 404/401 dönebilir — banner'ı gizle
      yield null;
    }
    await Future.delayed(const Duration(seconds: 8));
  }
});