import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/orders/presentation/kitchen_home_screen.dart';
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/waiter/presentation/waiter_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TapTableStaffApp()));
}

class TapTableStaffApp extends StatelessWidget {
  const TapTableStaffApp({super.key});

  static const Color primaryColor = Color(0xFF3E7CD3);
  static const Color accentColor = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapTable Staff',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // Ana tema rengi
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
        ),

        // FilledButton, ElevatedButton vb. varsayılan rengi
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),

        // ElevatedButton varsayılan rengi
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),

        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
        ),
      ),

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
