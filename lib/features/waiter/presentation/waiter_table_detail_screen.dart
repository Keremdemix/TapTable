import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import '../../tables/data/table_models.dart';
import 'waiter_item_picker_screen.dart';
import 'waiter_payment_screen.dart';

final _tableActiveOrderProvider =
    FutureProvider.autoDispose.family<OrderResponseDto?, int>((ref, tableId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final orders = await repository.getOrders(tableId: tableId);
  for (final o in orders) {
    if (o.status != OrderStatus.completed && o.status != OrderStatus.cancelled) {
      return o;
    }
  }
  return null;
});

String _orderStatusLabel(OrderStatus status) => switch (status) {
      OrderStatus.pending => 'Bekliyor',
      OrderStatus.preparing => 'Hazırlanıyor',
      OrderStatus.ready => 'Hazır',
      OrderStatus.served => 'Servis Edildi',
      OrderStatus.completed => 'Tamamlandı',
      OrderStatus.cancelled => 'İptal',
    };

String _paymentStatusLabel(OrderPaymentStatus status) => switch (status) {
      OrderPaymentStatus.unpaid => 'Ödenmedi',
      OrderPaymentStatus.partiallyPaid => 'Kısmi Ödendi',
      OrderPaymentStatus.paid => 'Ödendi',
    };

Color _paymentStatusColor(OrderPaymentStatus status) => switch (status) {
      OrderPaymentStatus.unpaid => Colors.red,
      OrderPaymentStatus.partiallyPaid => Colors.orange,
      OrderPaymentStatus.paid => Colors.green,
    };

class WaiterTableDetailScreen extends ConsumerWidget {
  final TableResponseDto table;
  const WaiterTableDetailScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_tableActiveOrderProvider(table.id));

    return Scaffold(
      appBar: AppBar(title: Text('Masa ${table.tableNumber}')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_tableActiveOrderProvider(table.id)),
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
                        MaterialPageRoute(builder: (_) => WaiterItemPickerScreen(tableId: table.id)),
                      );
                      ref.invalidate(_tableActiveOrderProvider(table.id));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Sipariş Oluştur'),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text('Sipariş #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text(_orderStatusLabel(order.status),
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Ödeme: ${_paymentStatusLabel(order.paymentStatus)}',
                    style: TextStyle(color: _paymentStatusColor(order.paymentStatus))),
                const Divider(height: 24),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.quantity}x ${item.menuItemName}')),
                          Text('₺${item.lineTotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Text('₺${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WaiterItemPickerScreen(tableId: table.id)),
                    );
                    ref.invalidate(_tableActiveOrderProvider(table.id));
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
                            MaterialPageRoute(builder: (_) => WaiterPaymentScreen(order: order)),
                          );
                          ref.invalidate(_tableActiveOrderProvider(table.id));
                        },
                  icon: const Icon(Icons.payments),
                  label: Text(order.paymentStatus == OrderPaymentStatus.paid ? 'Ödendi' : 'Ödeme Al'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}