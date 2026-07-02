import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _MenuItemCard extends StatelessWidget {
  final PublicMenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;

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
                placeholder: (_, __) => Container(
                  width: 84,
                  height: 84,
                  color: Colors.grey.shade100,
                ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: accent,
                        fontSize: 15,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        // Sepete ekleme — bir sonraki adımda cart_provider'a bağlanacak
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} sepete eklendi'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ekle'),
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