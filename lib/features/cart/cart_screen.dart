import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/features/cart/cart_models.dart';
import '../../core/session/session_provider.dart';
import '../orders/order_models.dart';
import '../orders/order_provider.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _placing = false;

  Future<void> _placeOrder() async {
  final cart = ref.read(cartProvider);
  if (cart.isEmpty) return;

  setState(() => _placing = true);

  try {
    await ref.read(apiClientProvider).placeOrder(
      items: cart.values
          .map((line) => {
                'menuItemId': line.item.id,
                'quantity': line.quantity,
              })
          .toList(),
    );

    ref.read(cartProvider.notifier).clear();
    ref.invalidate(activeOrderProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siparişiniz alındı!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sipariş gönderilemedi: $e')));
    }
  } finally {
    if (mounted) setState(() => _placing = false);
  }
}
  
  @override
  Widget build(BuildContext context) {
    final cartLines = ref.watch(cartProvider).values.toList();
    final newItemsTotal = ref.watch(cartTotalProvider);
    final newItemsCount = ref.watch(cartCountProvider);
    final activeOrderAsync = ref.watch(activeOrderProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Sepet & Siparişlerim'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (newItemsCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$newItemsCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: activeOrderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildBody(context, null, cartLines, primary),
        data: (order) => _buildBody(context, order, cartLines, primary),
      ),
      bottomNavigationBar: cartLines.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text('TOPLAM TUTAR',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                        Text(
                          '₺${newItemsTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _placing ? null : _placeOrder,
                        icon: _placing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ) 
                            : const Icon(Icons.shopping_bag, size: 18),
                        label: Text(
                          _placing
                              ? 'Gönderiliyor...'
                              : 'Siparişe Ekle (₺${newItemsTotal.toStringAsFixed(2)})',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderResponse? order,
    List<CartLine> cartLines,
    Color primary,
  ) {
    if (order == null && cartLines.isEmpty) {
      return const Center(child: Text('Sepetiniz boş.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daha önce verdiğiniz siparişler yukarıda, yeni ekledikleriniz aşağıda gösterilir.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (order != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Daha Önce Sipariş Verdiğiniz Ürünler',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.items.map((item) => _PreviousOrderTile(item: item, createdAt: order.createdAt)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.add_circle, size: 16, color: primary),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (cartLines.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Yeni Eklediğiniz Ürünler',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Yeni',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...cartLines.map((line) => _NewCartTile(line: line, primary: primary)),
        ] else if (order != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Henüz yeni ürün eklemediniz.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _PreviousOrderTile extends StatelessWidget {
  final OrderItemResponse item;
  final DateTime createdAt;

  const _PreviousOrderTile({required this.item, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(createdAt.toLocal());
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.menuItemImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade300,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.fastfood, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.fastfood, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItemName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${item.quantity} Adet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('₺${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(status: item.status),
              const SizedBox(height: 10),
              Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  ({Color color, IconData icon, String label}) get _meta {
    switch (status) {
      case 'Preparing':
        return (color: Colors.orange, icon: Icons.access_time, label: 'Hazırlanıyor');
      case 'Ready':
        return (color: Colors.green, icon: Icons.check_circle, label: 'Hazır');
      case 'Served':
        return (color: Colors.blueGrey, icon: Icons.check_circle, label: 'Servis Edildi');
      case 'Cancelled':
        return (color: Colors.red, icon: Icons.cancel, label: 'İptal Edildi');
      case 'Pending':
      default:
        return (color: Colors.green, icon: Icons.check_circle, label: 'Onaylandı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.icon, size: 13, color: m.color),
          const SizedBox(width: 4),
          Text(m.label, style: TextStyle(color: m.color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NewCartTile extends ConsumerWidget {
  final CartLine line;
  final Color primary;
  const _NewCartTile({required this.line, required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: line.item.imageUrl != null && line.item.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: line.item.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${line.quantity} Adet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('₺${line.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 16, color: primary),
                      onPressed: () => ref.read(cartProvider.notifier).decrement(line.item.id),
                    ),
                    Text('${line.quantity}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: Icon(Icons.add, size: 16, color: primary),
                      onPressed: () => ref.read(cartProvider.notifier).add(line.item),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () => ref.read(cartProvider.notifier).remove(line.item.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}