import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../application/order_providers.dart';
import '../data/order_models.dart';

// Sipariş süresine göre renk eşikleri — istersen bu değerleri ayarla.
const _kWarningThreshold = Duration(minutes: 10);
const _kDangerThreshold = Duration(minutes: 20);

class KitchenHomeScreen extends ConsumerStatefulWidget {
  const KitchenHomeScreen({super.key});

  @override
  ConsumerState<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends ConsumerState<KitchenHomeScreen> {
  Timer? _pollTimer;
  Timer? _tickTimer;
  final Set<int> _updatingItemIds = {};
  final Set<int> _updatingOrderIds = {};
  final Set<int> _newlyArrivedOrderIds = {};
  final Set<int> _newlyArrivedItemIds =
      {}; // ← YENİ: mevcut siparişe eklenen yeni ürünler
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<int>? _lastKnownOrderIds;
  Set<int>? _lastKnownItemIds; // ← YENİ

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(kitchenOrdersProvider);
    });
    // Süre sayaçlarını her saniye tazelemek için — ağ isteği yapmaz, sadece rebuild eder.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (_) {
      // Ses dosyası eksikse sessizce yut — kritik akışı bozmasın.
    }
  }

  /// Hem YENİ SİPARİŞLERİ hem de MEVCUT bir siparişe sonradan eklenen
  /// YENİ ÜRÜNLERİ tek seferde tespit eder. İkisi için de aynı ses çalınır,
  /// ama highlight/blink efekti ayrı ayrı uygulanır: yeni sipariş → tüm kart
  /// yanıp söner, mevcut siparişe eklenen ürün → sadece o ürün satırı yanıp söner.
  void _handleOrdersUpdate(List<OrderResponseDto> orders) {
    final currentOrderIds = orders.map((o) => o.id).toSet();
    final currentItemIds = orders
        .expand((o) => o.items)
        .map((i) => i.id)
        .toSet();

    final isFirstLoad = _lastKnownOrderIds == null;

    if (!isFirstLoad) {
      final newOrderIds = currentOrderIds.difference(_lastKnownOrderIds!);
      final newItemIds = currentItemIds.difference(_lastKnownItemIds ?? {});

      // Yeni sipariş içindeki ürünler zaten "yeni item" sayılır ama onlar
      // için ayrıca item-level blink göstermiyoruz — order-level highlight
      // yeterli. Sadece MEVCUT (yeni olmayan) bir siparişe eklenen ürünleri
      // item-level blink için ayıklıyoruz.
      final newItemIdsOnExistingOrders = <int>{};
      for (final order in orders) {
        if (newOrderIds.contains(order.id)) continue; // bu zaten yeni sipariş
        for (final item in order.items) {
          if (newItemIds.contains(item.id)) {
            newItemIdsOnExistingOrders.add(item.id);
          }
        }
      }

      final hasNewOrder = newOrderIds.isNotEmpty;
      final hasNewItemOnExisting = newItemIdsOnExistingOrders.isNotEmpty;

      if (hasNewOrder || hasNewItemOnExisting) {
        _playNewOrderSound();

        setState(() {
          _newlyArrivedOrderIds.addAll(newOrderIds);
          _newlyArrivedItemIds.addAll(newItemIdsOnExistingOrders);
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _newlyArrivedOrderIds.removeAll(newOrderIds);
              _newlyArrivedItemIds.removeAll(newItemIdsOnExistingOrders);
            });
          }
        });
      }
    }

    _lastKnownOrderIds = currentOrderIds;
    _lastKnownItemIds = currentItemIds;
  }

  Future<void> _setItemStatus(
    int orderId,
    OrderItemResponseDto item,
    OrderItemStatus status,
  ) async {
    setState(() => _updatingItemIds.add(item.id));
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateItemStatus(orderId: orderId, itemId: item.id, status: status);
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durum güncellenemedi, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingItemIds.remove(item.id));
    }
  }

  Future<void> _advanceStatus(int orderId, OrderItemResponseDto item) async {
    final next = switch (item.status) {
      OrderItemStatus.pending => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      OrderItemStatus.ready => OrderItemStatus.served,
      _ => null,
    };
    if (next == null) return;
    await _setItemStatus(orderId, item, next);
  }

  /// Bir grup (birleştirilmiş) satırdaki tüm ürünleri hedef duruma taşır.
  Future<void> _advanceGroup(int orderId, _ItemGroup group) async {
    final next = switch (group.status) {
      OrderItemStatus.pending => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      OrderItemStatus.ready => OrderItemStatus.served,
      _ => null,
    };
    if (next == null) return;
    await _setGroupStatus(orderId, group, next);
  }

  Future<void> _setGroupStatus(
    int orderId,
    _ItemGroup group,
    OrderItemStatus status,
  ) async {
    setState(() => _updatingItemIds.addAll(group.items.map((i) => i.id)));
    try {
      await Future.wait(
        group.items.map(
          (item) => ref
              .read(orderRepositoryProvider)
              .updateItemStatus(
                orderId: orderId,
                itemId: item.id,
                status: status,
              ),
        ),
      );
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durum güncellenemedi, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () => _updatingItemIds.removeAll(group.items.map((i) => i.id)),
        );
      }
    }
  }

  Future<void> _markWholeOrderReady(OrderResponseDto order) async {
    final pendingItems = order.items
        .where(
          (i) =>
              i.status == OrderItemStatus.pending ||
              i.status == OrderItemStatus.preparing,
        )
        .toList();

    if (pendingItems.isEmpty) return;

    setState(() => _updatingOrderIds.add(order.id));
    try {
      await Future.wait(
        pendingItems.map(
          (item) => ref
              .read(orderRepositoryProvider)
              .updateItemStatus(
                orderId: order.id,
                itemId: item.id,
                status: OrderItemStatus.ready,
              ),
        ),
      );
      ref.invalidate(kitchenOrdersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş güncellenemedi, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderIds.remove(order.id));
    }
  }

  /// Siparişleri hazırlanma durumuna göre sıralar: en az tamamlanmış (en çok
  /// işi kalan) sipariş en üstte gösterilir, eşitlikte en eski sipariş önce gelir.
  /// Bu, mutfağın en çok dikkat gerektiren siparişi ilk görmesini sağlar.
  List<OrderResponseDto> _sortedOrders(List<OrderResponseDto> orders) {
    double completionRatio(OrderResponseDto o) {
      final relevant = o.items
          .where((i) => i.status != OrderItemStatus.cancelled)
          .toList();
      if (relevant.isEmpty) return 1.0;
      final done = relevant
          .where(
            (i) =>
                i.status == OrderItemStatus.ready ||
                i.status == OrderItemStatus.served,
          )
          .length;
      return done / relevant.length;
    }

    final sorted = [...orders];
    sorted.sort((a, b) {
      final ratioCompare = completionRatio(a).compareTo(completionRatio(b));
      if (ratioCompare != 0) return ratioCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    ref.listen(kitchenOrdersProvider, (previous, next) {
      next.whenData(_handleOrdersUpdate);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutfak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(kitchenOrdersProvider),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Bekleyen sipariş yok 🎉')),
                ],
              );
            }
            final sorted = _sortedOrders(orders);
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (context, index) => _OrderCard(
                order: sorted[index],
                updatingItemIds: _updatingItemIds,
                isOrderUpdating: _updatingOrderIds.contains(sorted[index].id),
                isNewlyArrived: _newlyArrivedOrderIds.contains(
                  sorted[index].id,
                ),
                newlyArrivedItemIds: _newlyArrivedItemIds, // ← YENİ
                onAdvance: _advanceStatus,
                onSetStatus: _setItemStatus,
                onAdvanceGroup: _advanceGroup,
                onSetGroupStatus: _setGroupStatus,
                onMarkWholeOrderReady: _markWholeOrderReady,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Görsel gruplama modeli ────────────────────────────────────────────────
// Notu olmayan ve aynı ürün+durumdaki satırları tek satıra indirger.
class _ItemGroup {
  final String menuItemName;
  final String? menuItemImageUrl;
  final OrderItemStatus status;
  final List<OrderItemResponseDto> items;

  _ItemGroup({
    required this.menuItemName,
    required this.menuItemImageUrl,
    required this.status,
    required this.items,
  });

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  bool get hasNote => items.any((i) => i.note != null && i.note!.isNotEmpty);
  bool get isMerged => items.length > 1;
}

List<_ItemGroup> _groupItems(List<OrderItemResponseDto> items) {
  final List<_ItemGroup> result = [];
  final Map<String, int> keyToIndex = {};

  for (final item in items) {
    final hasNote = item.note != null && item.note!.isNotEmpty;

    if (hasNote) {
      // Notlu ürünler asla birleştirilmez — her not ayrı ayrı görünür kalmalı.
      result.add(
        _ItemGroup(
          menuItemName: item.menuItemName,
          menuItemImageUrl: item.menuItemImageUrl,
          status: item.status,
          items: [item],
        ),
      );
      continue;
    }

    final key = '${item.menuItemId}_${item.status}';
    if (keyToIndex.containsKey(key)) {
      result[keyToIndex[key]!].items.add(item);
    } else {
      keyToIndex[key] = result.length;
      result.add(
        _ItemGroup(
          menuItemName: item.menuItemName,
          menuItemImageUrl: item.menuItemImageUrl,
          status: item.status,
          items: [item],
        ),
      );
    }
  }

  return result;
}

// ── Yanıp sönme efekti ──────────────────────────────────────────────────
// Hem yeni sipariş kartı hem de mevcut siparişe eklenen yeni ürün satırı
// için ortak, gerçek anlamda yanıp sönen (opacity/border pulse) bir sarmalayıcı.
class _BlinkingHighlight extends StatefulWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;

  const _BlinkingHighlight({
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<_BlinkingHighlight> createState() => _BlinkingHighlightState();
}

class _BlinkingHighlightState extends State<_BlinkingHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1 arası nabız
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: widget.color.withOpacity(0.35 + 0.55 * t),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.15 + 0.25 * t),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── Sipariş süresi göstergesi ─────────────────────────────────────────────
class _ElapsedBadge extends StatelessWidget {
  final DateTime createdAt;
  const _ElapsedBadge({required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(createdAt.toLocal());
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final label = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final color = elapsed >= _kDangerThreshold
        ? Colors.red
        : elapsed >= _kWarningThreshold
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sipariş kartı ──────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderResponseDto order;
  final Set<int> updatingItemIds;
  final bool isOrderUpdating;
  final bool isNewlyArrived;
  final Set<int> newlyArrivedItemIds; // ← YENİ
  final void Function(int orderId, OrderItemResponseDto item) onAdvance;
  final void Function(
    int orderId,
    OrderItemResponseDto item,
    OrderItemStatus status,
  )
  onSetStatus;
  final void Function(int orderId, _ItemGroup group) onAdvanceGroup;
  final void Function(int orderId, _ItemGroup group, OrderItemStatus status)
  onSetGroupStatus;
  final void Function(OrderResponseDto order) onMarkWholeOrderReady;

  const _OrderCard({
    required this.order,
    required this.updatingItemIds,
    required this.isOrderUpdating,
    required this.isNewlyArrived,
    required this.newlyArrivedItemIds,
    required this.onAdvance,
    required this.onSetStatus,
    required this.onAdvanceGroup,
    required this.onSetGroupStatus,
    required this.onMarkWholeOrderReady,
  });

  @override
  Widget build(BuildContext context) {
    final relevantItems = order.items
        .where((i) => i.status != OrderItemStatus.cancelled)
        .toList();
    final readyCount = relevantItems
        .where(
          (i) =>
              i.status == OrderItemStatus.ready ||
              i.status == OrderItemStatus.served,
        )
        .length;
    final totalCount = relevantItems.length;
    final progress = totalCount == 0 ? 0.0 : readyCount / totalCount;

    final hasUnfinishedItems = order.items.any(
      (i) =>
          i.status == OrderItemStatus.pending ||
          i.status == OrderItemStatus.preparing,
    );

    final groups = _groupItems(order.items);

    final cardContent = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isNewlyArrived) ...[
                  Icon(Icons.fiber_new, color: Colors.amber.shade700, size: 22),
                  const SizedBox(width: 4),
                ],
                Text(
                  'Masa ${order.tableNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _ElapsedBadge(createdAt: order.createdAt),
                const SizedBox(width: 8),
                Text(
                  '#${order.id}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Not: ${order.note}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // --- X/Y ÜRÜN HAZIR GÖSTERGESİ ---
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$readyCount/$totalCount hazır',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const Divider(),

            ...groups.map((group) {
              final groupIsNewlyArrived = group.items.any(
                (i) => newlyArrivedItemIds.contains(i.id),
              );
              return _ItemRow(
                orderId: order.id,
                group: group,
                isUpdating: group.items.any(
                  (i) => updatingItemIds.contains(i.id),
                ),
                isNewlyArrived: groupIsNewlyArrived, // ← YENİ
                onAdvance: () => onAdvanceGroup(order.id, group),
                onSetStatus: (status) =>
                    onSetGroupStatus(order.id, group, status),
              );
            }),

            if (hasUnfinishedItems) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isOrderUpdating
                      ? null
                      : () => onMarkWholeOrderReady(order),
                  icon: isOrderUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all, size: 18),
                  label: Text(
                    isOrderUpdating
                        ? 'Güncelleniyor...'
                        : 'Siparişin Tamamı Hazır',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isNewlyArrived
          ? _BlinkingHighlight(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int orderId;
  final _ItemGroup group;
  final bool isUpdating;
  final bool isNewlyArrived; // ← YENİ
  final VoidCallback onAdvance;
  final void Function(OrderItemStatus status) onSetStatus;

  const _ItemRow({
    required this.orderId,
    required this.group,
    required this.isUpdating,
    required this.isNewlyArrived,
    required this.onAdvance,
    required this.onSetStatus,
  });

  (String, Color) _statusLabel(OrderItemStatus status) => switch (status) {
    OrderItemStatus.pending => ('Bekliyor', Colors.grey),
    OrderItemStatus.preparing => ('Hazırlanıyor', Colors.orange),
    OrderItemStatus.ready => ('Hazır', Colors.blue),
    OrderItemStatus.served => ('Servis Edildi', Colors.green),
    OrderItemStatus.cancelled => ('İptal', Colors.red),
  };

  String? _nextActionLabel(OrderItemStatus status) => switch (status) {
    OrderItemStatus.pending => 'Hazırlanmaya Başla',
    OrderItemStatus.preparing => 'Hazır',
    OrderItemStatus.ready => 'Servis Edildi',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusLabel(group.status);
    final actionLabel = _nextActionLabel(group.status);
    final hasNote = group.hasNote;
    final hasImage =
        group.menuItemImageUrl != null && group.menuItemImageUrl!.isNotEmpty;

    // --- HAZIR/SERVİS EDİLDİ OLAN ÜRÜNLER GRİLEŞTİRİLİR ---
    final isDone =
        group.status == OrderItemStatus.ready ||
        group.status == OrderItemStatus.served;

    final rowContent = Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(hasNote ? 8 : 4),
        decoration: hasNote
            ? BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNewlyArrived) ...[
              Icon(Icons.fiber_new, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 4),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: group.menuItemImageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.fastfood,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.fastfood,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${group.totalQuantity}x ${group.menuItemName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (group.isMerged)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${group.items.length} satır',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (hasNote) ...[
                    const SizedBox(height: 4),
                    ...group.items
                        .where((i) => i.note != null && i.note!.isNotEmpty)
                        .map(
                          (i) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.priority_high_rounded,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  i.note!,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],

                  const SizedBox(height: 6),

                  PopupMenuButton<OrderItemStatus>(
                    onSelected: onSetStatus,
                    itemBuilder: (context) => OrderItemStatus.values
                        .where((s) => s != group.status)
                        .map((s) {
                          final (l, c) = _statusLabel(s);
                          return PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(l),
                              ],
                            ),
                          );
                        })
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 16, color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              FilledButton(
                onPressed: isUpdating ? null : onAdvance,
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(actionLabel),
              ),
          ],
        ),
      ),
    );

    return isNewlyArrived
        ? _BlinkingHighlight(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(8),
            child: rowContent,
          )
        : rowContent;
  }
}
