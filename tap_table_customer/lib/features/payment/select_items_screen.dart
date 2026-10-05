import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_customer/core/theme/restaurant_theme_provider.dart';
import '../../core/session/session_provider.dart';
import 'payment_models.dart';
import 'payment_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'checkout_pending_screen.dart';

/// Aynı isimdeki ürünleri gruplamak için yardımcı sınıf
class GroupedPaymentItem {
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final List<PaymentStateItem> originalItems;

  GroupedPaymentItem({
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.originalItems,
  });

  /// Gruptaki toplam ödenmemiş adet (Örn: 2 adet Kola + 1 adet Kola = 3)
  int get totalUnpaidQuantity =>
      originalItems.fold(0, (sum, item) => sum + item.unpaidQuantity);

  /// Rozette gösterilecek toplam adet
  int get totalQuantity => totalUnpaidQuantity;
}

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
  // ARTIK SEÇİMLERİ ÜRÜN ADINA GÖRE TUTUYORUZ: Map<menuItemName, seçilenAdet>
  final Map<String, int> _selected = {};
  bool _submitting = false;

  /// Gruplanmış ürünlerin seçili toplam tutarını hesaplar
  double _selectedTotal(List<GroupedPaymentItem> groupedItems) {
    double total = 0;
    for (final group in groupedItems) {
      final qty = _selected[group.name] ?? 0;
      total += qty * group.unitPrice;
    }
    return total;
  }

  /// Listeyi ürün adına göre gruplar
  List<GroupedPaymentItem> _groupItems(List<PaymentStateItem> items) {
    final Map<String, List<PaymentStateItem>> tempGroups = {};

    for (final item in items) {
      tempGroups.putIfAbsent(item.menuItemName, () => []).add(item);
    }

    return tempGroups.entries.map((entry) {
      final firstItem = entry.value.first;
      return GroupedPaymentItem(
        name: entry.key,
        imageUrl: firstItem.menuItemImageUrl,
        unitPrice: firstItem.unitPrice,
        originalItems: entry.value,
      );
    }).toList();
  }

  Future<void> _submit(
    int tableId,
    List<GroupedPaymentItem> groupedItems,
    Color activeprimary,
    Color activeaccent,
  ) async {
    final List<Map<String, dynamic>> lines = [];

    // Seçilen adetleri gerçek orderItemId'lere paylaştırıyoruz
    for (final group in groupedItems) {
      int remainingQtyToPay = _selected[group.name] ?? 0;
      if (remainingQtyToPay <= 0) continue;

      for (final subItem in group.originalItems) {
        if (remainingQtyToPay <= 0) break;

        // Bu orderItemId için en fazla ödenebilecek miktar
        final int allocatable = subItem.unpaidQuantity;
        final int toPayForThisItem = remainingQtyToPay > allocatable
            ? allocatable
            : remainingQtyToPay;

        if (toPayForThisItem > 0) {
          lines.add({
            'orderItemId': subItem.orderItemId,
            'quantity': toPayForThisItem,
          });
          remainingQtyToPay -= toPayForThisItem;
        }
      }
    }

    if (lines.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionKey = await ref.read(sessionStorageProvider).getToken();

      final json = await apiClient.paySelectedItems(
        tableId,
        sessionKey: sessionKey!,
        items: lines,
      );

      final checkout = IyzicoCheckoutResult.fromJson(json);
      await launchUrl(
        Uri.parse(checkout.paymentPageUrl),
        webOnlyWindowName: '_blank',
      );

      setState(() => _selected.clear()); // Başarılıysa seçimleri sıfırla

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutPendingScreen(
              primary: activeprimary,
              accent: activeaccent,
              paymentId: checkout.paymentId,
            ),
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

    final primary = ref.watch(restaurantThemeProvider).primary;

    final accent = ref.watch(restaurantThemeProvider).accent;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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

            // Ödenmemiş olan orijinal itemleri filtrele
            final unpaidItems = state.items
                .where((i) => i.unpaidQuantity > 0)
                .toList();

            if (unpaidItems.isEmpty) {
              return const Center(child: Text('Ödenecek ürün kalmadı.'));
            }

            // GRUPLAMA BURADA YAPILIYOR
            final groupedList = _groupItems(unpaidItems);
            final selectedTotal = _selectedTotal(groupedList);

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final group = groupedList[index];
                      final qty = _selected[group.name] ?? 0;

                      return _SelectableItemTile(
                        group: group,
                        selectedQty: qty,
                        primary: primary,
                        accent: accent,
                        onDecrement: qty <= 0
                            ? null
                            : () => setState(
                                () => _selected[group.name] = qty - 1,
                              ),
                        onIncrement: qty >= group.totalUnpaidQuantity
                            ? null
                            : () => setState(
                                () => _selected[group.name] = qty + 1,
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
                              backgroundColor: accent,
                            ),
                            onPressed: (selectedTotal <= 0 || _submitting)
                                ? null
                                : () => _submit(
                                    session.tableId,
                                    groupedList,
                                    primary,
                                    accent,
                                  ),
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

class _SelectableItemTile extends StatelessWidget {
  final GroupedPaymentItem group;
  final int selectedQty;
  final Color primary;
  final Color accent;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _SelectableItemTile({
    required this.group,
    required this.selectedQty,
    required this.primary,
    required this.accent,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedQty > 0;
    final totalUnpaid = group.totalUnpaidQuantity;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? accent.withOpacity(.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accent.withOpacity(.45) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: group.imageUrl != null && group.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: group.imageUrl!,
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
              // --- Dinamik renkli ve group.totalQuantity kullanan Rozet ---
              if (totalUnpaid > 1)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      'x${group.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ödenmemiş: $totalUnpaid adet · ₺${group.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Seçilen: $selectedQty adet',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                  onPressed: onDecrement,
                ),
                Text(
                  '$selectedQty',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 16, color: accent),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
