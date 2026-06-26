import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/iyzico_connect/presentation/admin_iyzico_connect_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../tables/presentation/admin_tables_screen.dart';
import '../../menu/presentation/admin_menu_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminMenuTile(
            icon: Icons.table_bar,
            title: 'Masalar',
            subtitle: 'Masa ekle, düzenle, QR yönet',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTablesScreen())),
          ),
          _AdminMenuTile(
            icon: Icons.restaurant_menu,
            title: 'Menü',
            subtitle: 'Kategori ve ürün yönetimi',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMenuScreen())),
          ),
          _AdminMenuTile(
              icon: Icons.payment,
              title: 'Ödeme Ayarları',
            subtitle: 'Stripe Connect kurulumu',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIyzicoConnectScreen())),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}