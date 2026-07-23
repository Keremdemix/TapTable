import 'dart:async';

import '../../tables/application/table_providers.dart' show tableLayoutProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/orders/data/order_repository.dart';

import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';
import '../presentation/waiter_table_detail_screen.dart'
    show tableActiveOrderProvider;

/// Masa çerçeve renginin hangi "iş kuralı" durumundan kaynaklandığını ifade
/// eder. TableShapeWidget bunu status'a ek olarak dikkate alır.
enum TableAlertState {
  /// Aktif siparişte ödeme Paid ama (iptal hariç) tüm ürünler henüz
  /// Served değil — masa "kırmızı" gösterilmeli.
  paidNotServed,

  /// Özel bir durum yok — masa rengi sadece TableStatus'a göre belirlenir.
  none,
}

/// Mutfakta "Hazır" (Ready) durumuna geçen ürünleri masa bazında izler ve
/// aynı pollingden masa çerçeve renk durumunu da (ödendi-ama-teslim-edilmedi)
/// üretir.
///
/// - readyAlertProvider (state): en az bir Ready ürünü olan masaların
///   kümesi — o masa parlar, tüm Ready ürünler Served olana kadar sürer.
/// - tableAlertStateProvider: masa bazlı [TableAlertState] haritası —
///   şu an sadece "ödendi ama teslim edilmedi" (kırmızı) durumunu taşıyor,
///   ileride başka kurallar eklenebilir.
///
/// Her iki state de aynı 5sn'lik pollingden besleniyor, böylece ekran açık
/// kaldığı sürece hem parlama hem masa rengi otomatik güncel kalır.
///
/// NOT: Backend'de SignalR (OrderHub) zaten var — bu polling'i onun
/// "OrderItemStatusChanged" event'ine bağlamak çok daha verimli olur.
class ReadyAlertNotifier extends StateNotifier<Set<int>> {
  final OrderRepository _repository;
  final Ref _ref;
  Timer? _timer;

  /// tableId -> son pollde görülen ready orderItem id'leri. Sadece açık
  /// ekranların sipariş verisini (tableActiveOrderProvider) invalidate
  /// edip etmeyeceğimize karar vermek için önceki durumla kıyaslanır.
  Map<int, Set<int>> _previousReadyItemIds = {};

  ReadyAlertNotifier(this._repository, this._ref) : super(const {}) {
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final orders = await _repository.getOrders();

      final Map<int, Set<int>> readyByTable = {};
      final Map<int, TableAlertState> alertByTable = {};

      for (final order in orders) {
        if (order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled) {
          continue;
        }

        final readyItemIds = order.items
            .where((i) => i.status == OrderItemStatus.ready)
            .map((i) => i.id)
            .toSet();
        if (readyItemIds.isNotEmpty) {
          readyByTable
              .putIfAbsent(order.tableId, () => <int>{})
              .addAll(readyItemIds);
        }

        final relevant = order.items
            .where((i) => i.status != OrderItemStatus.cancelled)
            .toList();
        final allServed =
            relevant.isNotEmpty &&
            relevant.every((i) => i.status == OrderItemStatus.served);

        if (order.paymentStatus == OrderPaymentStatus.paid && !allServed) {
          alertByTable[order.tableId] = TableAlertState.paidNotServed;
        }
      }

      // Ready ürün kümesi öncekine göre değişen (yeni ürün eklenen ya da
      // teslim sonrası boşalan) her masa için sipariş provider'ını
      // invalidate et — açık ekranlar otomatik güncellensin.
      final allTableIds = {...readyByTable.keys, ..._previousReadyItemIds.keys};
      for (final tableId in allTableIds) {
        final previous = _previousReadyItemIds[tableId] ?? const <int>{};
        final current = readyByTable[tableId] ?? const <int>{};
        if (!setEquals(previous, current)) {
          _ref.invalidate(tableActiveOrderProvider(tableId));
        }
      }
      _previousReadyItemIds = readyByTable;

      _ref.read(tableAlertStateProvider.notifier).state = alertByTable;
      _ref.invalidate(tableLayoutProvider);

      if (mounted) state = readyByTable.keys.toSet();
    } catch (_) {
      // Sessizce yut — bir sonraki pollde tekrar denenecek.
    }
  }

  /// Garson "Teslim Edildi" işlemini yaptıktan hemen sonra, 5sn'lik poll
  /// beklemeden UI'ın anında güncellenmesi için çağrılır.
  Future<void> refresh() => _poll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final readyAlertProvider = StateNotifierProvider<ReadyAlertNotifier, Set<int>>((
  ref,
) {
  final repository = ref.watch(orderRepositoryProvider);
  return ReadyAlertNotifier(repository, ref);
});

/// tableId -> TableAlertState. ReadyAlertNotifier tarafından her pollde
/// güncellenir; haritada olmayan masalar için TableAlertState.none kabul
/// edilmelidir (bkz. tableAlertStateProvider'ın kullanıldığı widget'larda
/// `?? TableAlertState.none`).
final tableAlertStateProvider = StateProvider<Map<int, TableAlertState>>(
  (ref) => const {},
);
