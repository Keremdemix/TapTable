import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'order_models.dart';

final activeOrderProvider =
    StreamProvider.autoDispose<OrderResponse?>((ref) async* {
  final tableId = ref.watch(tableIdProvider);
  final storage = ref.read(sessionStorageProvider);
  final apiClient = ref.read(apiClientProvider);

  if (tableId == null) {
    yield null;
    return;
  }

  while (true) {
    final sessionKey = await storage.getSessionKey();
    if (sessionKey == null) {
      yield null;
    } else {
      try {
        final json = await apiClient.get(
          '/public/orders/$tableId/active',
          query: {'sessionKey': sessionKey},
        );
        yield OrderResponse.fromJson(json);
      } catch (_) {
        // Aktif sipariş yoksa backend muhtemelen 404 dönüyor — banner'ı gizle
        yield null;
      }
    }
    await Future.delayed(const Duration(seconds: 8));
  }
});