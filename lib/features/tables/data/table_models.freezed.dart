// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TableResponseDto _$TableResponseDtoFromJson(Map<String, dynamic> json) {
  return _TableResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TableResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get restaurantId => throw _privateConstructorUsedError;
  int get tableNumber => throw _privateConstructorUsedError;
  int get capacity => throw _privateConstructorUsedError;
  String get qrCodeUrl => throw _privateConstructorUsedError;
  TableStatus get status => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TableResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TableResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TableResponseDtoCopyWith<TableResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TableResponseDtoCopyWith<$Res> {
  factory $TableResponseDtoCopyWith(
    TableResponseDto value,
    $Res Function(TableResponseDto) then,
  ) = _$TableResponseDtoCopyWithImpl<$Res, TableResponseDto>;
  @useResult
  $Res call({
    int id,
    int restaurantId,
    int tableNumber,
    int capacity,
    String qrCodeUrl,
    TableStatus status,
    bool isActive,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$TableResponseDtoCopyWithImpl<$Res, $Val extends TableResponseDto>
    implements $TableResponseDtoCopyWith<$Res> {
  _$TableResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TableResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? tableNumber = null,
    Object? capacity = null,
    Object? qrCodeUrl = null,
    Object? status = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            restaurantId: null == restaurantId
                ? _value.restaurantId
                : restaurantId // ignore: cast_nullable_to_non_nullable
                      as int,
            tableNumber: null == tableNumber
                ? _value.tableNumber
                : tableNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            capacity: null == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int,
            qrCodeUrl: null == qrCodeUrl
                ? _value.qrCodeUrl
                : qrCodeUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TableStatus,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TableResponseDtoImplCopyWith<$Res>
    implements $TableResponseDtoCopyWith<$Res> {
  factory _$$TableResponseDtoImplCopyWith(
    _$TableResponseDtoImpl value,
    $Res Function(_$TableResponseDtoImpl) then,
  ) = __$$TableResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int restaurantId,
    int tableNumber,
    int capacity,
    String qrCodeUrl,
    TableStatus status,
    bool isActive,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$TableResponseDtoImplCopyWithImpl<$Res>
    extends _$TableResponseDtoCopyWithImpl<$Res, _$TableResponseDtoImpl>
    implements _$$TableResponseDtoImplCopyWith<$Res> {
  __$$TableResponseDtoImplCopyWithImpl(
    _$TableResponseDtoImpl _value,
    $Res Function(_$TableResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TableResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? tableNumber = null,
    Object? capacity = null,
    Object? qrCodeUrl = null,
    Object? status = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$TableResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        restaurantId: null == restaurantId
            ? _value.restaurantId
            : restaurantId // ignore: cast_nullable_to_non_nullable
                  as int,
        tableNumber: null == tableNumber
            ? _value.tableNumber
            : tableNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        capacity: null == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int,
        qrCodeUrl: null == qrCodeUrl
            ? _value.qrCodeUrl
            : qrCodeUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TableStatus,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TableResponseDtoImpl implements _TableResponseDto {
  const _$TableResponseDtoImpl({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.capacity,
    required this.qrCodeUrl,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory _$TableResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int restaurantId;
  @override
  final int tableNumber;
  @override
  final int capacity;
  @override
  final String qrCodeUrl;
  @override
  final TableStatus status;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'TableResponseDto(id: $id, restaurantId: $restaurantId, tableNumber: $tableNumber, capacity: $capacity, qrCodeUrl: $qrCodeUrl, status: $status, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.restaurantId, restaurantId) ||
                other.restaurantId == restaurantId) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.qrCodeUrl, qrCodeUrl) ||
                other.qrCodeUrl == qrCodeUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    restaurantId,
    tableNumber,
    capacity,
    qrCodeUrl,
    status,
    isActive,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TableResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableResponseDtoImplCopyWith<_$TableResponseDtoImpl> get copyWith =>
      __$$TableResponseDtoImplCopyWithImpl<_$TableResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TableResponseDtoImplToJson(this);
  }
}

abstract class _TableResponseDto implements TableResponseDto {
  const factory _TableResponseDto({
    required final int id,
    required final int restaurantId,
    required final int tableNumber,
    required final int capacity,
    required final String qrCodeUrl,
    required final TableStatus status,
    required final bool isActive,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$TableResponseDtoImpl;

  factory _TableResponseDto.fromJson(Map<String, dynamic> json) =
      _$TableResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get restaurantId;
  @override
  int get tableNumber;
  @override
  int get capacity;
  @override
  String get qrCodeUrl;
  @override
  TableStatus get status;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of TableResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableResponseDtoImplCopyWith<_$TableResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegenerateQrResponseDto _$RegenerateQrResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _RegenerateQrResponseDto.fromJson(json);
}

/// @nodoc
mixin _$RegenerateQrResponseDto {
  int get tableId => throw _privateConstructorUsedError;
  int get tableNumber => throw _privateConstructorUsedError;
  String get qrCodeUrl => throw _privateConstructorUsedError;
  String get newSessionKey => throw _privateConstructorUsedError;

  /// Serializes this RegenerateQrResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegenerateQrResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegenerateQrResponseDtoCopyWith<RegenerateQrResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegenerateQrResponseDtoCopyWith<$Res> {
  factory $RegenerateQrResponseDtoCopyWith(
    RegenerateQrResponseDto value,
    $Res Function(RegenerateQrResponseDto) then,
  ) = _$RegenerateQrResponseDtoCopyWithImpl<$Res, RegenerateQrResponseDto>;
  @useResult
  $Res call({
    int tableId,
    int tableNumber,
    String qrCodeUrl,
    String newSessionKey,
  });
}

/// @nodoc
class _$RegenerateQrResponseDtoCopyWithImpl<
  $Res,
  $Val extends RegenerateQrResponseDto
>
    implements $RegenerateQrResponseDtoCopyWith<$Res> {
  _$RegenerateQrResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegenerateQrResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? tableNumber = null,
    Object? qrCodeUrl = null,
    Object? newSessionKey = null,
  }) {
    return _then(
      _value.copyWith(
            tableId: null == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as int,
            tableNumber: null == tableNumber
                ? _value.tableNumber
                : tableNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            qrCodeUrl: null == qrCodeUrl
                ? _value.qrCodeUrl
                : qrCodeUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            newSessionKey: null == newSessionKey
                ? _value.newSessionKey
                : newSessionKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RegenerateQrResponseDtoImplCopyWith<$Res>
    implements $RegenerateQrResponseDtoCopyWith<$Res> {
  factory _$$RegenerateQrResponseDtoImplCopyWith(
    _$RegenerateQrResponseDtoImpl value,
    $Res Function(_$RegenerateQrResponseDtoImpl) then,
  ) = __$$RegenerateQrResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int tableId,
    int tableNumber,
    String qrCodeUrl,
    String newSessionKey,
  });
}

/// @nodoc
class __$$RegenerateQrResponseDtoImplCopyWithImpl<$Res>
    extends
        _$RegenerateQrResponseDtoCopyWithImpl<
          $Res,
          _$RegenerateQrResponseDtoImpl
        >
    implements _$$RegenerateQrResponseDtoImplCopyWith<$Res> {
  __$$RegenerateQrResponseDtoImplCopyWithImpl(
    _$RegenerateQrResponseDtoImpl _value,
    $Res Function(_$RegenerateQrResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegenerateQrResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? tableNumber = null,
    Object? qrCodeUrl = null,
    Object? newSessionKey = null,
  }) {
    return _then(
      _$RegenerateQrResponseDtoImpl(
        tableId: null == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as int,
        tableNumber: null == tableNumber
            ? _value.tableNumber
            : tableNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        qrCodeUrl: null == qrCodeUrl
            ? _value.qrCodeUrl
            : qrCodeUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        newSessionKey: null == newSessionKey
            ? _value.newSessionKey
            : newSessionKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RegenerateQrResponseDtoImpl implements _RegenerateQrResponseDto {
  const _$RegenerateQrResponseDtoImpl({
    required this.tableId,
    required this.tableNumber,
    required this.qrCodeUrl,
    required this.newSessionKey,
  });

  factory _$RegenerateQrResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegenerateQrResponseDtoImplFromJson(json);

  @override
  final int tableId;
  @override
  final int tableNumber;
  @override
  final String qrCodeUrl;
  @override
  final String newSessionKey;

  @override
  String toString() {
    return 'RegenerateQrResponseDto(tableId: $tableId, tableNumber: $tableNumber, qrCodeUrl: $qrCodeUrl, newSessionKey: $newSessionKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegenerateQrResponseDtoImpl &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.qrCodeUrl, qrCodeUrl) ||
                other.qrCodeUrl == qrCodeUrl) &&
            (identical(other.newSessionKey, newSessionKey) ||
                other.newSessionKey == newSessionKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, tableId, tableNumber, qrCodeUrl, newSessionKey);

  /// Create a copy of RegenerateQrResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegenerateQrResponseDtoImplCopyWith<_$RegenerateQrResponseDtoImpl>
  get copyWith =>
      __$$RegenerateQrResponseDtoImplCopyWithImpl<
        _$RegenerateQrResponseDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegenerateQrResponseDtoImplToJson(this);
  }
}

abstract class _RegenerateQrResponseDto implements RegenerateQrResponseDto {
  const factory _RegenerateQrResponseDto({
    required final int tableId,
    required final int tableNumber,
    required final String qrCodeUrl,
    required final String newSessionKey,
  }) = _$RegenerateQrResponseDtoImpl;

  factory _RegenerateQrResponseDto.fromJson(Map<String, dynamic> json) =
      _$RegenerateQrResponseDtoImpl.fromJson;

  @override
  int get tableId;
  @override
  int get tableNumber;
  @override
  String get qrCodeUrl;
  @override
  String get newSessionKey;

  /// Create a copy of RegenerateQrResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegenerateQrResponseDtoImplCopyWith<_$RegenerateQrResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
