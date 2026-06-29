import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../../tables/application/table_providers.dart';
import '../../tables/data/table_models.dart';
import 'waiter_table_detail_screen.dart';

class WaiterHomeScreen extends ConsumerWidget {
  const WaiterHomeScreen({super.key});

  (String, Color) _statusInfo(TableStatus status) => switch (status) {
        TableStatus.available => ('Müsait', Colors.green),
        TableStatus.occupied => ('Dolu', Colors.orange),
        TableStatus.reserved => ('Rezerve', Colors.blue),
        TableStatus.outOfService => ('Kapalı', Colors.grey),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masalar'),
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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tablesProvider),
        child: tablesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (tables) {
            if (tables.isEmpty) return const Center(child: Text('Henüz masa eklenmedi.'));

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final (label, color) = _statusInfo(table.status);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WaiterTableDetailScreen(table: table)),
                    );
                    ref.invalidate(tablesProvider);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      border: Border.all(color: color, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Masa ${table.tableNumber}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                        Text('${table.capacity} kişilik', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}