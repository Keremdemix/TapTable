import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
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
  final Set<int> _updatingOrderIds = {};

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

  Future<void> _setItemStatus(
    int orderId,
    OrderItemResponseDto item,
    OrderItemStatus status,
  ) async {
    setState(() => _updatingItemIds.add(item.id));
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateItemStatus(orderId: orderId, itemId: item.id, status: status);
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durum güncellenemedi, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingItemIds.remove(item.id));
    }
  }

  Future<void> _advanceStatus(int orderId, OrderItemResponseDto item) async {
    final next = switch (item.status) {
      OrderItemStatus.pending => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      OrderItemStatus.ready => OrderItemStatus.served,
      _ => null,
    };
    if (next == null) return;
    await _setItemStatus(orderId, item, next);
  }

  /// Siparişteki henüz hazır olmayan tüm ürünleri tek seferde "Hazır" yapar.
  /// Kullanıcı her ürüne tek tek basmak yerine tüm siparişi bir kerede kapatabilir.
  Future<void> _markWholeOrderReady(OrderResponseDto order) async {
    final pendingItems = order.items
        .where(
          (i) =>
              i.status == OrderItemStatus.pending ||
              i.status == OrderItemStatus.preparing,
        )
        .toList();

    if (pendingItems.isEmpty) return;

    setState(() => _updatingOrderIds.add(order.id));
    try {
      await Future.wait(
        pendingItems.map(
          (item) => ref
              .read(orderRepositoryProvider)
              .updateItemStatus(
                orderId: order.id,
                itemId: item.id,
                status: OrderItemStatus.ready,
              ),
        ),
      );
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş güncellenemedi, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderIds.remove(order.id));
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
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
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
                isOrderUpdating: _updatingOrderIds.contains(orders[index].id),
                onAdvance: _advanceStatus,
                onSetStatus: _setItemStatus,
                onMarkWholeOrderReady: _markWholeOrderReady,
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
  final bool isOrderUpdating;
  final void Function(int orderId, OrderItemResponseDto item) onAdvance;
  final void Function(
    int orderId,
    OrderItemResponseDto item,
    OrderItemStatus status,
  )
  onSetStatus;
  final void Function(OrderResponseDto order) onMarkWholeOrderReady;

  const _OrderCard({
    required this.order,
    required this.updatingItemIds,
    required this.isOrderUpdating,
    required this.onAdvance,
    required this.onSetStatus,
    required this.onMarkWholeOrderReady,
  });

  @override
  Widget build(BuildContext context) {
    // Sipariş genelinde bekleyen/hazırlanan ürün var mı — bulk buton bu duruma göre gösterilir
    final hasUnfinishedItems = order.items.any(
      (i) =>
          i.status == OrderItemStatus.pending ||
          i.status == OrderItemStatus.preparing,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Masa ${order.tableNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.id}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Not: ${order.note}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ],
            const Divider(),
            ...order.items.map(
              (item) => _ItemRow(
                orderId: order.id,
                item: item,
                isUpdating: updatingItemIds.contains(item.id),
                onAdvance: () => onAdvance(order.id, item),
                onSetStatus: (status) => onSetStatus(order.id, item, status),
              ),
            ),

            // --- SİPARİŞ TAMAMEN HAZIR OLDUĞUNDA BASILACAK BUTON ---
            if (hasUnfinishedItems) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isOrderUpdating
                      ? null
                      : () => onMarkWholeOrderReady(order),
                  icon: isOrderUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all, size: 18),
                  label: Text(
                    isOrderUpdating
                        ? 'Güncelleniyor...'
                        : 'Siparişin Tamamı Hazır',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int orderId;
  final OrderItemResponseDto item;
  final bool isUpdating;
  final VoidCallback onAdvance;
  final void Function(OrderItemStatus status) onSetStatus;

  const _ItemRow({
    required this.orderId,
    required this.item,
    required this.isUpdating,
    required this.onAdvance,
    required this.onSetStatus,
  });

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
    final hasNote = item.note != null && item.note!.isNotEmpty;
    final hasImage =
        item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(hasNote ? 8 : 4),
      decoration: hasNote
          ? BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200, width: 1),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ÜRÜN GÖRSELİ ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: item.menuItemImageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.fastfood,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.fastfood,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x ${item.menuItemName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                if (hasNote) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.note!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // --- DURUM ROZETİ — artık dokununca manuel durum seçilebiliyor ---
                PopupMenuButton<OrderItemStatus>(
                  onSelected: onSetStatus,
                  itemBuilder: (context) => OrderItemStatus.values
                      .where((s) => s != item.status)
                      .map((s) {
                        final (l, c) = _statusLabel(s);
                        return PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(l),
                            ],
                          ),
                        );
                      })
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 16, color: color),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            FilledButton(
              onPressed: isUpdating ? null : onAdvance,
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
