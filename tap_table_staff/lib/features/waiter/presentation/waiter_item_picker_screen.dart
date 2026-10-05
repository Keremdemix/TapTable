import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../menu/application/menu_providers.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import 'order_display.dart';
import 'waiter_table_detail_screen.dart' show tableActiveOrderProvider;

/// Sepete eklenen bir ürünü (referans + adet + not) birlikte tutar.
/// Böylece alt özet barında fiyat hesaplamak için menü listesine
/// tekrar ihtiyaç duymayız.
class _CartLine {
  final dynamic item;
  int quantity;
  String? note;
  _CartLine(this.item, this.quantity, {this.note});
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
        // Adet değişse bile daha önce girilmiş notu koru.
        _cart[id] = _CartLine(item, nextQty, note: current?.note);
      }
    });
  }

  /// [item] için not ekleme/düzenleme diyaloğunu açar. Ürün sepette
  /// olmalı (quantity > 0), aksi halde bağlanacağı bir satır yoktur.
  Future<void> _editNote(dynamic item) async {
    final id = item.id as int;
    final line = _cart[id];
    if (line == null) return;

    final controller = TextEditingController(text: line.note ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} için not'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Örn: Acısız olsun, az pişmiş, sosu ayrı...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == null) return; // Vazgeçildi, mevcut notu değiştirme

    setState(() {
      final current = _cart[id];
      if (current != null) {
        current.note = result.isEmpty ? null : result;
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
            (e) => OrderItemInput(
              menuItemId: e.key,
              quantity: e.value.quantity,
              note: e.value.note,
            ),
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

    // Görüntüleme için: notu olmayanlar ürün+durum bazında birleştirilip
    // adet gösterilir (ör. "3x Kola"), notu olanlar kendi satırında ayrı
    // kalır. Diğer ekranlarla birebir aynı mantık — order_display.dart.
    final List<DisplayOrderItem> displayPreviousItems =
        groupOrderItemsForDisplay(previousItems);

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
              items: displayPreviousItems,
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
                    final line = _cart[item.id];
                    final qty = line?.quantity ?? 0;

                    return _MenuItemPickerCard(
                      item: item,
                      quantity: qty,
                      note: line?.note,
                      accent: accent,
                      onAdd: () => _changeQty(item, 1),
                      onRemove: () => _changeQty(item, -1),
                      onEditNote: () => _editNote(item),
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
                            onEditNote: () => _editNote(line.item),
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
/// [items] zaten gruplanmış olarak gelir (bkz. groupOrderItemsForDisplay,
/// order_display.dart). Satırlar diğer ekranlarla aynı OrderItemRow ile
/// render edilir — böylece resim/not/durum rozeti hepsinde tutarlı.
class _PreviousOrderCard extends StatelessWidget {
  final List<DisplayOrderItem> items;
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
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return OrderItemRow(
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
/// fiyat rozeti + ekle/adet stepper + (sepetteyse) not ekleme satırı.
class _MenuItemPickerCard extends StatelessWidget {
  final dynamic item;
  final int quantity;
  final String? note;
  final Color accent;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onEditNote;

  const _MenuItemPickerCard({
    required this.item,
    required this.quantity,
    required this.note,
    required this.accent,
    required this.onAdd,
    required this.onRemove,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = item.imageUrl as String?;
    final String? description = item.description as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasNote = note != null && note!.isNotEmpty;

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
                // Sepete eklenmiş bir ürün için not ekleme/düzenleme satırı.
                if (quantity > 0) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onEditNote,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasNote
                            ? Colors.amber.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasNote
                              ? Colors.amber.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasNote
                                ? Icons.sticky_note_2
                                : Icons.note_add_outlined,
                            size: 14,
                            color: hasNote
                                ? Colors.amber.shade800
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasNote ? note! : 'Not ekle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasNote
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

/// Alt bardaki yatay kaydırılabilir küçük ürün kartı. Not eklenmişse
/// sol üstte küçük bir not rozeti gösterir; rozete veya karta dokununca
/// not diyaloğu açılır.
class _CartItemThumb extends StatelessWidget {
  final _CartLine line;
  final Color primary;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onEditNote;

  const _CartItemThumb({
    required this.line,
    required this.primary,
    required this.onAdd,
    required this.onRemove,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = line.item.imageUrl as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasNote = line.note != null && line.note!.isNotEmpty;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditNote,
                child: ClipRRect(
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
              if (hasNote)
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.sticky_note_2,
                      size: 9,
                      color: Colors.white,
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
