import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final claims = await ref.read(authRepositoryProvider).restoreSession();
    if (!mounted) return;

    if (claims == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _navigateByRole(claims.role);
    }
  }

  void _navigateByRole(String? role) {
    final route = switch (role) {
      'Admin' => '/admin',
      'Waiter' => '/waiter',
      'Kitchen' => '/kitchen',
      _ => '/login',
    };
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}