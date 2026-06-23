// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderItemResponseDto _$OrderItemResponseDtoFromJson(Map<String, dynamic> json) {
  return _OrderItemResponseDto.fromJson(json);
}

/// @nodoc
mixin _$OrderItemResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get menuItemId => throw _privateConstructorUsedError;
  String get menuItemName => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDouble)
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDouble)
  double get lineTotal => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  OrderItemStatus get status => throw _privateConstructorUsedError;

  /// Serializes this OrderItemResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemResponseDtoCopyWith<OrderItemResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemResponseDtoCopyWith<$Res> {
  factory $OrderItemResponseDtoCopyWith(
    OrderItemResponseDto value,
    $Res Function(OrderItemResponseDto) then,
  ) = _$OrderItemResponseDtoCopyWithImpl<$Res, OrderItemResponseDto>;
  @useResult
  $Res call({
    int id,
    int menuItemId,
    String menuItemName,
    int quantity,
    @JsonKey(fromJson: _toDouble) double unitPrice,
    @JsonKey(fromJson: _toDouble) double lineTotal,
    String? note,
    OrderItemStatus status,
  });
}

/// @nodoc
class _$OrderItemResponseDtoCopyWithImpl<
  $Res,
  $Val extends OrderItemResponseDto
>
    implements $OrderItemResponseDtoCopyWith<$Res> {
  _$OrderItemResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? menuItemId = null,
    Object? menuItemName = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? lineTotal = null,
    Object? note = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            menuItemId: null == menuItemId
                ? _value.menuItemId
                : menuItemId // ignore: cast_nullable_to_non_nullable
                      as int,
            menuItemName: null == menuItemName
                ? _value.menuItemName
                : menuItemName // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            lineTotal: null == lineTotal
                ? _value.lineTotal
                : lineTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OrderItemStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderItemResponseDtoImplCopyWith<$Res>
    implements $OrderItemResponseDtoCopyWith<$Res> {
  factory _$$OrderItemResponseDtoImplCopyWith(
    _$OrderItemResponseDtoImpl value,
    $Res Function(_$OrderItemResponseDtoImpl) then,
  ) = __$$OrderItemResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int menuItemId,
    String menuItemName,
    int quantity,
    @JsonKey(fromJson: _toDouble) double unitPrice,
    @JsonKey(fromJson: _toDouble) double lineTotal,
    String? note,
    OrderItemStatus status,
  });
}

/// @nodoc
class __$$OrderItemResponseDtoImplCopyWithImpl<$Res>
    extends _$OrderItemResponseDtoCopyWithImpl<$Res, _$OrderItemResponseDtoImpl>
    implements _$$OrderItemResponseDtoImplCopyWith<$Res> {
  __$$OrderItemResponseDtoImplCopyWithImpl(
    _$OrderItemResponseDtoImpl _value,
    $Res Function(_$OrderItemResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? menuItemId = null,
    Object? menuItemName = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? lineTotal = null,
    Object? note = freezed,
    Object? status = null,
  }) {
    return _then(
      _$OrderItemResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        menuItemId: null == menuItemId
            ? _value.menuItemId
            : menuItemId // ignore: cast_nullable_to_non_nullable
                  as int,
        menuItemName: null == menuItemName
            ? _value.menuItemName
            : menuItemName // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        lineTotal: null == lineTotal
            ? _value.lineTotal
            : lineTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OrderItemStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemResponseDtoImpl implements _OrderItemResponseDto {
  const _$OrderItemResponseDtoImpl({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    @JsonKey(fromJson: _toDouble) required this.unitPrice,
    @JsonKey(fromJson: _toDouble) required this.lineTotal,
    this.note,
    required this.status,
  });

  factory _$OrderItemResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int menuItemId;
  @override
  final String menuItemName;
  @override
  final int quantity;
  @override
  @JsonKey(fromJson: _toDouble)
  final double unitPrice;
  @override
  @JsonKey(fromJson: _toDouble)
  final double lineTotal;
  @override
  final String? note;
  @override
  final OrderItemStatus status;

  @override
  String toString() {
    return 'OrderItemResponseDto(id: $id, menuItemId: $menuItemId, menuItemName: $menuItemName, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal, note: $note, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.menuItemId, menuItemId) ||
                other.menuItemId == menuItemId) &&
            (identical(other.menuItemName, menuItemName) ||
                other.menuItemName == menuItemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    menuItemId,
    menuItemName,
    quantity,
    unitPrice,
    lineTotal,
    note,
    status,
  );

  /// Create a copy of OrderItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemResponseDtoImplCopyWith<_$OrderItemResponseDtoImpl>
  get copyWith =>
      __$$OrderItemResponseDtoImplCopyWithImpl<_$OrderItemResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemResponseDtoImplToJson(this);
  }
}

abstract class _OrderItemResponseDto implements OrderItemResponseDto {
  const factory _OrderItemResponseDto({
    required final int id,
    required final int menuItemId,
    required final String menuItemName,
    required final int quantity,
    @JsonKey(fromJson: _toDouble) required final double unitPrice,
    @JsonKey(fromJson: _toDouble) required final double lineTotal,
    final String? note,
    required final OrderItemStatus status,
  }) = _$OrderItemResponseDtoImpl;

  factory _OrderItemResponseDto.fromJson(Map<String, dynamic> json) =
      _$OrderItemResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get menuItemId;
  @override
  String get menuItemName;
  @override
  int get quantity;
  @override
  @JsonKey(fromJson: _toDouble)
  double get unitPrice;
  @override
  @JsonKey(fromJson: _toDouble)
  double get lineTotal;
  @override
  String? get note;
  @override
  OrderItemStatus get status;

  /// Create a copy of OrderItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemResponseDtoImplCopyWith<_$OrderItemResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OrderResponseDto _$OrderResponseDtoFromJson(Map<String, dynamic> json) {
  return _OrderResponseDto.fromJson(json);
}

/// @nodoc
mixin _$OrderResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get tableId => throw _privateConstructorUsedError;
  int get tableNumber => throw _privateConstructorUsedError;
  int? get waiterId => throw _privateConstructorUsedError;
  String? get waiterName => throw _privateConstructorUsedError;
  OrderStatus get status => throw _privateConstructorUsedError;
  OrderPaymentStatus get paymentStatus => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDouble)
  double get totalPrice => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  List<OrderItemResponseDto> get items => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OrderResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderResponseDtoCopyWith<OrderResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderResponseDtoCopyWith<$Res> {
  factory $OrderResponseDtoCopyWith(
    OrderResponseDto value,
    $Res Function(OrderResponseDto) then,
  ) = _$OrderResponseDtoCopyWithImpl<$Res, OrderResponseDto>;
  @useResult
  $Res call({
    int id,
    int tableId,
    int tableNumber,
    int? waiterId,
    String? waiterName,
    OrderStatus status,
    OrderPaymentStatus paymentStatus,
    @JsonKey(fromJson: _toDouble) double totalPrice,
    String? note,
    List<OrderItemResponseDto> items,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$OrderResponseDtoCopyWithImpl<$Res, $Val extends OrderResponseDto>
    implements $OrderResponseDtoCopyWith<$Res> {
  _$OrderResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? tableNumber = null,
    Object? waiterId = freezed,
    Object? waiterName = freezed,
    Object? status = null,
    Object? paymentStatus = null,
    Object? totalPrice = null,
    Object? note = freezed,
    Object? items = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            tableId: null == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as int,
            tableNumber: null == tableNumber
                ? _value.tableNumber
                : tableNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            waiterId: freezed == waiterId
                ? _value.waiterId
                : waiterId // ignore: cast_nullable_to_non_nullable
                      as int?,
            waiterName: freezed == waiterName
                ? _value.waiterName
                : waiterName // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OrderStatus,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as OrderPaymentStatus,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItemResponseDto>,
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
abstract class _$$OrderResponseDtoImplCopyWith<$Res>
    implements $OrderResponseDtoCopyWith<$Res> {
  factory _$$OrderResponseDtoImplCopyWith(
    _$OrderResponseDtoImpl value,
    $Res Function(_$OrderResponseDtoImpl) then,
  ) = __$$OrderResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int tableId,
    int tableNumber,
    int? waiterId,
    String? waiterName,
    OrderStatus status,
    OrderPaymentStatus paymentStatus,
    @JsonKey(fromJson: _toDouble) double totalPrice,
    String? note,
    List<OrderItemResponseDto> items,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$OrderResponseDtoImplCopyWithImpl<$Res>
    extends _$OrderResponseDtoCopyWithImpl<$Res, _$OrderResponseDtoImpl>
    implements _$$OrderResponseDtoImplCopyWith<$Res> {
  __$$OrderResponseDtoImplCopyWithImpl(
    _$OrderResponseDtoImpl _value,
    $Res Function(_$OrderResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableId = null,
    Object? tableNumber = null,
    Object? waiterId = freezed,
    Object? waiterName = freezed,
    Object? status = null,
    Object? paymentStatus = null,
    Object? totalPrice = null,
    Object? note = freezed,
    Object? items = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$OrderResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        tableId: null == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as int,
        tableNumber: null == tableNumber
            ? _value.tableNumber
            : tableNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        waiterId: freezed == waiterId
            ? _value.waiterId
            : waiterId // ignore: cast_nullable_to_non_nullable
                  as int?,
        waiterName: freezed == waiterName
            ? _value.waiterName
            : waiterName // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OrderStatus,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as OrderPaymentStatus,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItemResponseDto>,
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
class _$OrderResponseDtoImpl implements _OrderResponseDto {
  const _$OrderResponseDtoImpl({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    this.waiterId,
    this.waiterName,
    required this.status,
    required this.paymentStatus,
    @JsonKey(fromJson: _toDouble) required this.totalPrice,
    this.note,
    required final List<OrderItemResponseDto> items,
    required this.createdAt,
    this.updatedAt,
  }) : _items = items;

  factory _$OrderResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int tableId;
  @override
  final int tableNumber;
  @override
  final int? waiterId;
  @override
  final String? waiterName;
  @override
  final OrderStatus status;
  @override
  final OrderPaymentStatus paymentStatus;
  @override
  @JsonKey(fromJson: _toDouble)
  final double totalPrice;
  @override
  final String? note;
  final List<OrderItemResponseDto> _items;
  @override
  List<OrderItemResponseDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'OrderResponseDto(id: $id, tableId: $tableId, tableNumber: $tableNumber, waiterId: $waiterId, waiterName: $waiterName, status: $status, paymentStatus: $paymentStatus, totalPrice: $totalPrice, note: $note, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.waiterId, waiterId) ||
                other.waiterId == waiterId) &&
            (identical(other.waiterName, waiterName) ||
                other.waiterName == waiterName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.note, note) || other.note == note) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
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
    tableId,
    tableNumber,
    waiterId,
    waiterName,
    status,
    paymentStatus,
    totalPrice,
    note,
    const DeepCollectionEquality().hash(_items),
    createdAt,
    updatedAt,
  );

  /// Create a copy of OrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderResponseDtoImplCopyWith<_$OrderResponseDtoImpl> get copyWith =>
      __$$OrderResponseDtoImplCopyWithImpl<_$OrderResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderResponseDtoImplToJson(this);
  }
}

abstract class _OrderResponseDto implements OrderResponseDto {
  const factory _OrderResponseDto({
    required final int id,
    required final int tableId,
    required final int tableNumber,
    final int? waiterId,
    final String? waiterName,
    required final OrderStatus status,
    required final OrderPaymentStatus paymentStatus,
    @JsonKey(fromJson: _toDouble) required final double totalPrice,
    final String? note,
    required final List<OrderItemResponseDto> items,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$OrderResponseDtoImpl;

  factory _OrderResponseDto.fromJson(Map<String, dynamic> json) =
      _$OrderResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get tableId;
  @override
  int get tableNumber;
  @override
  int? get waiterId;
  @override
  String? get waiterName;
  @override
  OrderStatus get status;
  @override
  OrderPaymentStatus get paymentStatus;
  @override
  @JsonKey(fromJson: _toDouble)
  double get totalPrice;
  @override
  String? get note;
  @override
  List<OrderItemResponseDto> get items;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of OrderResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderResponseDtoImplCopyWith<_$OrderResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
