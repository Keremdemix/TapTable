import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/features/cart/cart_provider.dart';
import 'package:tap_table_customer/features/cart/cart_screen.dart';
import '../../core/session/session_provider.dart';
import 'menu_models.dart';
import 'menu_provider.dart';

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
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final count = ref.watch(cartCountProvider);
          final total = ref.watch(cartTotalProvider);
          if (count == 0) return const SizedBox.shrink();

          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text('$count ürün', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('₺${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                    child: const Text('Sepeti Gör'),
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
          _activeCategoryId ??=
              menu.categories.isNotEmpty ? menu.categories.first.id : null;

          for (final c in menu.categories) {
            _categoryKeys.putIfAbsent(c.id, () => GlobalKey());
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    widget.session.restaurantName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  background: widget.session.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.session.logoUrl!,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.25),
                          colorBlendMode: BlendMode.darken,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primary),
                ),
              ),

              // ── Kategori seçici (sticky) ────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryBarDelegate(
                  categories: menu.categories,
                  activeCategoryId: _activeCategoryId,
                  onSelect: _scrollToCategory,
                ),
              ),

              // ── Kategoriler + ürünler ───────────────────────────────
              for (final category in menu.categories) ...[
                SliverToBoxAdapter(
                  key: _categoryKeys[category.id],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge,
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

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final List<PublicCategory> categories;
  final int? activeCategoryId;
  final void Function(int categoryId) onSelect;

  _CategoryBarDelegate({
    required this.categories,
    required this.activeCategoryId,
    required this.onSelect,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: categories.map((c) {
          final selected = c.id == activeCategoryId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(c.name),
              selected: selected,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onSelected: (_) => onSelect(c.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) {
    return oldDelegate.activeCategoryId != activeCategoryId ||
        oldDelegate.categories != categories;
  }
}

class _MenuItemCard extends ConsumerWidget {
  final PublicMenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.secondary;
    final quantity = ref.watch(
      cartProvider.select((cart) => cart[item.id]?.quantity ?? 0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 84, height: 84, color: Colors.grey.shade100),
                errorWidget: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₺${item.price.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: 15),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: quantity == 0
                          ? FilledButton.icon(
                              key: const ValueKey('add'),
                              onPressed: () => ref.read(cartProvider.notifier).add(item),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ekle'),
                            )
                          : _QuantityStepper(key: const ValueKey('stepper'), item: item, quantity: quantity),
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
  const _QuantityStepper({super.key, required this.item, required this.quantity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.secondary;

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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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