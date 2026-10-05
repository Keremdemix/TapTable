import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_provider.dart';
import 'thank_you_screen.dart';

/// iyzico ödeme sayfası yeni sekmede açıldıktan sonra bu ekranda kalınır.
/// Üç durumu ayrı ayrı ele alır:
/// 1. Henüz hiçbir şey netleşmedi → bekleme ekranı
/// 2. Benim ödemem bitti ama hesabın tamamı bitmedi → "diğer ödemeler
///    bekleniyor" ekranı + geldiğim ödeme ekranına dönüş butonu
/// 3. Hesabın tamamı ödendi → ortak teşekkür ekranı (session kapandı)
class CheckoutPendingScreen extends ConsumerWidget {
  final Color primary;
  final Color accent;
  final int paymentId;

  const CheckoutPendingScreen({
    super.key,
    required this.primary,
    required this.accent,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallAsync = ref.watch(paymentStateProvider);
    final myPaymentAsync = ref.watch(myPaymentStatusProvider(paymentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: overallAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Durum kontrol edilemedi.')),
        data: (overall) {
          if (overall == null) {
            return const Center(child: Text('Durum kontrol edilemedi.'));
          }

          // ── Durum 3: Hesabın tamamı ödendi ──
          if (overall.isFullyPaid) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      ThankYouScreen(primary: primary, accent: accent),
                ),
                (route) => false,
              );
            });
            return Center(child: CircularProgressIndicator(color: accent));
          }

          return myPaymentAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: primary)),
            error: (_, __) =>
                Center(child: CircularProgressIndicator(color: primary)),
            data: (myPayment) {
              // ── Durum 2: Benim ödemem tamam, hesap hâlâ açık ──
              if (myPayment != null && myPayment.status == 'Succeeded') {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: accent, size: 72),
                      const SizedBox(height: 20),
                      const Text(
                        'Ödemeniz başarıyla alınmıştır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masadaki diğer ödemeler bekleniyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oturumunuz devam ediyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kalan Tutar: ₺${overall.remainingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Ödeme Ekranına Dön'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ── Durum 1: Bekleme ekranı ──
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
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
