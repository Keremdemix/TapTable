import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/tables/application/table_providers.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import '../application/ready_alert_provider.dart';
import 'waiter_item_picker_screen.dart';
import 'waiter_payment_screen.dart';

/// Public: WaiterHomeScreen'in yan paneli (_TableSidebar) de bu provider'ı kullanıyor.
final tableActiveOrderProvider = FutureProvider.autoDispose
    .family<OrderResponseDto?, int>((ref, tableId) async {
      final repository = ref.watch(orderRepositoryProvider);
      final orders = await repository.getOrders(tableId: tableId);
      for (final o in orders) {
        if (o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled) {
          return o;
        }
      }
      return null;
    });

String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'Bekliyor',
  OrderStatus.preparing => 'Hazırlanıyor',
  OrderStatus.ready => 'Hazır',
  OrderStatus.served => 'Servis Edildi',
  OrderStatus.completed => 'Tamamlandı',
  OrderStatus.cancelled => 'İptal',
};

String paymentStatusLabel(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.unpaid => 'Ödenmedi',
  OrderPaymentStatus.partiallyPaid => 'Kısmi Ödendi',
  OrderPaymentStatus.paid => 'Ödendi',
};

Color paymentStatusColor(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.unpaid => Colors.red,
  OrderPaymentStatus.partiallyPaid => Colors.orange,
  OrderPaymentStatus.paid => Colors.green,
};

class WaiterTableDetailScreen extends ConsumerStatefulWidget {
  final int tableId;
  final int tableNumber;
  const WaiterTableDetailScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  ConsumerState<WaiterTableDetailScreen> createState() =>
      _WaiterTableDetailScreenState();
}

class _WaiterTableDetailScreenState
    extends ConsumerState<WaiterTableDetailScreen> {
  bool _serving = false;

  Future<void> _serveReadyItems() async {
    setState(() => _serving = true);
    try {
      await ref.read(orderRepositoryProvider).serveReadyItems(widget.tableId);
      ref.invalidate(tableActiveOrderProvider(widget.tableId));
      // Poll'u beklemeden masa parlamasını hemen kapat.
      await ref.read(readyAlertProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Teslim işlemi başarısız: $e')));
      }
    } finally {
      if (mounted) setState(() => _serving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(tableActiveOrderProvider(widget.tableId));
    return Scaffold(
      appBar: AppBar(title: Text('Masa ${widget.tableNumber}')),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(tableActiveOrderProvider(widget.tableId)),
        child: orderAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (order) {
            if (order == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  const Center(child: Text('Bu masada aktif sipariş yok.')),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WaiterItemPickerScreen(tableId: widget.tableId),
                        ),
                      );
                      ref.invalidate(tableActiveOrderProvider(widget.tableId));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Sipariş Oluştur'),
                  ),
                ],
              );
            }

            final readyItems = order.items
                .where((i) => i.status == OrderItemStatus.ready)
                .toList();
            final hasReadyItems = readyItems.isNotEmpty;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      'Sipariş #${order.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        orderStatusLabel(order.status),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ödeme: ${paymentStatusLabel(order.paymentStatus)}',
                  style: TextStyle(
                    color: paymentStatusColor(order.paymentStatus),
                  ),
                ),
                if (hasReadyItems) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hazır ürünler (${readyItems.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...readyItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${item.quantity}x ${item.menuItemName}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                            ),
                            onPressed: _serving ? null : _serveReadyItems,
                            icon: _serving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 16),
                            label: const Text('Teslim Edildi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.quantity}x ${item.menuItemName}'),
                        ),
                        Text('₺${item.lineTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text(
                      'Toplam',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₺${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WaiterItemPickerScreen(tableId: widget.tableId),
                      ),
                    );
                    ref.invalidate(tableActiveOrderProvider(widget.tableId));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ürün Ekle'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: order.paymentStatus == OrderPaymentStatus.paid
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WaiterPaymentScreen(order: order),
                            ),
                          );
                          ref.invalidate(
                            tableActiveOrderProvider(widget.tableId),
                          );
                          ref.invalidate(tableLayoutProvider);
                        },
                  icon: const Icon(Icons.payments),
                  label: Text(
                    order.paymentStatus == OrderPaymentStatus.paid
                        ? 'Ödendi'
                        : 'Ödeme Al',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
