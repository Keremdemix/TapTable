// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableResponseDtoImpl _$$TableResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TableResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  restaurantId: (json['restaurantId'] as num).toInt(),
  tableNumber: (json['tableNumber'] as num).toInt(),
  capacity: (json['capacity'] as num).toInt(),
  qrCodeUrl: json['qrCodeUrl'] as String,
  status: $enumDecode(_$TableStatusEnumMap, json['status']),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$TableResponseDtoImplToJson(
  _$TableResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurantId': instance.restaurantId,
  'tableNumber': instance.tableNumber,
  'capacity': instance.capacity,
  'qrCodeUrl': instance.qrCodeUrl,
  'status': _$TableStatusEnumMap[instance.status]!,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$TableStatusEnumMap = {
  TableStatus.available: 'Available',
  TableStatus.occupied: 'Occupied',
  TableStatus.reserved: 'Reserved',
  TableStatus.outOfService: 'OutOfService',
};

_$RegenerateQrResponseDtoImpl _$$RegenerateQrResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$RegenerateQrResponseDtoImpl(
  tableId: (json['tableId'] as num).toInt(),
  tableNumber: (json['tableNumber'] as num).toInt(),
  qrCodeUrl: json['qrCodeUrl'] as String,
  newSessionKey: json['newSessionKey'] as String,
);

Map<String, dynamic> _$$RegenerateQrResponseDtoImplToJson(
  _$RegenerateQrResponseDtoImpl instance,
) => <String, dynamic>{
  'tableId': instance.tableId,
  'tableNumber': instance.tableNumber,
  'qrCodeUrl': instance.qrCodeUrl,
  'newSessionKey': instance.newSessionKey,
};
