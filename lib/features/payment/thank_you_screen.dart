import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import '../../core/session/session_provider.dart';

class ThankYouScreen extends ConsumerStatefulWidget {
  final Color primary;
  final Color accent;

  const ThankYouScreen({
    super.key,
    required this.primary,
    required this.accent,
  });

  @override
  ConsumerState<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends ConsumerState<ThankYouScreen> {
  Future<void> _close() async {
    // Artık geçersiz olan SessionKey'i temizle — aynı cihazdan yeni bir QR
    // okutulursa eski token'la karışmasın.
    await ref.read(sessionStorageProvider).clear();

    if (kIsWeb) {
      try {
        html.window.close();
      } catch (_) {
        // Sekme script tarafından açılmadıysa tarayıcı kapatmaya izin
        // vermeyebilir — kullanıcı elle kapatabilir.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: widget.accent, size: 88),
              const SizedBox(height: 24),
              const Text(
                'Ödemeniz tamamlandı.',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                'Bizi tercih ettiğiniz için teşekkür ederiz.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: widget.accent),
                  onPressed: _close,
                  child: const Text('Güle Güle 👋'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
