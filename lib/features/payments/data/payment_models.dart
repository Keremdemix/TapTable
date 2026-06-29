import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_models.freezed.dart';
part 'payment_models.g.dart';

double _toDouble(dynamic value) => (value as num).toDouble();

enum PaymentMethodType {
  @JsonValue('Cash') cash,
  @JsonValue('Card') card,
  @JsonValue('Iyzico') iyzico,
}

@freezed
class PaymentResponseDto with _$PaymentResponseDto {
  const factory PaymentResponseDto({
    required int id,
    required int orderId,
    @JsonKey(fromJson: _toDouble) required double amount,
    required String method,
    required String splitType,
    required String status,
    String? iyzicoPaymentId,
    required DateTime createdAt,
  }) = _PaymentResponseDto;

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseDtoFromJson(json);
}