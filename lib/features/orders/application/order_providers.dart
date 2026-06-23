import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/providers.dart';
import '../data/order_models.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

/// Mutfağın ilgilenmesi gereken siparişler: en az bir ürünü Pending/Preparing olanlar.
/// Order.Status alanına güvenmiyoruz — o alan sadece Waiter/Admin tarafından elle
/// güncelleniyor, mutfak için gerçek kaynak ürün bazlı (OrderItem.Status) durum.
final kitchenOrdersProvider = FutureProvider.autoDispose<List<OrderResponseDto>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  final orders = await repository.getOrders();

  final active = orders.where((order) {
    return order.items.any((item) =>
        item.status == OrderItemStatus.pending || item.status == OrderItemStatus.preparing);
  }).toList();

  active.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // en eski sipariş üstte
  return active;
});