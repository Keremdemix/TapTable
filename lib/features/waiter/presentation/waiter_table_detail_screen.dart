import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/tables/application/table_providers.dart';
import 'package:tap_table_staff/features/waiter/presentation/order_display.dart';
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ActiveOrderContent(
                  order: order,
                  serving: _serving,
                  onServeReadyItems: _serveReadyItems,
                  actions: [
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WaiterItemPickerScreen(tableId: widget.tableId),
                          ),
                        );

                        ref.invalidate(
                          tableActiveOrderProvider(widget.tableId),
                        );
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
                                  builder: (_) =>
                                      WaiterPaymentScreen(order: order),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
