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
  String? get subMerchantKey => throw _privateConstructorUsedError;

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
  $Res call({bool hasSubMerchant, bool isApproved, String? subMerchantKey});
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
  $Res call({
    Object? hasSubMerchant = null,
    Object? isApproved = null,
    Object? subMerchantKey = freezed,
  }) {
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
            subMerchantKey: freezed == subMerchantKey
                ? _value.subMerchantKey
                : subMerchantKey // ignore: cast_nullable_to_non_nullable
                      as String?,
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
  $Res call({bool hasSubMerchant, bool isApproved, String? subMerchantKey});
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
  $Res call({
    Object? hasSubMerchant = null,
    Object? isApproved = null,
    Object? subMerchantKey = freezed,
  }) {
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
        subMerchantKey: freezed == subMerchantKey
            ? _value.subMerchantKey
            : subMerchantKey // ignore: cast_nullable_to_non_nullable
                  as String?,
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
    this.subMerchantKey,
  });

  factory _$IyzicoSubMerchantStatusDtoImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$IyzicoSubMerchantStatusDtoImplFromJson(json);

  @override
  final bool hasSubMerchant;
  @override
  final bool isApproved;
  @override
  final String? subMerchantKey;

  @override
  String toString() {
    return 'IyzicoSubMerchantStatusDto(hasSubMerchant: $hasSubMerchant, isApproved: $isApproved, subMerchantKey: $subMerchantKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IyzicoSubMerchantStatusDtoImpl &&
            (identical(other.hasSubMerchant, hasSubMerchant) ||
                other.hasSubMerchant == hasSubMerchant) &&
            (identical(other.isApproved, isApproved) ||
                other.isApproved == isApproved) &&
            (identical(other.subMerchantKey, subMerchantKey) ||
                other.subMerchantKey == subMerchantKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, hasSubMerchant, isApproved, subMerchantKey);

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
    final String? subMerchantKey,
  }) = _$IyzicoSubMerchantStatusDtoImpl;

  factory _IyzicoSubMerchantStatusDto.fromJson(Map<String, dynamic> json) =
      _$IyzicoSubMerchantStatusDtoImpl.fromJson;

  @override
  bool get hasSubMerchant;
  @override
  bool get isApproved;
  @override
  String? get subMerchantKey;

  /// Create a copy of IyzicoSubMerchantStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IyzicoSubMerchantStatusDtoImplCopyWith<_$IyzicoSubMerchantStatusDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RegisterSubMerchantRequestDto _$RegisterSubMerchantRequestDtoFromJson(
  Map<String, dynamic> json,
) {
  return _RegisterSubMerchantRequestDto.fromJson(json);
}

/// @nodoc
mixin _$RegisterSubMerchantRequestDto {
  String get contactName => throw _privateConstructorUsedError;
  String get contactSurname => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get gsmNumber => throw _privateConstructorUsedError;
  String get iban => throw _privateConstructorUsedError;
  String get legalCompanyTitle => throw _privateConstructorUsedError;
  String get taxOffice => throw _privateConstructorUsedError;
  String get taxNumber => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;

  /// Serializes this RegisterSubMerchantRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegisterSubMerchantRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegisterSubMerchantRequestDtoCopyWith<RegisterSubMerchantRequestDto>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterSubMerchantRequestDtoCopyWith<$Res> {
  factory $RegisterSubMerchantRequestDtoCopyWith(
    RegisterSubMerchantRequestDto value,
    $Res Function(RegisterSubMerchantRequestDto) then,
  ) =
      _$RegisterSubMerchantRequestDtoCopyWithImpl<
        $Res,
        RegisterSubMerchantRequestDto
      >;
  @useResult
  $Res call({
    String contactName,
    String contactSurname,
    String email,
    String gsmNumber,
    String iban,
    String legalCompanyTitle,
    String taxOffice,
    String taxNumber,
    String address,
  });
}

/// @nodoc
class _$RegisterSubMerchantRequestDtoCopyWithImpl<
  $Res,
  $Val extends RegisterSubMerchantRequestDto
>
    implements $RegisterSubMerchantRequestDtoCopyWith<$Res> {
  _$RegisterSubMerchantRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterSubMerchantRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contactName = null,
    Object? contactSurname = null,
    Object? email = null,
    Object? gsmNumber = null,
    Object? iban = null,
    Object? legalCompanyTitle = null,
    Object? taxOffice = null,
    Object? taxNumber = null,
    Object? address = null,
  }) {
    return _then(
      _value.copyWith(
            contactName: null == contactName
                ? _value.contactName
                : contactName // ignore: cast_nullable_to_non_nullable
                      as String,
            contactSurname: null == contactSurname
                ? _value.contactSurname
                : contactSurname // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            gsmNumber: null == gsmNumber
                ? _value.gsmNumber
                : gsmNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            iban: null == iban
                ? _value.iban
                : iban // ignore: cast_nullable_to_non_nullable
                      as String,
            legalCompanyTitle: null == legalCompanyTitle
                ? _value.legalCompanyTitle
                : legalCompanyTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            taxOffice: null == taxOffice
                ? _value.taxOffice
                : taxOffice // ignore: cast_nullable_to_non_nullable
                      as String,
            taxNumber: null == taxNumber
                ? _value.taxNumber
                : taxNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RegisterSubMerchantRequestDtoImplCopyWith<$Res>
    implements $RegisterSubMerchantRequestDtoCopyWith<$Res> {
  factory _$$RegisterSubMerchantRequestDtoImplCopyWith(
    _$RegisterSubMerchantRequestDtoImpl value,
    $Res Function(_$RegisterSubMerchantRequestDtoImpl) then,
  ) = __$$RegisterSubMerchantRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String contactName,
    String contactSurname,
    String email,
    String gsmNumber,
    String iban,
    String legalCompanyTitle,
    String taxOffice,
    String taxNumber,
    String address,
  });
}

/// @nodoc
class __$$RegisterSubMerchantRequestDtoImplCopyWithImpl<$Res>
    extends
        _$RegisterSubMerchantRequestDtoCopyWithImpl<
          $Res,
          _$RegisterSubMerchantRequestDtoImpl
        >
    implements _$$RegisterSubMerchantRequestDtoImplCopyWith<$Res> {
  __$$RegisterSubMerchantRequestDtoImplCopyWithImpl(
    _$RegisterSubMerchantRequestDtoImpl _value,
    $Res Function(_$RegisterSubMerchantRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegisterSubMerchantRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contactName = null,
    Object? contactSurname = null,
    Object? email = null,
    Object? gsmNumber = null,
    Object? iban = null,
    Object? legalCompanyTitle = null,
    Object? taxOffice = null,
    Object? taxNumber = null,
    Object? address = null,
  }) {
    return _then(
      _$RegisterSubMerchantRequestDtoImpl(
        contactName: null == contactName
            ? _value.contactName
            : contactName // ignore: cast_nullable_to_non_nullable
                  as String,
        contactSurname: null == contactSurname
            ? _value.contactSurname
            : contactSurname // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        gsmNumber: null == gsmNumber
            ? _value.gsmNumber
            : gsmNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        iban: null == iban
            ? _value.iban
            : iban // ignore: cast_nullable_to_non_nullable
                  as String,
        legalCompanyTitle: null == legalCompanyTitle
            ? _value.legalCompanyTitle
            : legalCompanyTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        taxOffice: null == taxOffice
            ? _value.taxOffice
            : taxOffice // ignore: cast_nullable_to_non_nullable
                  as String,
        taxNumber: null == taxNumber
            ? _value.taxNumber
            : taxNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RegisterSubMerchantRequestDtoImpl
    implements _RegisterSubMerchantRequestDto {
  const _$RegisterSubMerchantRequestDtoImpl({
    required this.contactName,
    required this.contactSurname,
    required this.email,
    required this.gsmNumber,
    required this.iban,
    required this.legalCompanyTitle,
    required this.taxOffice,
    required this.taxNumber,
    required this.address,
  });

  factory _$RegisterSubMerchantRequestDtoImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RegisterSubMerchantRequestDtoImplFromJson(json);

  @override
  final String contactName;
  @override
  final String contactSurname;
  @override
  final String email;
  @override
  final String gsmNumber;
  @override
  final String iban;
  @override
  final String legalCompanyTitle;
  @override
  final String taxOffice;
  @override
  final String taxNumber;
  @override
  final String address;

  @override
  String toString() {
    return 'RegisterSubMerchantRequestDto(contactName: $contactName, contactSurname: $contactSurname, email: $email, gsmNumber: $gsmNumber, iban: $iban, legalCompanyTitle: $legalCompanyTitle, taxOffice: $taxOffice, taxNumber: $taxNumber, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterSubMerchantRequestDtoImpl &&
            (identical(other.contactName, contactName) ||
                other.contactName == contactName) &&
            (identical(other.contactSurname, contactSurname) ||
                other.contactSurname == contactSurname) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gsmNumber, gsmNumber) ||
                other.gsmNumber == gsmNumber) &&
            (identical(other.iban, iban) || other.iban == iban) &&
            (identical(other.legalCompanyTitle, legalCompanyTitle) ||
                other.legalCompanyTitle == legalCompanyTitle) &&
            (identical(other.taxOffice, taxOffice) ||
                other.taxOffice == taxOffice) &&
            (identical(other.taxNumber, taxNumber) ||
                other.taxNumber == taxNumber) &&
            (identical(other.address, address) || other.address == address));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    contactName,
    contactSurname,
    email,
    gsmNumber,
    iban,
    legalCompanyTitle,
    taxOffice,
    taxNumber,
    address,
  );

  /// Create a copy of RegisterSubMerchantRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterSubMerchantRequestDtoImplCopyWith<
    _$RegisterSubMerchantRequestDtoImpl
  >
  get copyWith =>
      __$$RegisterSubMerchantRequestDtoImplCopyWithImpl<
        _$RegisterSubMerchantRequestDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegisterSubMerchantRequestDtoImplToJson(this);
  }
}

abstract class _RegisterSubMerchantRequestDto
    implements RegisterSubMerchantRequestDto {
  const factory _RegisterSubMerchantRequestDto({
    required final String contactName,
    required final String contactSurname,
    required final String email,
    required final String gsmNumber,
    required final String iban,
    required final String legalCompanyTitle,
    required final String taxOffice,
    required final String taxNumber,
    required final String address,
  }) = _$RegisterSubMerchantRequestDtoImpl;

  factory _RegisterSubMerchantRequestDto.fromJson(Map<String, dynamic> json) =
      _$RegisterSubMerchantRequestDtoImpl.fromJson;

  @override
  String get contactName;
  @override
  String get contactSurname;
  @override
  String get email;
  @override
  String get gsmNumber;
  @override
  String get iban;
  @override
  String get legalCompanyTitle;
  @override
  String get taxOffice;
  @override
  String get taxNumber;
  @override
  String get address;

  /// Create a copy of RegisterSubMerchantRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterSubMerchantRequestDtoImplCopyWith<
    _$RegisterSubMerchantRequestDtoImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
