import 'package:freezed_annotation/freezed_annotation.dart';
import 'table_models.dart'; // TableStatus enum'ı buradan tekrar kullanılıyor

part 'table_layout_models.freezed.dart';
part 'table_layout_models.g.dart';

@freezed
class TableLayoutResponseDto with _$TableLayoutResponseDto {
  const factory TableLayoutResponseDto({
    required int tableId,
    required int tableNumber,
    required int capacity,
    required TableStatus status,
    required int width,
    required int height,
    required String shape,
    required int positionX,
    required int positionY,
  }) = _TableLayoutResponseDto;

  factory TableLayoutResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TableLayoutResponseDtoFromJson(json);
}

class UpdateTableLayoutItemInput {
  final int tableId;
  final int positionX;
  final int positionY;
  final int width;
  final int height;
  final String shape;

  UpdateTableLayoutItemInput({
    required this.tableId,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.shape,
  });

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'positionX': positionX,
        'positionY': positionY,
        'width': width,
        'height': height,
        'shape': shape,
      };
}