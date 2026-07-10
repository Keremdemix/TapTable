import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_provider.dart';

/// iyzico ödeme sayfası yeni sekmede açıldıktan sonra bu ekranda kalınır.
/// paymentStateProvider zaten 5 sn'de bir güncelleniyor — ödeme başarılı
/// olduğunda (backend callback'i işledikten sonra) burası otomatik yansır.
class CheckoutPendingScreen extends ConsumerWidget {
  final Color primary;
  final Color accent;

  const CheckoutPendingScreen({
    super.key,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(paymentStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Bekleniyor')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Durum kontrol edilemedi.')),
        data: (state) {
          if (state == null) {
            return const Center(child: Text('Durum kontrol edilemedi.'));
          }

          if (state.isFullyPaid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            });

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: accent, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Ödemeniz alındı, teşekkürler!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primary),
                const SizedBox(height: 20),
                const Text(
                  'Yeni sekmede açılan ödeme sayfasını tamamlayın.\nBu ekran işlemi otomatik algılayacak.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kalan Tutar: ₺${state.remainingAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Geri Dön'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
