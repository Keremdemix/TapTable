// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentResponseDtoImpl _$$PaymentResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PaymentResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  orderId: (json['orderId'] as num).toInt(),
  amount: _toDouble(json['amount']),
  method: json['method'] as String,
  splitType: json['splitType'] as String,
  status: json['status'] as String,
  iyzicoPaymentId: json['iyzicoPaymentId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$PaymentResponseDtoImplToJson(
  _$PaymentResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'method': instance.method,
  'splitType': instance.splitType,
  'status': instance.status,
  'iyzicoPaymentId': instance.iyzicoPaymentId,
  'createdAt': instance.createdAt.toIso8601String(),
};
