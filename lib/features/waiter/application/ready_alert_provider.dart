import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tap_table_staff/features/orders/data/order_repository.dart';

import '../../orders/application/order_providers.dart';
import '../../orders/data/order_models.dart';

/// Mutfakta "Hazır" (Ready) durumuna geçen ürünleri masa bazında izler.
/// Bir masada en az bir Ready ürün varsa o masa "parlıyor" (flashing)
/// sayılır. Garsonun masaya tıklaması/girmesi parlamayı etkilemez —
/// parlama SADECE o masadaki tüm Ready ürünler Served olduğunda
/// (yani backend'de teslim işaretlendiğinde) kalkar.
///
/// Görüldü/acknowledge kavramı tamamen kaldırıldı; state artık hiçbir
/// yerel hafızaya değil, doğrudan sunucudan gelen OrderItemStatus'a bağlı.
///
/// NOT: Bu implementasyon polling (5sn) ile çalışıyor. Backend'de SignalR
/// (OrderHub) zaten var — eğer staff app'te buna bağlanan bir client
/// mevcutsa, bu polling'i "OrderItemStatusChanged" event'ine bağlamak
/// çok daha verimli olur.
class ReadyAlertNotifier extends StateNotifier<Set<int>> {
  final OrderRepository _repository;
  Timer? _timer;

  ReadyAlertNotifier(this._repository) : super(const {}) {
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final orders = await _repository.getOrders();

      final Set<int> flashing = {};
      for (final order in orders) {
        final hasReadyItem = order.items.any(
          (i) => i.status == OrderItemStatus.ready,
        );
        if (hasReadyItem) flashing.add(order.tableId);
      }

      if (mounted) state = flashing;
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
  return ReadyAlertNotifier(repository);
});
