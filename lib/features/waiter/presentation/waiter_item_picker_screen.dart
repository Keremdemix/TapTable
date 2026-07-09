import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../menu/application/menu_providers.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import 'waiter_table_detail_screen.dart' show tableActiveOrderProvider;

/// Sepete eklenen bir ürünü (referans + adet) birlikte tutar.
/// Böylece alt özet barında fiyat hesaplamak için menü listesine
/// tekrar ihtiyaç duymayız.
class _CartLine {
  final dynamic item;
  int quantity;
  _CartLine(this.item, this.quantity);
}

class WaiterItemPickerScreen extends ConsumerStatefulWidget {
  final int tableId;
  const WaiterItemPickerScreen({super.key, required this.tableId});

  @override
  ConsumerState<WaiterItemPickerScreen> createState() =>
      _WaiterItemPickerScreenState();
}

class _WaiterItemPickerScreenState
    extends ConsumerState<WaiterItemPickerScreen> {
  final Map<int, _CartLine> _cart = {}; // menuItemId -> _CartLine
  int? _selectedCategoryId;
  bool _submitting = false;
  bool _previousOrderExpanded = true;

  void _changeQty(dynamic item, int delta) {
    setState(() {
      final int id = item.id as int;
      final current = _cart[id];
      final currentQty = current?.quantity ?? 0;
      final nextQty = (currentQty + delta).clamp(0, 99);

      if (nextQty == 0) {
        _cart.remove(id);
      } else {
        _cart[id] = _CartLine(item, nextQty);
      }
    });
  }

  int get _totalItemCount =>
      _cart.values.fold(0, (sum, line) => sum + line.quantity);

  double get _totalAmount => _cart.values.fold(
    0.0,
    (sum, line) => sum + (line.item.price as double) * line.quantity,
  );

  Future<void> _submit() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final items = _cart.entries
          .map(
            (e) =>
                OrderItemInput(menuItemId: e.key, quantity: e.value.quantity),
          )
          .toList();

      await ref
          .read(orderRepositoryProvider)
          .createOrderByStaff(tableId: widget.tableId, items: items);

      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(menuItemsProvider);
    final previousOrderAsync = ref.watch(
      tableActiveOrderProvider(widget.tableId),
    );

    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    final OrderResponseDto? previousOrder = previousOrderAsync.when(
      data: (o) => o,
      loading: () => null,
      error: (_, __) => null,
    );

    final List<OrderItemResponseDto> previousItems =
        previousOrder?.items ?? const [];
    final hasPreviousOrder = previousItems.isNotEmpty;

    final double previousOrderTotal = hasPreviousOrder
        ? previousItems.fold<double>(0, (sum, i) => sum + i.lineTotal)
        : 0.0;
    final int previousItemCount = hasPreviousOrder
        ? previousItems.fold<int>(0, (sum, i) => sum + i.quantity)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Ürün Seç'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(34),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.table_bar,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Masa ${widget.tableId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Masanın mevcut siparişi (varsa) ─────────────────────
          if (hasPreviousOrder)
            _PreviousOrderCard(
              items: previousItems,
              itemCount: previousItemCount,
              total: previousOrderTotal,
              expanded: _previousOrderExpanded,
              onToggle: () => setState(
                () => _previousOrderExpanded = !_previousOrderExpanded,
              ),
              primary: primary,
              accent: accent,
            ),

          // ── Kategori seçici ──────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CategoryChip(
                      label: 'Tümü',
                      selected: _selectedCategoryId == null,
                      primary: primary,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    ...categories.map(
                      (c) => _CategoryChip(
                        label: c.name,
                        selected: _selectedCategoryId == c.id,
                        primary: primary,
                        onTap: () => setState(() => _selectedCategoryId = c.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Ürün listesi ─────────────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (items) {
                final available = items.where(
                  (i) => i.isAvailable && i.isActive,
                );
                final filtered = _selectedCategoryId == null
                    ? available.toList()
                    : available
                          .where((i) => i.categoryId == _selectedCategoryId)
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Bu kategoride ürün bulunamadı.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final qty = _cart[item.id]?.quantity ?? 0;

                    return _MenuItemPickerCard(
                      item: item,
                      quantity: qty,
                      accent: accent,
                      onAdd: () => _changeQty(item, 1),
                      onRemove: () => _changeQty(item, -1),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── Yüzen alt özet + gönder barı ───────────────────────────
      bottomNavigationBar: _totalItemCount == 0
          ? null
          : SafeArea(
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
                    // NOT: yükseklik 104 - içerik (resim 52 + isim satırı + stepper 22
                    // + aralar) toplamda ~96-100px, 76 vermek overflow'a yol açıyordu.
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final line = _cart.values.elementAt(index);
                          return _CartItemThumb(
                            line: line,
                            primary: primary,
                            onAdd: () => _changeQty(line.item, 1),
                            onRemove: () => _changeQty(line.item, -1),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),
                    if (hasPreviousOrder) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mevcut sipariş tutarı',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₺${previousOrderTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EKLENECEK · $_totalItemCount ürün',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₺${_totalAmount.toStringAsFixed(2)}',
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
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _submitting ? 'Gönderiliyor...' : 'Siparişi Gönder',
                            style: const TextStyle(
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
            ),
    );
  }
}

/// Masanın önceden verilmiş/onaylanmış siparişini gösteren, tıklanınca
/// açılıp kapanan bilgi kartı. Salt okunur - burada miktar değiştirilemez.
class _PreviousOrderCard extends StatelessWidget {
  final List<OrderItemResponseDto> items;
  final int itemCount;
  final double total;
  final bool expanded;
  final VoidCallback onToggle;
  final Color primary;
  final Color accent;

  const _PreviousOrderCard({
    required this.items,
    required this.itemCount,
    required this.total,
    required this.expanded,
    required this.onToggle,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mevcut Sipariş · $itemCount ürün',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '₺${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _PreviousOrderRow(
                    item: item,
                    primary: primary,
                    accent: accent,
                  );
                },
              ),
            ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

class _PreviousOrderRow extends StatelessWidget {
  final OrderItemResponseDto item;
  final Color primary;
  final Color accent;

  const _PreviousOrderRow({
    required this.item,
    required this.primary,
    required this.accent,
  });

  ({Color color, String label}) get _statusMeta => switch (item.status) {
    OrderItemStatus.pending => (color: primary, label: 'Onaylandı'),
    OrderItemStatus.preparing => (color: Colors.orange, label: 'Hazırlanıyor'),
    OrderItemStatus.ready => (color: accent, label: 'Hazır'),
    OrderItemStatus.served => (color: primary, label: 'Servis Edildi'),
    OrderItemStatus.cancelled => (color: Colors.red, label: 'İptal Edildi'),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} Adet · ₺${item.lineTotal.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: meta.color.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              meta.label,
              style: TextStyle(
                color: meta.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MenuScreen'deki kategori çipleriyle aynı görünüm.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// MenuScreen'deki _MenuItemCard ile aynı düzen: resim + isim + açıklama +
/// fiyat rozeti + ekle/adet stepper.
class _MenuItemPickerCard extends StatelessWidget {
  final dynamic item;
  final int quantity;
  final Color accent;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuItemPickerCard({
    required this.item,
    required this.quantity,
    required this.accent,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = item.imageUrl as String?;
    final String? description = item.description as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
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
                  )
                : Container(
                    width: 88,
                    height: 88,
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
                  item.name as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
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
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₺${(item.price as double).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: onAdd,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ekle'),
                            )
                          : _QuantityStepper(
                              key: const ValueKey('stepper'),
                              quantity: quantity,
                              accent: accent,
                              onAdd: onAdd,
                              onRemove: onRemove,
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

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final Color accent;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityStepper({
    super.key,
    required this.quantity,
    required this.accent,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onRemove),
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
          _StepperButton(icon: Icons.add, onTap: onAdd),
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

/// Alt bardaki yatay kaydırılabilir küçük ürün kartı.
class _CartItemThumb extends StatelessWidget {
  final _CartLine line;
  final Color primary;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemThumb({
    required this.line,
    required this.primary,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = line.item.imageUrl as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
                        imageUrl: imageUrl,
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
                      color: Colors.deepOrange,
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
            line.item.name as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRemove,
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
                  onTap: onAdd,
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
