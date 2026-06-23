import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../application/order_providers.dart';
import '../data/order_models.dart';

class KitchenHomeScreen extends ConsumerStatefulWidget {
  const KitchenHomeScreen({super.key});

  @override
  ConsumerState<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends ConsumerState<KitchenHomeScreen> {
  Timer? _pollTimer;
  final Set<int> _updatingItemIds = {};

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(kitchenOrdersProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _advanceStatus(int orderId, OrderItemResponseDto item) async {
    final next = switch (item.status) {
      OrderItemStatus.pending => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      OrderItemStatus.ready => OrderItemStatus.served,
      _ => null,
    };
    if (next == null) return;

    setState(() => _updatingItemIds.add(item.id));
    try {
      await ref.read(orderRepositoryProvider).updateItemStatus(
            orderId: orderId,
            itemId: item.id,
            status: next,
          );
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Durum güncellenemedi, tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingItemIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutfak'),
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
        onRefresh: () async => ref.invalidate(kitchenOrdersProvider),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Bekleyen sipariş yok 🎉')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(
                order: orders[index],
                updatingItemIds: _updatingItemIds,
                onAdvance: _advanceStatus,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderResponseDto order;
  final Set<int> updatingItemIds;
  final void Function(int orderId, OrderItemResponseDto item) onAdvance;

  const _OrderCard({
    required this.order,
    required this.updatingItemIds,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Masa ${order.tableNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('#${order.id}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Not: ${order.note}',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
            ],
            const Divider(),
            ...order.items.map((item) => _ItemRow(
                  item: item,
                  isUpdating: updatingItemIds.contains(item.id),
                  onAdvance: () => onAdvance(order.id, item),
                )),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItemResponseDto item;
  final bool isUpdating;
  final VoidCallback onAdvance;

  const _ItemRow({required this.item, required this.isUpdating, required this.onAdvance});

  (String, Color) _statusLabel(OrderItemStatus status) => switch (status) {
        OrderItemStatus.pending => ('Bekliyor', Colors.grey),
        OrderItemStatus.preparing => ('Hazırlanıyor', Colors.orange),
        OrderItemStatus.ready => ('Hazır', Colors.blue),
        OrderItemStatus.served => ('Servis Edildi', Colors.green),
        OrderItemStatus.cancelled => ('İptal', Colors.red),
      };

  String? _nextActionLabel(OrderItemStatus status) => switch (status) {
        OrderItemStatus.pending => 'Hazırlanmaya Başla',
        OrderItemStatus.preparing => 'Hazır',
        OrderItemStatus.ready => 'Servis Edildi',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusLabel(item.status);
    final actionLabel = _nextActionLabel(item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.quantity}x ${item.menuItemName}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(item.note!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label, style: TextStyle(color: color, fontSize: 12)),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            FilledButton(
              onPressed: isUpdating ? null : onAdvance,
              child: isUpdating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(actionLabel),
            ),
        ],
      ),
    );
  }
}