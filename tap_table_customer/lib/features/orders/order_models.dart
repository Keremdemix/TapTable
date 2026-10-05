class OrderItemResponse {
  final int id;
  final int menuItemId;
  final String menuItemName;
  final String? menuItemImageUrl; // ← eklendi
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? note;
  final String status;

  OrderItemResponse({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    this.menuItemImageUrl, // ← eklendi
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note,
    required this.status,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'] as int,
      menuItemId: json['menuItemId'] as int,
      menuItemName: json['menuItemName'] as String,
      menuItemImageUrl: json['menuItemImageUrl'] as String?, // ← eklendi
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      note: json['note'] as String?,
      status: json['status'] as String,
    );
  }
}

class OrderResponse {
  final int id;
  final int tableId;
  final int tableNumber;
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final String? note;
  final List<OrderItemResponse> items;
  final DateTime createdAt;

  OrderResponse({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    this.note,
    required this.items,
    required this.createdAt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      tableId: json['tableId'] as int,
      tableNumber: json['tableNumber'] as int,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      note: json['note'] as String?,
      items: (json['items'] as List)
          .map((i) => OrderItemResponse.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Backend enum'larıyla birebir — Türkçe etiketler burada tutuluyor.
String orderStatusLabel(String status) {
  switch (status) {
    case 'Pending':
      return 'Sipariş Alındı';
    case 'Preparing':
      return 'Hazırlanıyor';
    case 'Ready':
      return 'Hazır';
    case 'Served':
      return 'Servis Edildi';
    case 'Completed':
      return 'Tamamlandı';
    case 'Cancelled':
      return 'İptal Edildi';
    default:
      return status;
  }
}