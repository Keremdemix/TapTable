import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_models.freezed.dart';
part 'order_models.g.dart';

double _toDouble(dynamic value) => (value as num).toDouble();

enum OrderItemStatus {
  @JsonValue('Pending') pending,
  @JsonValue('Preparing') preparing,
  @JsonValue('Ready') ready,
  @JsonValue('Served') served,
  @JsonValue('Cancelled') cancelled,
}

enum OrderStatus {
  @JsonValue('Pending') pending,
  @JsonValue('Preparing') preparing,
  @JsonValue('Ready') ready,
  @JsonValue('Served') served,
  @JsonValue('Completed') completed,
  @JsonValue('Cancelled') cancelled,
}

enum OrderPaymentStatus {
  @JsonValue('Unpaid') unpaid,
  @JsonValue('PartiallyPaid') partiallyPaid,
  @JsonValue('Paid') paid,
}

@freezed
class OrderItemResponseDto with _$OrderItemResponseDto {
  const factory OrderItemResponseDto({
    required int id,
    required int menuItemId,
    required String menuItemName,
    required int quantity,
    @JsonKey(fromJson: _toDouble) required double unitPrice,
    @JsonKey(fromJson: _toDouble) required double lineTotal,
    String? note,
    required OrderItemStatus status,
  }) = _OrderItemResponseDto;

  factory OrderItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemResponseDtoFromJson(json);
}

@freezed
class OrderResponseDto with _$OrderResponseDto {
  const factory OrderResponseDto({
    required int id,
    required int tableId,
    required int tableNumber,
    int? waiterId,
    String? waiterName,
    required OrderStatus status,
    required OrderPaymentStatus paymentStatus,
    @JsonKey(fromJson: _toDouble) required double totalPrice,
    String? note,
    required List<OrderItemResponseDto> items,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _OrderResponseDto;

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseDtoFromJson(json);
}