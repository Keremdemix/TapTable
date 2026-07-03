import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../menu/menu_models.dart';
import 'cart_models.dart';

class CartNotifier extends StateNotifier<Map<int, CartLine>> {
  CartNotifier() : super({});

  void add(PublicMenuItem item) {
    final existing = state[item.id];
    state = {
      ...state,
      item.id: existing == null
          ? CartLine(item: item, quantity: 1)
          : existing.copyWith(quantity: existing.quantity + 1),
    };
  }

  void decrement(int itemId) {
    final existing = state[itemId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      final next = {...state}..remove(itemId);
      state = next;
    } else {
      state = {...state, itemId: existing.copyWith(quantity: existing.quantity - 1)};
    }
  }
 
  void remove(int itemId) {
  final next = {...state}..remove(itemId);
  state = next;
}

  void clear() => state = {};

  int get totalCount => state.values.fold(0, (sum, l) => sum + l.quantity);
  double get totalPrice => state.values.fold(0, (sum, l) => sum + l.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, CartLine>>(
  (ref) => CartNotifier(),
);

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, l) => sum + l.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, l) => sum + l.total);
});