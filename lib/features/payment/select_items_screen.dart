import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import 'payment_models.dart';
import 'payment_provider.dart';

class SelectItemsScreen extends ConsumerStatefulWidget {
  final Color primary;
  final Color accent;

  const SelectItemsScreen({
    super.key,
    required this.primary,
    required this.accent,
  });

  @override
  ConsumerState<SelectItemsScreen> createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends ConsumerState<SelectItemsScreen> {
  final Map<int, int> _selected = {}; // orderItemId -> seçilen adet
  bool _submitting = false;

  double _selectedTotal(List<PaymentStateItem> items) {
    double total = 0;
    for (final item in items) {
      final qty = _selected[item.orderItemId] ?? 0;
      total += qty * item.unitPrice;
    }
    return total;
  }

  Future<void> _submit(int tableId) async {
    final lines = _selected.entries
        .where((e) => e.value > 0)
        .map((e) => {'orderItemId': e.key, 'quantity': e.value})
        .toList();

    if (lines.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();

      await apiClient.paySelectedItems(
        tableId,
        sessionKey: sessionKey!,
        items: lines,
      );

      ref.invalidate(paymentStateProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme talebiniz alındı, garson onayı bekleniyor.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ödeme başlatılamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(customerSessionProvider);
    final stateAsync = ref.watch(paymentStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seçerek Öde')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Oturum bilgisi alınamadı.')),
        data: (session) => stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Ödeme bilgisi alınamadı.')),
          data: (state) {
            if (state == null) {
              return const Center(child: Text('Ödeme bilgisi alınamadı.'));
            }

            if (state.hasActiveSplitPlan) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Eşit bölüşüm başlatıldığı için ürün seçerek ödeme yapılamaz.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final unpaidItems = state.items
                .where((i) => i.unpaidQuantity > 0)
                .toList();

            if (unpaidItems.isEmpty) {
              return const Center(child: Text('Ödenecek ürün kalmadı.'));
            }

            final selectedTotal = _selectedTotal(unpaidItems);

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: unpaidItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = unpaidItems[index];
                      final qty = _selected[item.orderItemId] ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
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
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ödenmemiş: ${item.unpaidQuantity} adet · ₺${item.unitPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: widget.accent.withOpacity(.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: widget.accent,
                                    ),
                                    onPressed: qty <= 0
                                        ? null
                                        : () => setState(
                                            () => _selected[item.orderItemId] =
                                                qty - 1,
                                          ),
                                  ),
                                  Text(
                                    '$qty',
                                    style: TextStyle(
                                      color: widget.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: widget.accent,
                                    ),
                                    onPressed: qty >= item.unpaidQuantity
                                        ? null
                                        : () => setState(
                                            () => _selected[item.orderItemId] =
                                                qty + 1,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Seçili Tutar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₺${selectedTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: widget.accent,
                            ),
                            onPressed: (selectedTotal <= 0 || _submitting)
                                ? null
                                : () => _submit(session.tableId),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Seçilenleri Öde'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
