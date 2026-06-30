import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/core/constants/layout_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../../orders/data/order_models.dart';
import '../../tables/application/table_providers.dart';
import '../../tables/data/table_layout_models.dart';
import '../../tables/presentation/table_shape_widget.dart';
import 'waiter_item_picker_screen.dart';
import 'waiter_payment_screen.dart';
import 'waiter_table_detail_screen.dart';


/// Sidebar'ı gösterecek kadar geniş ekranlar için eşik. Altında tam sayfa push.
const double _sidebarBreakpoint = 700;

class WaiterHomeScreen extends ConsumerStatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  ConsumerState<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends ConsumerState<WaiterHomeScreen> {
  TableLayoutResponseDto? _selected;

  Future<void> _openDetail(BuildContext context, TableLayoutResponseDto t) async {
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
    if (mounted && _selected != null) {
      ref.invalidate(tableActiveOrderProvider(_selected!.tableId));
    }
  }

  void _handleTableTap(BuildContext context, TableLayoutResponseDto t, bool wide) {
    if (!wide) {
      _openDetail(context, t);
      return;
    }
    setState(() {
      _selected = (_selected?.tableId == t.tableId) ? null : t;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _sidebarBreakpoint;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tableLayoutProvider),
            child: layoutAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (layouts) {
                if (layouts.isEmpty) {
                  return const Center(child: Text('Henüz masa eklenmedi.'));
                }

                // Sidebar'da seçili masa artık layout listesinde yoksa (silinmiş olabilir) temizle.
                if (_selected != null &&
                    !layouts.any((t) => t.tableId == _selected!.tableId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selected = null);
                  });
                }

                return Row(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 0.4,
                        maxScale: 2.0,
                        constrained: false,
                        child: SizedBox(
                          width: LayoutConstants.canvasWidth,
                          height: LayoutConstants.canvasHeight,
                          child: Stack(
                            children: layouts.map((t) {
                              final isSelected = wide && _selected?.tableId == t.tableId;
                              return Positioned(
                                left: t.positionX.toDouble(),
                                top: t.positionY.toDouble(),
                                child: GestureDetector(
                                  onTap: () => _handleTableTap(context, t, wide),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    decoration: BoxDecoration(
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                  color: Colors.blue.withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 1)
                                            ]
                                          : [],
                                    ),
                                    child: TableShapeWidget(
                                      tableNumber: t.tableNumber,
                                      capacity: t.capacity,
                                      status: t.status,
                                      width: t.width.toDouble(),
                                      height: t.height.toDouble(),
                                      shape: t.shape,
                                      isSelected: isSelected,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    if (wide && _selected != null)
                      _TableSidebar(
                        table: _selected!,
                        onClose: () => setState(() => _selected = null),
                        onOpenFullDetail: () => _openDetail(context, _selected!),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TableSidebar extends ConsumerWidget {
  final TableLayoutResponseDto table;
  final VoidCallback onClose;
  final VoidCallback onOpenFullDetail;

  const _TableSidebar({
    required this.table,
    required this.onClose,
    required this.onOpenFullDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(tableActiveOrderProvider(table.tableId));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('Masa ${table.tableNumber}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: orderAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (order) {
                if (order == null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bu masada aktif sipariş yok.',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        WaiterItemPickerScreen(tableId: table.tableId)),
                              );
                              ref.invalidate(tableActiveOrderProvider(table.tableId));
                              ref.invalidate(tableLayoutProvider);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Sipariş Oluştur'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Sipariş #${order.id}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(orderStatusLabel(order.status),
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Ödeme: ${paymentStatusLabel(order.paymentStatus)}',
                          style: TextStyle(
                              fontSize: 12, color: paymentStatusColor(order.paymentStatus))),
                      const Divider(height: 20),
                      // En fazla ilk birkaç kalemi göster, kalanını "+N diğer" ile özetle.
                      ...order.items.take(5).map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${item.quantity}x ${item.menuItemName}',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text('₺${item.lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          )),
                      if (order.items.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('+${order.items.length - 5} diğer ürün',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Text('Toplam',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          Text('₺${order.totalPrice.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      WaiterItemPickerScreen(tableId: table.tableId)),
                            );
                            ref.invalidate(tableActiveOrderProvider(table.tableId));
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ürün Ekle', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: order.paymentStatus == OrderPaymentStatus.paid
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => WaiterPaymentScreen(order: order)),
                                  );
                                  ref.invalidate(tableActiveOrderProvider(table.tableId));
                                },
                          icon: const Icon(Icons.payments, size: 16),
                          label: Text(
                              order.paymentStatus == OrderPaymentStatus.paid
                                  ? 'Ödendi'
                                  : 'Ödeme Al',
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenFullDetail,
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Tam Ekran Detay', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}