import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tap_table_staff/features/orders/data/order_models.dart';

/// TEK MERKEZİ SİPARİŞ GÖRÜNTÜLEME DOSYASI.
///
/// Masa detayı ekranı, ana ekrandaki masa kenar paneli ve ürün seçme
/// ekranındaki "mevcut sipariş" kartı — üçü de sipariş kalemlerini
/// BURADAKİ bileşenler üzerinden gösterir. Görünümde bir değişiklik
/// (renk, boyut, hangi bilgi gösterilsin vb.) gerektiğinde sadece bu
/// dosya düzenlenir; üç ekran da otomatik olarak güncellenir.

String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'Bekliyor',
  OrderStatus.preparing => 'Hazırlanıyor',
  OrderStatus.ready => 'Hazır',
  OrderStatus.served => 'Servis Edildi',
  OrderStatus.completed => 'Tamamlandı',
  OrderStatus.cancelled => 'İptal',
};

String paymentStatusLabel(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.unpaid => 'Ödenmedi',
  OrderPaymentStatus.partiallyPaid => 'Kısmi Ödendi',
  OrderPaymentStatus.paid => 'Ödendi',
};

Color paymentStatusColor(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.unpaid => Colors.red,
  OrderPaymentStatus.partiallyPaid => Colors.orange,
  OrderPaymentStatus.paid => Colors.green,
};

/// Sipariş kalemi durumu (pending/preparing/ready/served/cancelled) için
/// rozet rengi ve etiketi.
({Color color, String label}) orderItemStatusMeta(
  OrderItemStatus status, {
  required Color primary,
  required Color accent,
}) => switch (status) {
  OrderItemStatus.pending => (color: primary, label: 'Onaylandı'),
  OrderItemStatus.preparing => (color: Colors.orange, label: 'Hazırlanıyor'),
  OrderItemStatus.ready => (color: accent, label: 'Hazır'),
  OrderItemStatus.served => (color: primary, label: 'Servis Edildi'),
  OrderItemStatus.cancelled => (color: Colors.red, label: 'İptal Edildi'),
};

/// Sipariş kalemlerini ekranda göstermek için kullanılan ortak model.
/// Notu olmayan kalemler aynı ürün + aynı durumda birleştirilip
/// adetleri toplanır (ör. "1x Köfte" + "1x Köfte" -> "2x Köfte"). Notu
/// olan kalemler asla başka bir kalemle birleştirilmez, her biri kendi
/// satırında ayrı kalır.
class DisplayOrderItem {
  final String menuItemName;
  final String? menuItemImageUrl;
  final int quantity;
  final double lineTotal;
  final String? note;
  final OrderItemStatus status;

  const DisplayOrderItem({
    required this.menuItemName,
    required this.menuItemImageUrl,
    required this.quantity,
    required this.lineTotal,
    required this.note,
    required this.status,
  });

  DisplayOrderItem _mergedWith(OrderItemResponseDto other) {
    return DisplayOrderItem(
      menuItemName: menuItemName,
      menuItemImageUrl: menuItemImageUrl,
      quantity: quantity + other.quantity,
      lineTotal: lineTotal + other.lineTotal,
      note: note,
      status: status,
    );
  }
}

/// [items] listesini görüntüleme için gruplar: notu olmayan, aynı isim
/// ve aynı durumdaki kalemlerin adetlerini/tutarlarını toplar; notu
/// olan her kalemi olduğu gibi ayrı bir satır olarak korur.
List<DisplayOrderItem> groupOrderItemsForDisplay(
  List<OrderItemResponseDto> items,
) {
  final List<DisplayOrderItem> result = [];
  final Map<String, int> groupedIndexByKey = {};

  for (final item in items) {
    final hasNote = item.note != null && item.note!.isNotEmpty;

    if (hasNote) {
      result.add(
        DisplayOrderItem(
          menuItemName: item.menuItemName,
          menuItemImageUrl: item.menuItemImageUrl,
          quantity: item.quantity,
          lineTotal: item.lineTotal,
          note: item.note,
          status: item.status,
        ),
      );
      continue;
    }

    final key = '${item.menuItemName}__${item.status}';
    final existingIndex = groupedIndexByKey[key];
    if (existingIndex != null) {
      result[existingIndex] = result[existingIndex]._mergedWith(item);
    } else {
      groupedIndexByKey[key] = result.length;
      result.add(
        DisplayOrderItem(
          menuItemName: item.menuItemName,
          menuItemImageUrl: item.menuItemImageUrl,
          quantity: item.quantity,
          lineTotal: item.lineTotal,
          note: null,
          status: item.status,
        ),
      );
    }
  }

  return result;
}

/// Sipariş kalemlerini göstermek için TEK merkezi satır bileşeni.
/// Masa detayı, kenar panel ve ürün seçme ekranındaki önizleme —
/// hepsi bunu kullanır.
class OrderItemRow extends StatelessWidget {
  final DisplayOrderItem item;
  final Color primary;
  final Color accent;
  final bool showStatusBadge;

  const OrderItemRow({
    super.key,
    required this.item,
    required this.primary,
    required this.accent,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty;
    final hasNote = item.note != null && item.note!.isNotEmpty;
    final meta = orderItemStatusMeta(
      item.status,
      primary: primary,
      accent: accent,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: item.menuItemImageUrl!,
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.menuItemName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₺${item.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (hasNote) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          size: 12,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showStatusBadge) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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

/// Mutfakta hazır olan ürünler için ortak uyarı kutusu + "Teslim
/// Edildi" butonu. Masa detayı, kenar panel ve ürün seçme ekranı
/// bunu birebir aynı şekilde kullanır.
class ReadyItemsBanner extends StatelessWidget {
  final List<DisplayOrderItem> items;
  final bool serving;
  final VoidCallback onServe;

  const ReadyItemsBanner({
    super.key,
    required this.items,
    required this.serving,
    required this.onServe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 14,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 6),
              Text(
                'Hazır ürünler (${items.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '${item.quantity}x ${item.menuItemName}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
              onPressed: serving ? null : onServe,
              icon: serving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle, size: 16),
              label: const Text(
                'Teslim Edildi',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sipariş başlığı: "Sipariş #123" + durum rozeti + ödeme durumu satırı.
class OrderStatusHeader extends StatelessWidget {
  final OrderResponseDto order;

  const OrderStatusHeader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sipariş #${order.id}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                orderStatusLabel(order.status),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ödeme: ${paymentStatusLabel(order.paymentStatus)}',
          style: TextStyle(
            fontSize: 12,
            color: paymentStatusColor(order.paymentStatus),
          ),
        ),
      ],
    );
  }
}

/// Sipariş toplamı satırı.
class OrderTotalRow extends StatelessWidget {
  final double total;

  const OrderTotalRow({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Toplam',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        Text(
          '₺${total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

/// Aktif siparişin TÜM içeriğini (başlık + hazır ürünler uyarısı +
/// kalem listesi + toplam) tek bir yerden render eden birleşik
/// bileşen.
///
/// Masa detayı ekranı, ana ekrandaki masa kenar paneli ve ürün seçme
/// ekranındaki "mevcut sipariş" kartı — üçü de birebir aynı görünümü
/// elde etmek için bunu kullanır. Aralarındaki tek fark etraflarındaki
/// sayfa düzeni (ListView / SingleChildScrollView / collapsible kart)
/// ve altlarındaki aksiyon butonlarıdır — o kısım [actions] ile
/// dışarıdan verilir (boş liste de olabilir, salt-okunur önizlemeler
/// için).
class ActiveOrderContent extends StatelessWidget {
  final OrderResponseDto order;
  final bool serving;
  final VoidCallback onServeReadyItems;
  final List<Widget> actions;

  const ActiveOrderContent({
    super.key,
    required this.order,
    required this.serving,
    required this.onServeReadyItems,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    final readyItems = order.items
        .where((i) => i.status == OrderItemStatus.ready)
        .toList();
    final displayReadyItems = groupOrderItemsForDisplay(readyItems);
    final hasReadyItems = displayReadyItems.isNotEmpty;
    final displayItems = groupOrderItemsForDisplay(order.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrderStatusHeader(order: order),
        if (hasReadyItems) ...[
          const SizedBox(height: 12),
          ReadyItemsBanner(
            items: displayReadyItems,
            serving: serving,
            onServe: onServeReadyItems,
          ),
        ],
        const Divider(height: 20),
        // Tüm kalemler — notu olmayanlar adet bazında gruplanmış, notu
        // olanlar kendi satırında ayrı; resim, not ve durum rozeti
        // bilgisiyle birlikte gösteriliyor.
        ...displayItems.map(
          (item) => OrderItemRow(item: item, primary: primary, accent: accent),
        ),
        const Divider(height: 20),
        OrderTotalRow(total: order.totalPrice),
        if (actions.isNotEmpty) const SizedBox(height: 16),
        ...actions,
      ],
    );
  }
}
