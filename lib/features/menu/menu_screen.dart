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
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
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
                  if (hasPrevious && hasNew) const SizedBox(height: 8),
                  if (hasNew)
                    _NewItemsRow(
                      lines: cartLines,
                      total: newTotal,
                      primary: ref.watch(restaurantThemeProvider).primary,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                                fontSize: 11,
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
                                fontSize: 18,
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
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                        icon: const Icon(Icons.shopping_bag, size: 18),
                        label: const Text(
                          'Sepete Git',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                expandedHeight: 190,
                backgroundColor: ref.watch(restaurantThemeProvider).primary,
                elevation: 0,
                automaticallyImplyLeading:
                    false, // geri butonu da istemiyorsan kalsın
                title: null, // başlığı kaldır
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
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: ref.watch(restaurantThemeProvider).primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleLarge,
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

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
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
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, accent, .6)!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: _decorativeCircle(150, Colors.white.withOpacity(.08)),
          ),

          Positioned(
            left: -60,
            bottom: -40,
            child: _decorativeCircle(180, Colors.white.withOpacity(.05)),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
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

                  const SizedBox(height: 18),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Menüye Hoş Geldiniz",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.95),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
          fontSize: 24,
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: labelColor,
            ),
          ),
        ),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 12, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 100,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: lines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) =>
                    _NewItemThumb(line: lines[index]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
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
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: line.item.imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.fastfood,
                            size: 22,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.fastfood,
                          size: 22,
                          color: Colors.grey,
                        ),
                      ),
              ),
              if (line.quantity > 1)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: ref.watch(restaurantThemeProvider).accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            line.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: ref.watch(restaurantThemeProvider).primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(cartProvider.notifier).decrement(line.item.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.remove, color: Colors.white, size: 12),
                  ),
                ),
                SizedBox(
                  width: 18,
                  child: Text(
                    '${line.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(cartProvider.notifier).add(line.item);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.add, color: Colors.white, size: 12),
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
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        children: categories.map((c) {
          final selected = c.id == activeCategoryId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(c.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? primary : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  c.name,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 88,
                  height: 88,
                  color: Colors.grey.shade100,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ref
                            .watch(restaurantThemeProvider)
                            .accent
                            .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₺${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ref.watch(restaurantThemeProvider).accent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: quantity == 0
                          ? FilledButton.icon(
                              key: const ValueKey('add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ref
                                    .watch(restaurantThemeProvider)
                                    .primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).add(item),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ekle'),
                            )
                          : _QuantityStepper(
                              key: const ValueKey('stepper'),
                              item: item,
                              quantity: quantity,
                            ),
                    ),
                  ],
                ),
              ],
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: () => ref.read(cartProvider.notifier).decrement(item.id),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
