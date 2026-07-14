import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_models.freezed.dart';
part 'table_models.g.dart';

enum TableStatus {
  @JsonValue('Available') available,
  @JsonValue('Occupied') occupied,
  @JsonValue('Reserved') reserved,
  @JsonValue('OutOfService') outOfService,
}

@freezed
class TableResponseDto with _$TableResponseDto {
  const factory TableResponseDto({
    required int id,
    required int restaurantId,
    required int tableNumber,
    required int capacity,
    required String qrCodeUrl,
    required TableStatus status,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _TableResponseDto;

  factory TableResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TableResponseDtoFromJson(json);
}

@freezed
class RegenerateQrResponseDto with _$RegenerateQrResponseDto {
  const factory RegenerateQrResponseDto({
    required int tableId,
    required int tableNumber,
    required String qrCodeUrl,
    required String newSessionKey,
  }) = _RegenerateQrResponseDto;

  factory RegenerateQrResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegenerateQrResponseDtoFromJson(json);
}