import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'payment_models.dart';

/// Ödeme ekranının tüm state'i — kalan tutar, kalem bazlı ödenmemiş
/// adetler, varsa aktif bölüşüm planı. activeOrderProvider ile aynı
/// pattern: 5 saniyede bir yenilenir, "Seçerek/Bölerek Öde" gibi henüz
/// staff onayı bekleyen Pending ödemelerin durumunu da bu sayede yakalar.
final paymentStateProvider = StreamProvider.autoDispose<OrderPaymentState?>((
  ref,
) async* {
  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(sessionStorageProvider);
  final session = await ref.watch(customerSessionProvider.future);
  final sessionKey = await storage.getToken();

  if (sessionKey == null) {
    yield null;
    return;
  }

  while (true) {
    try {
      final json = await apiClient.getPaymentState(session.tableId, sessionKey);
      yield OrderPaymentState.fromJson(json);
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});
