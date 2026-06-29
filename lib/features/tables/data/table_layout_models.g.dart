// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_layout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableLayoutResponseDtoImpl _$$TableLayoutResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TableLayoutResponseDtoImpl(
  tableId: (json['tableId'] as num).toInt(),
  tableNumber: (json['tableNumber'] as num).toInt(),
  capacity: (json['capacity'] as num).toInt(),
  status: $enumDecode(_$TableStatusEnumMap, json['status']),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  shape: json['shape'] as String,
  positionX: (json['positionX'] as num).toInt(),
  positionY: (json['positionY'] as num).toInt(),
);

Map<String, dynamic> _$$TableLayoutResponseDtoImplToJson(
  _$TableLayoutResponseDtoImpl instance,
) => <String, dynamic>{
  'tableId': instance.tableId,
  'tableNumber': instance.tableNumber,
  'capacity': instance.capacity,
  'status': _$TableStatusEnumMap[instance.status]!,
  'width': instance.width,
  'height': instance.height,
  'shape': instance.shape,
  'positionX': instance.positionX,
  'positionY': instance.positionY,
};

const _$TableStatusEnumMap = {
  TableStatus.available: 'Available',
  TableStatus.occupied: 'Occupied',
  TableStatus.reserved: 'Reserved',
  TableStatus.outOfService: 'OutOfService',
};
