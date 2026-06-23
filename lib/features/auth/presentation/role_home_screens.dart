import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_providers.dart';

class _RoleHomeScaffold extends ConsumerWidget {
  final String title;
  const _RoleHomeScaffold({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(child: Text('$title ekranları buraya gelecek')),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const _RoleHomeScaffold(title: 'Admin Paneli');
}

class WaiterHomeScreen extends StatelessWidget {
  const WaiterHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const _RoleHomeScaffold(title: 'Garson');
}

class KitchenHomeScreen extends StatelessWidget {
  const KitchenHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const _RoleHomeScaffold(title: 'Mutfak');
}