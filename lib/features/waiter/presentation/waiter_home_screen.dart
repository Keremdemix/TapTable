import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../../tables/application/table_providers.dart';
import '../../tables/presentation/table_shape_widget.dart';
import 'waiter_table_detail_screen.dart';

const double _canvasWidth = 1200;
const double _canvasHeight = 900;

class WaiterHomeScreen extends ConsumerWidget {
  const WaiterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(tableLayoutProvider);

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
        onRefresh: () async => ref.invalidate(tableLayoutProvider),
        child: layoutAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (layouts) {
            if (layouts.isEmpty) return const Center(child: Text('Henüz masa eklenmedi.'));

            return InteractiveViewer(
              minScale: 0.4,
              maxScale: 2.0,
              constrained: false,
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: Stack(
                  children: layouts.map((t) {
                    return Positioned(
                      left: t.positionX.toDouble(),
                      top: t.positionY.toDouble(),
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WaiterTableDetailScreen(
                                tableId: t.tableId,
                                tableNumber: t.tableNumber,
                              ),
                            ),
                          );
                          ref.invalidate(tableLayoutProvider);
                        },
                        child: TableShapeWidget(
                          tableNumber: t.tableNumber,
                          capacity: t.capacity,
                          status: t.status,
                          width: t.width.toDouble(),
                          height: t.height.toDouble(),
                          shape: t.shape,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}