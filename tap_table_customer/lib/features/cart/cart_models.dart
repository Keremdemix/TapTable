import 'package:tap_table_customer/features/menu/menu_models.dart';

class CartLine {
  final PublicMenuItem item;
  final int quantity;
  final String? note;

  CartLine({required this.item, required this.quantity, this.note});

  double get total => item.price * quantity;

  CartLine copyWith({int? quantity, String? note}) => CartLine(
    item: item,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
  );

  /// note'u temizlemek için (copyWith'te null geçince eski değer korunur, o yüzden ayrı metod)
  CartLine clearNote() => CartLine(item: item, quantity: quantity, note: null);
}
