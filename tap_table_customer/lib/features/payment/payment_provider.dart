import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'payment_models.dart';

/// Masanın toplam ödeme durumu — kalan tutar, kalem/pay bazlı ilerleme.
/// 5 saniyede bir yenilenir. Ödemenin Succeeded olması tamamen iyzico'nun
/// callback'ine bağlıdır (bkz. PaymentService.HandleIyzicoCallbackAsync).
final paymentStateProvider = StreamProvider.autoDispose<OrderPaymentState?>((
  ref,
) async* {
  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(sessionStorageProvider);

  while (true) {
    try {
      final session = await ref.read(customerSessionProvider.future);
      final sessionKey = await storage.getToken();

      if (sessionKey == null) {
        yield null;
      } else {
        final json = await apiClient.getPaymentState(
          session.tableId,
          sessionKey,
        );
        yield OrderPaymentState.fromJson(json);
      }
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});

/// Tek bir ödemenin ("benim ödemem") durumu — paymentId'ye göre parametrik.
/// Kullanıcı kendi ödemesini yapıp yapmadığını, toplam hesaptan bağımsız
/// olarak takip edebilsin diye ayrı tutuluyor.
final myPaymentStatusProvider = StreamProvider.autoDispose
    .family<PaymentResult?, int>((ref, paymentId) async* {
      final apiClient = ref.read(apiClientProvider);
      final storage = ref.read(sessionStorageProvider);

      while (true) {
        try {
          final session = await ref.read(customerSessionProvider.future);
          final sessionKey = await storage.getToken();

          if (sessionKey == null) {
            yield null;
          } else {
            final json = await apiClient.getPaymentStatus(
              session.tableId,
              paymentId,
              sessionKey,
            );
            yield PaymentResult.fromJson(json);
          }
        } catch (_) {
          yield null;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
    });
