// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PaymentResponseDto _$PaymentResponseDtoFromJson(Map<String, dynamic> json) {
  return _PaymentResponseDto.fromJson(json);
}

/// @nodoc
mixin _$PaymentResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get orderId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDouble)
  double get amount => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String get splitType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get iyzicoPaymentId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PaymentResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentResponseDtoCopyWith<PaymentResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentResponseDtoCopyWith<$Res> {
  factory $PaymentResponseDtoCopyWith(
    PaymentResponseDto value,
    $Res Function(PaymentResponseDto) then,
  ) = _$PaymentResponseDtoCopyWithImpl<$Res, PaymentResponseDto>;
  @useResult
  $Res call({
    int id,
    int orderId,
    @JsonKey(fromJson: _toDouble) double amount,
    String method,
    String splitType,
    String status,
    String? iyzicoPaymentId,
    DateTime createdAt,
  });
}

/// @nodoc
class _$PaymentResponseDtoCopyWithImpl<$Res, $Val extends PaymentResponseDto>
    implements $PaymentResponseDtoCopyWith<$Res> {
  _$PaymentResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? amount = null,
    Object? method = null,
    Object? splitType = null,
    Object? status = null,
    Object? iyzicoPaymentId = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as int,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            splitType: null == splitType
                ? _value.splitType
                : splitType // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            iyzicoPaymentId: freezed == iyzicoPaymentId
                ? _value.iyzicoPaymentId
                : iyzicoPaymentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentResponseDtoImplCopyWith<$Res>
    implements $PaymentResponseDtoCopyWith<$Res> {
  factory _$$PaymentResponseDtoImplCopyWith(
    _$PaymentResponseDtoImpl value,
    $Res Function(_$PaymentResponseDtoImpl) then,
  ) = __$$PaymentResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int orderId,
    @JsonKey(fromJson: _toDouble) double amount,
    String method,
    String splitType,
    String status,
    String? iyzicoPaymentId,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$PaymentResponseDtoImplCopyWithImpl<$Res>
    extends _$PaymentResponseDtoCopyWithImpl<$Res, _$PaymentResponseDtoImpl>
    implements _$$PaymentResponseDtoImplCopyWith<$Res> {
  __$$PaymentResponseDtoImplCopyWithImpl(
    _$PaymentResponseDtoImpl _value,
    $Res Function(_$PaymentResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? amount = null,
    Object? method = null,
    Object? splitType = null,
    Object? status = null,
    Object? iyzicoPaymentId = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$PaymentResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        splitType: null == splitType
            ? _value.splitType
            : splitType // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        iyzicoPaymentId: freezed == iyzicoPaymentId
            ? _value.iyzicoPaymentId
            : iyzicoPaymentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentResponseDtoImpl implements _PaymentResponseDto {
  const _$PaymentResponseDtoImpl({
    required this.id,
    required this.orderId,
    @JsonKey(fromJson: _toDouble) required this.amount,
    required this.method,
    required this.splitType,
    required this.status,
    this.iyzicoPaymentId,
    required this.createdAt,
  });

  factory _$PaymentResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int orderId;
  @override
  @JsonKey(fromJson: _toDouble)
  final double amount;
  @override
  final String method;
  @override
  final String splitType;
  @override
  final String status;
  @override
  final String? iyzicoPaymentId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PaymentResponseDto(id: $id, orderId: $orderId, amount: $amount, method: $method, splitType: $splitType, status: $status, iyzicoPaymentId: $iyzicoPaymentId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.splitType, splitType) ||
                other.splitType == splitType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.iyzicoPaymentId, iyzicoPaymentId) ||
                other.iyzicoPaymentId == iyzicoPaymentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    orderId,
    amount,
    method,
    splitType,
    status,
    iyzicoPaymentId,
    createdAt,
  );

  /// Create a copy of PaymentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentResponseDtoImplCopyWith<_$PaymentResponseDtoImpl> get copyWith =>
      __$$PaymentResponseDtoImplCopyWithImpl<_$PaymentResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentResponseDtoImplToJson(this);
  }
}

abstract class _PaymentResponseDto implements PaymentResponseDto {
  const factory _PaymentResponseDto({
    required final int id,
    required final int orderId,
    @JsonKey(fromJson: _toDouble) required final double amount,
    required final String method,
    required final String splitType,
    required final String status,
    final String? iyzicoPaymentId,
    required final DateTime createdAt,
  }) = _$PaymentResponseDtoImpl;

  factory _PaymentResponseDto.fromJson(Map<String, dynamic> json) =
      _$PaymentResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get orderId;
  @override
  @JsonKey(fromJson: _toDouble)
  double get amount;
  @override
  String get method;
  @override
  String get splitType;
  @override
  String get status;
  @override
  String? get iyzicoPaymentId;
  @override
  DateTime get createdAt;

  /// Create a copy of PaymentResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentResponseDtoImplCopyWith<_$PaymentResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
