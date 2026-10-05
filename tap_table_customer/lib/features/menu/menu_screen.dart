import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/core/theme/restaurant_theme_provider.dart';
import 'package:tap_table_customer/features/cart/cart_models.dart';
import 'package:tap_table_customer/features/cart/cart_provider.dart';
import 'package:tap_table_customer/features/cart/cart_screen.dart';
import 'package:tap_table_customer/features/orders/order_provider.dart';
import '../../core/session/session_provider.dart';
import 'menu_models.dart';
import 'menu_provider.dart';
import '../payment/payment_provider.dart';
import '../payment/payment_progress_badge.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final CustomerSession session;
  const MenuScreen({super.key, required this.session});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};
  int? _activeCategoryId;

  void _scrollToCategory(int categoryId) {
    final key = _categoryKeys[categoryId];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    setState(() => _activeCategoryId = categoryId);
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(publicMenuProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final cartLines = ref.watch(cartProvider).values.toList();
          final newTotal = ref.watch(cartTotalProvider);
          final activeOrderAsync = ref.watch(activeOrderProvider);
          final paymentState = ref.watch(paymentStateProvider).value;

          final order = activeOrderAsync.when(
            data: (o) => o,
            loading: () => null,
            error: (_, __) => null,
          );

          final hasPrevious = order != null && order.items.isNotEmpty;
          final hasNew = cartLines.isNotEmpty;

          if (!hasPrevious && !hasNew) return const SizedBox.shrink();

          final previousCount = hasPrevious
              ? order.items.fold<int>(0, (sum, i) => sum + i.quantity)
              : 0;
          final previousTotal = hasPrevious
              ? order.items.fold<double>(0, (sum, i) => sum + i.lineTotal)
              : 0.0;
          final grandTotal = previousTotal + newTotal;

          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPrevious)
                    _BottomBarSummaryRow(
                      icon: Icons.check,
                      iconBg: Colors.grey.shade400,
                      label: 'Onaylanan: $previousCount ürün',
                      amount: previousTotal,
                      labelColor: Colors.grey.shade700,
                    ),
                  if (hasPrevious && hasNew) const SizedBox(height: 6),
                  if (hasNew)
                    _NewItemsRow(
                      lines: cartLines,
                      total: newTotal,
                      primary: ref.watch(restaurantThemeProvider).primary,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  if (paymentState != null)
                    PaymentProgressBadge(
                      state: paymentState,
                      accent: ref.watch(restaurantThemeProvider).accent,
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOPLAM TUTAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₺${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ref
                              .watch(restaurantThemeProvider)
                              .primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                        icon: const Icon(Icons.shopping_bag, size: 16),
                        label: const Text(
                          'Sepete Git',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Menü yüklenemedi: $err')),
        data: (menu) {
          _activeCategoryId ??= menu.categories.isNotEmpty
              ? menu.categories.first.id
              : null;

          for (final c in menu.categories) {
            _categoryKeys.putIfAbsent(c.id, () => GlobalKey());
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 150,
                backgroundColor: ref.watch(restaurantThemeProvider).primary,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: null,
                flexibleSpace: FlexibleSpaceBar(
                  title: null,
                  background: _RestaurantHeader(
                    name: widget.session.restaurantName,
                    logoUrl: widget.session.logoUrl,
                    primary: ref.watch(restaurantThemeProvider).primary,
                    accent: ref.watch(restaurantThemeProvider).accent,
                  ),
                ),
              ),
              // ── Kategori seçici (sticky) ────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryBarDelegate(
                  categories: menu.categories,
                  activeCategoryId: _activeCategoryId,
                  onSelect: _scrollToCategory,
                  primary: ref.watch(restaurantThemeProvider).primary,
                ),
              ),

              // ── Kategoriler + ürünler ───────────────────────────────
              for (final category in menu.categories) ...[
                SliverToBoxAdapter(
                  key: _categoryKeys[category.id],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 15,
                          decoration: BoxDecoration(
                            color: ref.watch(restaurantThemeProvider).primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _MenuItemCard(item: category.items[index]),
                    childCount: category.items.length,
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

/// Üst başlık — restoranın primary/accent renkleriyle gradyan bir zemin,
/// üzerinde beyaz çerçeveli logo rozeti ve restoran adı. Logo yoksa
/// baş harfle bir rozet üretir, böylece header hiçbir zaman boş/çirkin durmaz.
class _RestaurantHeader extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final Color primary;
  final Color accent;

  const _RestaurantHeader({
    required this.name,
    required this.logoUrl,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, accent, .6)!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: _decorativeCircle(100, Colors.white.withOpacity(.08)),
          ),

          Positioned(
            left: -40,
            bottom: -30,
            child: _decorativeCircle(120, Colors.white.withOpacity(.05)),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasLogo
                          ? CachedNetworkImage(
                              imageUrl: logoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) =>
                                  _initialsBadge(primary),
                            )
                          : _initialsBadge(primary),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Menüye Hoş Geldiniz",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.95),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _initialsBadge(Color primary) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      color: primary.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

/// cart_screen'deki "Onaylanan / Yeni" satır tasarımı ile aynı mantıkta
/// küçük ikon + etiket + tutar satırı.
class _BottomBarSummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final double amount;
  final Color labelColor;

  const _BottomBarSummaryRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.amount,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: labelColor,
            ),
          ),
        ),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

/// "Yeni" satırı: eklenen ürünlerin küçük resimlerini yatayda kaydırılabilir
/// şekilde gösterir. Çok sayıda farklı ürün eklendiğinde satır sabit
/// yükseklikte kalır, ürünler soldan sağa kaydırılarak görülür.
class _NewItemsRow extends StatelessWidget {
  final List<CartLine> lines;
  final double total;
  final Color primary;

  const _NewItemsRow({
    required this.lines,
    required this.total,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 10, color: Colors.white),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 76,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: lines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (context, index) =>
                    _NewItemThumb(line: lines[index]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: primary,
          ),
        ),
      ],
    );
  }
}

class _NewItemThumb extends ConsumerWidget {
  final CartLine line;

  const _NewItemThumb({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage =
        line.item.imageUrl != null && line.item.imageUrl!.isNotEmpty;

    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: line.item.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.fastfood,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.fastfood,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
              ),
              if (line.quantity > 1)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: ref.watch(restaurantThemeProvider).accent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    constraints: const BoxConstraints(minWidth: 14),
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            line.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Container(
            height: 19,
            decoration: BoxDecoration(
              color: ref.watch(restaurantThemeProvider).primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ref.read(cartProvider.notifier).decrement(line.item.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(Icons.remove, color: Colors.white, size: 10),
                  ),
                ),
                SizedBox(
                  width: 15,
                  child: Text(
                    '${line.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ref.read(cartProvider.notifier).add(line.item);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(Icons.add, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final List<PublicCategory> categories;
  final int? activeCategoryId;
  final void Function(int categoryId) onSelect;
  final Color primary;

  _CategoryBarDelegate({
    required this.categories,
    required this.activeCategoryId,
    required this.onSelect,
    required this.primary,
  });

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        children: categories.map((c) {
          final selected = c.id == activeCategoryId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelect(c.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? primary : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  c.name,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) {
    return oldDelegate.activeCategoryId != activeCategoryId ||
        oldDelegate.categories != categories ||
        oldDelegate.primary != primary;
  }
}

class _MenuItemCard extends ConsumerWidget {
  final PublicMenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      cartProvider.select((cart) => cart[item.id]?.quantity ?? 0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade100,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ref
                        .watch(restaurantThemeProvider)
                        .accent
                        .withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₺${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ref.watch(restaurantThemeProvider).accent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Sağdaki buton ürün kartının tamamına göre dikey ortalanır
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: quantity == 0
                ? FilledButton.icon(
                    key: const ValueKey('add'),
                    style: FilledButton.styleFrom(
                      fixedSize: const Size(90, 36),
                      backgroundColor: ref
                          .watch(restaurantThemeProvider)
                          .primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => ref.read(cartProvider.notifier).add(item),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Ekle', style: TextStyle(fontSize: 12)),
                  )
                : _QuantityStepper(
                    key: const ValueKey('stepper'),
                    item: item,
                    quantity: quantity,
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final PublicMenuItem item;
  final int quantity;
  const _QuantityStepper({
    super.key,
    required this.item,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(restaurantThemeProvider).accent;

    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: () => ref.read(cartProvider.notifier).decrement(item.id),
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: () => ref.read(cartProvider.notifier).add(item),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
