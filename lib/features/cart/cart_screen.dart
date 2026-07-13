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
                  'Daha önce verdiğiniz siparişler yukarıda, yeni ekledikleriniz aşağıda gösterilir.',
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

          // Önceki sipariş için ara toplam - genel toplamla karışmasın diye burada gösteriliyor
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

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.add_circle, size: 16, color: accent),
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
        ] else if (order != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Henüz yeni ürün eklemediniz.',
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '₺${item.lineTotal.toStringAsFixed(2)}',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(.30)),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 2),

                Text(
                  '₺${line.total.toStringAsFixed(2)}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
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
        Row(
          children: [
            Expanded(
              child: _PaymentButton(
                icon: Icons.checklist_rtl,
                label: 'Seçerek Öde',
                color: primary,
                filled: false,
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
            const SizedBox(width: 8),
            Expanded(
              child: _PaymentButton(
                icon: Icons.call_split,
                label: 'Bölerek Öde',
                color: primary,
                filled: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SplitPaymentScreen(primary: primary, accent: accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PaymentButton(
                icon: Icons.payments,
                label: 'Hepsini Öde',
                color: accent,
                filled: true,
                onTap: hasActivePlan
                    ? null
                    : () => _startFullCheckout(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _PaymentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              child: _content(Colors.white),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(.4)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              child: _content(color),
            ),
    );
  }

  Widget _content(Color fg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    );
  }
}
