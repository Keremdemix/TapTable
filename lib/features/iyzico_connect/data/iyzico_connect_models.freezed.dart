// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iyzico_connect_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IyzicoSubMerchantStatusDto _$IyzicoSubMerchantStatusDtoFromJson(
  Map<String, dynamic> json,
) {
  return _IyzicoSubMerchantStatusDto.fromJson(json);
}

/// @nodoc
mixin _$IyzicoSubMerchantStatusDto {
  bool get hasSubMerchant => throw _privateConstructorUsedError;
  bool get isApproved => throw _privateConstructorUsedError;

  /// Serializes this IyzicoSubMerchantStatusDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IyzicoSubMerchantStatusDtoCopyWith<IyzicoSubMerchantStatusDto>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IyzicoSubMerchantStatusDtoCopyWith<$Res> {
  factory $IyzicoSubMerchantStatusDtoCopyWith(
    IyzicoSubMerchantStatusDto value,
    $Res Function(IyzicoSubMerchantStatusDto) then,
  ) =
      _$IyzicoSubMerchantStatusDtoCopyWithImpl<
        $Res,
        IyzicoSubMerchantStatusDto
      >;
  @useResult
  $Res call({bool hasSubMerchant, bool isApproved});
}

/// @nodoc
class _$IyzicoSubMerchantStatusDtoCopyWithImpl<
  $Res,
  $Val extends IyzicoSubMerchantStatusDto
>
    implements $IyzicoSubMerchantStatusDtoCopyWith<$Res> {
  _$IyzicoSubMerchantStatusDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? hasSubMerchant = null, Object? isApproved = null}) {
    return _then(
      _value.copyWith(
            hasSubMerchant: null == hasSubMerchant
                ? _value.hasSubMerchant
                : hasSubMerchant // ignore: cast_nullable_to_non_nullable
                      as bool,
            isApproved: null == isApproved
                ? _value.isApproved
                : isApproved // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IyzicoSubMerchantStatusDtoImplCopyWith<$Res>
    implements $IyzicoSubMerchantStatusDtoCopyWith<$Res> {
  factory _$$IyzicoSubMerchantStatusDtoImplCopyWith(
    _$IyzicoSubMerchantStatusDtoImpl value,
    $Res Function(_$IyzicoSubMerchantStatusDtoImpl) then,
  ) = __$$IyzicoSubMerchantStatusDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool hasSubMerchant, bool isApproved});
}

/// @nodoc
class __$$IyzicoSubMerchantStatusDtoImplCopyWithImpl<$Res>
    extends
        _$IyzicoSubMerchantStatusDtoCopyWithImpl<
          $Res,
          _$IyzicoSubMerchantStatusDtoImpl
        >
    implements _$$IyzicoSubMerchantStatusDtoImplCopyWith<$Res> {
  __$$IyzicoSubMerchantStatusDtoImplCopyWithImpl(
    _$IyzicoSubMerchantStatusDtoImpl _value,
    $Res Function(_$IyzicoSubMerchantStatusDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? hasSubMerchant = null, Object? isApproved = null}) {
    return _then(
      _$IyzicoSubMerchantStatusDtoImpl(
        hasSubMerchant: null == hasSubMerchant
            ? _value.hasSubMerchant
            : hasSubMerchant // ignore: cast_nullable_to_non_nullable
                  as bool,
        isApproved: null == isApproved
            ? _value.isApproved
            : isApproved // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IyzicoSubMerchantStatusDtoImpl implements _IyzicoSubMerchantStatusDto {
  const _$IyzicoSubMerchantStatusDtoImpl({
    required this.hasSubMerchant,
    required this.isApproved,
  });

  factory _$IyzicoSubMerchantStatusDtoImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$IyzicoSubMerchantStatusDtoImplFromJson(json);

  @override
  final bool hasSubMerchant;
  @override
  final bool isApproved;

  @override
  String toString() {
    return 'IyzicoSubMerchantStatusDto(hasSubMerchant: $hasSubMerchant, isApproved: $isApproved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IyzicoSubMerchantStatusDtoImpl &&
            (identical(other.hasSubMerchant, hasSubMerchant) ||
                other.hasSubMerchant == hasSubMerchant) &&
            (identical(other.isApproved, isApproved) ||
                other.isApproved == isApproved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hasSubMerchant, isApproved);

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IyzicoSubMerchantStatusDtoImplCopyWith<_$IyzicoSubMerchantStatusDtoImpl>
  get copyWith =>
      __$$IyzicoSubMerchantStatusDtoImplCopyWithImpl<
        _$IyzicoSubMerchantStatusDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IyzicoSubMerchantStatusDtoImplToJson(this);
  }
}

abstract class _IyzicoSubMerchantStatusDto
    implements IyzicoSubMerchantStatusDto {
  const factory _IyzicoSubMerchantStatusDto({
    required final bool hasSubMerchant,
    required final bool isApproved,
  }) = _$IyzicoSubMerchantStatusDtoImpl;

  factory _IyzicoSubMerchantStatusDto.fromJson(Map<String, dynamic> json) =
      _$IyzicoSubMerchantStatusDtoImpl.fromJson;

  @override
  bool get hasSubMerchant;
  @override
  bool get isApproved;

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IyzicoSubMerchantStatusDtoImplCopyWith<_$IyzicoSubMerchantStatusDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
