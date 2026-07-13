import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/features/cart/cart_models.dart';
import 'package:tap_table_customer/features/payment/payment_models.dart';
import 'package:tap_table_customer/features/payment/payment_progress_badge.dart';
import '../../core/session/session_provider.dart';
import '../orders/order_models.dart';
import '../orders/order_provider.dart';
import 'cart_provider.dart';
import '../payment/payment_provider.dart';
import '../payment/select_items_screen.dart';
import '../payment/split_payment_screen.dart';
import '../payment/checkout_pending_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
      await ref
          .read(apiClientProvider)
          .placeOrder(
            items: cart.values
                .map(
                  (line) => {
                    'menuItemId': line.item.id,
                    'quantity': line.quantity,
                    'note': line
                        .note, // null olabilir, backend nullable kabul etmeli
                  },
                )
                .toList(),
          );

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(activeOrderProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Siparişiniz alındı!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sipariş gönderilemedi: $e')));
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

    final sessionAsync = ref.watch(customerSessionProvider);
    final session = sessionAsync.value;

    final primary = session != null
        ? colorFromHex(session.primaryColorHex)
        : Theme.of(context).colorScheme.primary;

    final accent = session != null
        ? colorFromHex(session.accentColorHex)
        : Colors.deepOrange;

    final order = activeOrderAsync.when(
      data: (o) => o,
      loading: () => null,
      error: (_, __) => null,
    );

    final hasOrder = order != null && order.items.isNotEmpty;
    final hasNewItems = cartLines.isNotEmpty;
    final showBottomBar = hasOrder || hasNewItems;

    // Daha önce onaylanmış siparişin tutarı
    final previousOrderTotal = hasOrder
        ? order.items.fold<double>(0, (sum, item) => sum + item.lineTotal)
        : 0.0;

    // Genel toplam: onaylanmış sipariş + henüz eklenmemiş sepet
    final grandTotal = previousOrderTotal + newItemsTotal;

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
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$newItemsCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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
        error: (_, __) => _buildBody(context, null, cartLines, primary, accent),
        data: (o) => _buildBody(context, o, cartLines, primary, accent),
      ),
      bottomNavigationBar: !showBottomBar
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SEPET (henüz siparişe eklenmemiş yeni ürünler) ---
                    if (hasNewItems) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart,
                                      size: 16,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SEPETİNİZ · Henüz Sipariş Verilmedi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₺${newItemsTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 50,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _placing ? null : _placeOrder,
                                icon: _placing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.playlist_add_check,
                                        size: 18,
                                      ),
                                label: Text(
                                  _placing
                                      ? 'Gönderiliyor...'
                                      : 'Bu Ürünleri Siparişe Ekle',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Bu bir ödeme değildir; ürünler mutfağa iletilir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // --- GENEL SİPARİŞ TOPLAMI ---
                    if (hasOrder || hasNewItems) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GENEL SİPARİŞ TOPLAMI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  letterSpacing: .3,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₺${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // --- ÖDEME SEÇENEKLERİ ---
                    if (hasOrder) ...[
                      const SizedBox(height: 12),
                      if (hasNewItems)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ödeme yapmadan önce sepetinizdeki ürünleri siparişe ekleyin.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Text(
                          'Nasıl ödemek istersiniz?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PaymentOptionsRow(primary: primary, accent: accent),
                      ],
                    ],
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
    Color accent,
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
            color: primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Yeni eklediğiniz ürünler yukarıda, daha önce verdiğiniz siparişler aşağıda gösterilir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- ÖNCE: YENİ EKLENEN ÜRÜNLER ---
        if (cartLines.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Yeni Eklediğiniz Ürünler',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Henüz Gönderilmedi',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...cartLines.map(
            (line) =>
                _NewCartTile(line: line, primary: primary, accent: accent),
          ),

          if (order != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.history, size: 16, color: primary),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],

        // --- SONRA: DAHA ÖNCE VERİLEN SİPARİŞ ---
        if (order != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Daha Önce Sipariş Verdiğiniz Ürünler',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...order.items.map(
            (item) => _PreviousOrderTile(
              item: item,
              createdAt: order.createdAt,
              primary: primary,
              accent: accent,
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Bu siparişin tutarı: ₺${order.items.fold<double>(0, (s, i) => s + i.lineTotal).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ] else if (cartLines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Henüz onaylanmış bir siparişiniz yok.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _PreviousOrderTile extends StatelessWidget {
  final OrderItemResponse item;
  final DateTime createdAt;
  final Color primary;
  final Color accent;

  const _PreviousOrderTile({
    required this.item,
    required this.createdAt,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(createdAt.toLocal());
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final hasNote = item.note != null && item.note!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    item.menuItemImageUrl != null &&
                        item.menuItemImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.menuItemImageUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
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
                    Text(
                      item.menuItemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} Adet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₺${item.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(
                    status: item.status,
                    primary: primary,
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeStr,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sticky_note_2,
                    size: 15,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.note!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color primary;
  final Color accent;

  const _StatusChip({
    required this.status,
    required this.primary,
    required this.accent,
  });

  ({Color color, IconData icon, String label}) get _meta {
    switch (status) {
      case 'Preparing':
        return (
          color: Colors.orange,
          icon: Icons.access_time,
          label: 'Hazırlanıyor',
        );

      case 'Ready':
        return (color: accent, icon: Icons.check_circle, label: 'Hazır');

      case 'Served':
        return (
          color: primary,
          icon: Icons.check_circle,
          label: 'Servis Edildi',
        );

      case 'Cancelled':
        return (color: Colors.red, icon: Icons.cancel, label: 'İptal Edildi');

      case 'Pending':
      default:
        return (color: primary, icon: Icons.check_circle, label: 'Onaylandı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: m.color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.icon, size: 13, color: m.color),
          const SizedBox(width: 4),
          Text(
            m.label,
            style: TextStyle(
              color: m.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCartTile extends ConsumerWidget {
  final CartLine line;
  final Color primary;
  final Color accent;

  const _NewCartTile({
    required this.line,
    required this.primary,
    required this.accent,
  });

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: line.note ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${line.item.name} için not',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 140,
          maxLines: 3,
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: 'Örn: Acısız olsun, soğansız olsun...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.6),
            ),
            counterStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text(
              'Vazgeç',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(cartProvider.notifier).updateNote(line.item.id, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNote = line.note != null && line.note!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    line.item.imageUrl != null && line.item.imageUrl!.isNotEmpty
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
                    Text(
                      line.item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${line.quantity} Adet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₺${line.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: 16, color: accent),
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .decrement(line.item.id),
                        ),
                        Text(
                          '${line.quantity}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 16, color: accent),
                          onPressed: () =>
                              ref.read(cartProvider.notifier).add(line.item),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: accent),
                    onPressed: () =>
                        ref.read(cartProvider.notifier).remove(line.item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // --- NOT ALANI ---
          InkWell(
            onTap: () => _editNote(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: hasNote ? Colors.amber.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasNote ? Colors.amber.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasNote ? Icons.sticky_note_2 : Icons.note_add_outlined,
                    size: 15,
                    color: hasNote
                        ? Colors.amber.shade800
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasNote ? line.note! : 'Not ekle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasNote ? FontWeight.w600 : FontWeight.w500,
                        color: hasNote
                            ? Colors.amber.shade900
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.edit, size: 13, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color colorFromHex(String hex) {
  final buffer = StringBuffer();

  if (hex.replaceFirst('#', '').length == 6) {
    buffer.write('ff');
  }

  buffer.write(hex.replaceFirst('#', ''));

  return Color(int.parse(buffer.toString(), radix: 16));
}

class _PaymentOptionsRow extends ConsumerWidget {
  final Color primary;
  final Color accent;

  const _PaymentOptionsRow({required this.primary, required this.accent});

  Future<void> _startFullCheckout(BuildContext context, WidgetRef ref) async {
    final session = ref.read(customerSessionProvider).value;
    if (session == null) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();

      final json = await apiClient.createIyzicoCheckout(
        session.tableId,
        sessionKey: sessionKey!,
      );

      final checkout = IyzicoCheckoutResult.fromJson(json);
      await launchUrl(
        Uri.parse(checkout.paymentPageUrl),
        webOnlyWindowName: '_blank',
      );

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutPendingScreen(
              primary: primary,
              accent: accent,
              paymentId: checkout.paymentId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ödeme başlatılamadı: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(paymentStateProvider);
    final state = stateAsync.value;
    final hasActivePlan = state?.hasActiveSplitPlan ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state != null) PaymentProgressBadge(state: state, accent: accent),

        // Hepsini Öde — ana CTA, tam genişlik, dolgun
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: hasActivePlan ? Colors.grey.shade300 : accent,
              elevation: hasActivePlan ? 0 : 2,
              shadowColor: accent.withOpacity(.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: hasActivePlan
                ? null
                : () => _startFullCheckout(context, ref),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments,
                  size: 20,
                  color: hasActivePlan ? Colors.grey.shade500 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hepsini Öde',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: hasActivePlan ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Alt satır — ikincil seçenekler, hafif kart görünümü
        Row(
          children: [
            Expanded(
              child: _PaymentOptionCard(
                icon: Icons.checklist_rtl,
                label: 'Seçerek Öde',
                color: primary,
                onTap: hasActivePlan
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectItemsScreen(
                            primary: primary,
                            accent: accent,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PaymentOptionCard(
                icon: Icons.call_split,
                label: 'Bölerek Öde',
                color: Colors.purple.shade400,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SplitPaymentScreen(primary: primary, accent: accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: disabled ? Colors.grey.shade100 : color.withOpacity(.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled ? Colors.grey.shade300 : color.withOpacity(.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: disabled ? Colors.grey.shade400 : color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: disabled ? Colors.grey.shade400 : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
