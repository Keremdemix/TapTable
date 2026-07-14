// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryResponseDtoImpl _$$CategoryResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CategoryResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  restaurantId: (json['restaurantId'] as num).toInt(),
  name: json['name'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  isActive: json['isActive'] as bool,
  menuItemCount: (json['menuItemCount'] as num).toInt(),
);

Map<String, dynamic> _$$CategoryResponseDtoImplToJson(
  _$CategoryResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurantId': instance.restaurantId,
  'name': instance.name,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
  'menuItemCount': instance.menuItemCount,
};

_$MenuItemResponseDtoImpl _$$MenuItemResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$MenuItemResponseDtoImpl(
  id: (json['id'] as num).toInt(),
  categoryId: (json['categoryId'] as num).toInt(),
  categoryName: json['categoryName'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String?,
  isAvailable: json['isAvailable'] as bool,
  isActive: json['isActive'] as bool,
  sortOrder: (json['sortOrder'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$MenuItemResponseDtoImplToJson(
  _$MenuItemResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
  'isAvailable': instance.isAvailable,
  'isActive': instance.isActive,
  'sortOrder': instance.sortOrder,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
