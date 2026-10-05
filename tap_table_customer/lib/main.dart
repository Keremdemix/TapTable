import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/entry/entry_screen.dart';
import 'features/payment/global_payment_gate.dart';

/// GlobalPaymentGate'in, kullanıcı hangi ekranda olursa olsun (menü, sepet,
/// ödeme ekranı) ThankYouScreen'e yönlendirebilmesi için route yığınından
/// bağımsız bir navigator referansı gerekiyor.
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final uri = Uri.base;

  print('BASE: $uri');
  print('PATH: ${uri.path}');
  print('QUERY: ${uri.queryParameters}');

  final token = uri.queryParameters['token'] ?? uri.queryParameters['t'];

  runApp(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        // builder, route değişikliklerinden bağımsız olarak her zaman
        // ağaçta kalır — bu sayede GlobalPaymentGate hangi ekranda
        // olunursa olsun ödeme durumunu dinleyebilir.
        builder: (context, child) {
          return GlobalPaymentGate(child: child ?? const SizedBox.shrink());
        },
        home: (token != null && token.isNotEmpty)
            ? EntryScreen(token: token)
            : const Scaffold(body: Center(child: Text('QR kod bekleniyor...'))),
      ),
    ),
  );
}
