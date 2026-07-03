import 'package:tap_table_customer/features/menu/menu_models.dart';

class CartLine {
  final PublicMenuItem item;
  final int quantity;

  CartLine({required this.item, required this.quantity});

  double get total => item.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(item: item, quantity: quantity ?? this.quantity);
}