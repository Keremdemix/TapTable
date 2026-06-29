import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../menu/application/menu_providers.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';

class WaiterItemPickerScreen extends ConsumerStatefulWidget {
  final int tableId;
  const WaiterItemPickerScreen({super.key, required this.tableId});

  @override
  ConsumerState<WaiterItemPickerScreen> createState() => _WaiterItemPickerScreenState();
}

class _WaiterItemPickerScreenState extends ConsumerState<WaiterItemPickerScreen> {
  final Map<int, int> _cart = {}; // menuItemId -> quantity
  int? _selectedCategoryId;
  bool _submitting = false;

  void _changeQty(int menuItemId, int delta) {
    setState(() {
      final current = _cart[menuItemId] ?? 0;
      final next = (current + delta).clamp(0, 99);
      if (next == 0) {
        _cart.remove(menuItemId);
      } else {
        _cart[menuItemId] = next;
      }
    });
  }

  int get _totalItemCount => _cart.values.fold(0, (sum, q) => sum + q);

  Future<void> _submit() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final items = _cart.entries
          .map((e) => OrderItemInput(menuItemId: e.key, quantity: e.value))
          .toList();

      await ref.read(orderRepositoryProvider).createOrderByStaff(
            tableId: widget.tableId,
            items: items,
          );

      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(menuItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Seç')),
      body: Column(
        children: [
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  ...categories.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
              data: (items) {
                final available = items.where((i) => i.isAvailable && i.isActive);
                final filtered = _selectedCategoryId == null
                    ? available.toList()
                    : available.where((i) => i.categoryId == _selectedCategoryId).toList();

                if (filtered.isEmpty) return const Center(child: Text('Ürün bulunamadı.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final qty = _cart[item.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('₺${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: qty > 0 ? () => _changeQty(item.id, -1) : null,
                            ),
                            Text('$qty', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _changeQty(item.id, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _totalItemCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Sepeti Gönder ($_totalItemCount ürün)'),
                ),
              ),
            ),
    );
  }
}