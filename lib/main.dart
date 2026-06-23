import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/role_home_screens.dart' hide KitchenHomeScreen;
import 'features/orders/presentation/kitchen_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TapTableStaffApp()));
}

class TapTableStaffApp extends StatelessWidget {
  const TapTableStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapTable Staff',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminHomeScreen(),
        '/waiter': (_) => const WaiterHomeScreen(),
        '/kitchen': (_) => const KitchenHomeScreen(),
      },
    );
  }
}