import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_models.freezed.dart';
part 'menu_models.g.dart';

@freezed
class CategoryResponseDto with _$CategoryResponseDto {
  const factory CategoryResponseDto({
    required int id,
    required int restaurantId,
    required String name,
    required int sortOrder,
    required bool isActive,
    required int menuItemCount,
  }) = _CategoryResponseDto;

  factory CategoryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseDtoFromJson(json);
}

@freezed
class MenuItemResponseDto with _$MenuItemResponseDto {
  const factory MenuItemResponseDto({
    required int id,
    required int categoryId,
    required String categoryName,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    required bool isAvailable,
    required bool isActive,
    required int sortOrder,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MenuItemResponseDto;

  factory MenuItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MenuItemResponseDtoFromJson(json);
}
