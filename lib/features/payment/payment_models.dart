class PaymentStateItem {
  final int orderItemId;
  final String menuItemName;
  final double unitPrice;
  final int quantity;
  final int paidQuantity;

  PaymentStateItem({
    required this.orderItemId,
    required this.menuItemName,
    required this.unitPrice,
    required this.quantity,
    required this.paidQuantity,
  });

  int get unpaidQuantity => quantity - paidQuantity;
  double get lineTotal => unitPrice * quantity;
  double get unpaidLineTotal => unitPrice * unpaidQuantity;

  factory PaymentStateItem.fromJson(Map<String, dynamic> json) {
    return PaymentStateItem(
      orderItemId: json['orderItemId'] as int,
      menuItemName: json['menuItemName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      paidQuantity: json['paidQuantity'] as int,
    );
  }
}

class SplitPaymentPlan {
  final int id;
  final int totalPeople;
  final double totalAmount;
  final int sharesPaid;
  final String status;

  SplitPaymentPlan({
    required this.id,
    required this.totalPeople,
    required this.totalAmount,
    required this.sharesPaid,
    required this.status,
  });

  double get amountPerPerson =>
      totalPeople == 0 ? 0 : totalAmount / totalPeople;
  int get remainingShares => totalPeople - sharesPaid;
  bool get isActive => status == 'Active';

  factory SplitPaymentPlan.fromJson(Map<String, dynamic> json) {
    return SplitPaymentPlan(
      id: json['id'] as int,
      totalPeople: json['totalPeople'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      sharesPaid: json['sharesPaid'] as int,
      status: json['status'] as String,
    );
  }
}

class OrderPaymentState {
  final int orderId;
  final double totalPrice;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final List<PaymentStateItem> items;
  final SplitPaymentPlan? activeSplitPlan;

  OrderPaymentState({
    required this.orderId,
    required this.totalPrice,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.items,
    this.activeSplitPlan,
  });

  bool get isFullyPaid => paymentStatus == 'Paid';
  bool get hasActiveSplitPlan =>
      activeSplitPlan != null && activeSplitPlan!.isActive;

  factory OrderPaymentState.fromJson(Map<String, dynamic> json) {
    return OrderPaymentState(
      orderId: json['orderId'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      items: (json['items'] as List)
          .map((i) => PaymentStateItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      activeSplitPlan: json['activeSplitPlan'] == null
          ? null
          : SplitPaymentPlan.fromJson(
              json['activeSplitPlan'] as Map<String, dynamic>,
            ),
    );
  }
}

class PaymentResult {
  final int id;
  final int orderId;
  final double amount;
  final String method;
  final String splitType;
  final String status;
  final String? iyzicoPaymentId;
  final DateTime createdAt;

  PaymentResult({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.splitType,
    required this.status,
    this.iyzicoPaymentId,
    required this.createdAt,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      splitType: json['splitType'] as String,
      status: json['status'] as String,
      iyzicoPaymentId: json['iyzicoPaymentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class IyzicoCheckoutResult {
  final int paymentId;
  final String token;
  final String paymentPageUrl;

  IyzicoCheckoutResult({
    required this.paymentId,
    required this.token,
    required this.paymentPageUrl,
  });

  factory IyzicoCheckoutResult.fromJson(Map<String, dynamic> json) {
    return IyzicoCheckoutResult(
      paymentId: json['paymentId'] as int,
      token: json['token'] as String,
      paymentPageUrl: json['paymentPageUrl'] as String,
    );
  }
}
