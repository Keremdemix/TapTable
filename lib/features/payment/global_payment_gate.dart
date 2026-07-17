import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/core/theme/restaurant_theme_provider.dart';
import '../../main.dart';
import 'payment_provider.dart';
import 'thank_you_screen.dart';

/// Uygulamanın her ekranını saran global bir dinleyici. Hesabın tam olarak
/// ödendiği AN'ı (geçiş) yakalar — "ödenmemişti, şimdi ödendi" farkına
/// bakar. Sadece anlık duruma bakmak, taze bir QR taramasında geçmişteki
/// eski/ödenmiş bir siparişin yanlışlıkla yakalanması gibi durumlarda
/// yanlış pozitife yol açabildiği için transition-based yaklaşım tercih
/// edildi (bkz. GetOrderPaymentStateAsync'teki 5 dk'lık pencere ile
/// birlikte çift katmanlı koruma).
class GlobalPaymentGate extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalPaymentGate({super.key, required this.child});

  @override
  ConsumerState<GlobalPaymentGate> createState() => _GlobalPaymentGateState();
}

class _GlobalPaymentGateState extends ConsumerState<GlobalPaymentGate> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(paymentStateProvider, (previous, next) {
      final prevState = previous?.value;
      final nextState = next.value;

      if (nextState == null || _navigated) return;

      // Sadece "az önce tamamen ödendi" geçişinde tetiklen — uygulama ilk
      // açıldığında (previous == null) veya zaten ödenmiş bir durumla
      // başladığında değil.
      final justCompleted =
          prevState != null && !prevState.isFullyPaid && nextState.isFullyPaid;

      if (justCompleted) {
        _navigated = true;
        _goToThankYou();
      }
    });

    return widget.child;
  }

  Future<void> _goToThankYou() async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    await nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ThankYouScreen(
          primary: ref.watch(restaurantThemeProvider).primary,
          accent: ref.watch(restaurantThemeProvider).accent,
        ),
      ),
      (route) => false,
    );
  }
}
