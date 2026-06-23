// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderItemResponseDtoImpl _$$OrderItemResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$OrderItemResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  menuItemId: (json['menuItemId'] as num).toInt(),
  menuItemName: json['menuItemName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: _toDouble(json['unitPrice']),
  lineTotal: _toDouble(json['lineTotal']),
  note: json['note'] as String?,
  status: $enumDecode(_$OrderItemStatusEnumMap, json['status']),
);

Map<String, dynamic> _$$OrderItemResponseDtoImplToJson(
  _$OrderItemResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'menuItemId': instance.menuItemId,
  'menuItemName': instance.menuItemName,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'lineTotal': instance.lineTotal,
  'note': instance.note,
  'status': _$OrderItemStatusEnumMap[instance.status]!,
};

const _$OrderItemStatusEnumMap = {
  OrderItemStatus.pending: 'Pending',
  OrderItemStatus.preparing: 'Preparing',
  OrderItemStatus.ready: 'Ready',
  OrderItemStatus.served: 'Served',
  OrderItemStatus.cancelled: 'Cancelled',
};

_$OrderResponseDtoImpl _$$OrderResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$OrderResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  tableId: (json['tableId'] as num).toInt(),
  tableNumber: (json['tableNumber'] as num).toInt(),
  waiterId: (json['waiterId'] as num?)?.toInt(),
  waiterName: json['waiterName'] as String?,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  paymentStatus: $enumDecode(
    _$OrderPaymentStatusEnumMap,
    json['paymentStatus'],
  ),
  totalPrice: _toDouble(json['totalPrice']),
  note: json['note'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItemResponseDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$OrderResponseDtoImplToJson(
  _$OrderResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'tableId': instance.tableId,
  'tableNumber': instance.tableNumber,
  'waiterId': instance.waiterId,
  'waiterName': instance.waiterName,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'paymentStatus': _$OrderPaymentStatusEnumMap[instance.paymentStatus]!,
  'totalPrice': instance.totalPrice,
  'note': instance.note,
  'items': instance.items,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'Pending',
  OrderStatus.preparing: 'Preparing',
  OrderStatus.ready: 'Ready',
  OrderStatus.served: 'Served',
  OrderStatus.completed: 'Completed',
  OrderStatus.cancelled: 'Cancelled',
};

const _$OrderPaymentStatusEnumMap = {
  OrderPaymentStatus.unpaid: 'Unpaid',
  OrderPaymentStatus.partiallyPaid: 'PartiallyPaid',
  OrderPaymentStatus.paid: 'Paid',
};
