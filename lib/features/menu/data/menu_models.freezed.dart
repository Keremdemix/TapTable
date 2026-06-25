// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CategoryResponseDto _$CategoryResponseDtoFromJson(Map<String, dynamic> json) {
  return _CategoryResponseDto.fromJson(json);
}

/// @nodoc
mixin _$CategoryResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get restaurantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int get menuItemCount => throw _privateConstructorUsedError;

  /// Serializes this CategoryResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryResponseDtoCopyWith<CategoryResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryResponseDtoCopyWith<$Res> {
  factory $CategoryResponseDtoCopyWith(
    CategoryResponseDto value,
    $Res Function(CategoryResponseDto) then,
  ) = _$CategoryResponseDtoCopyWithImpl<$Res, CategoryResponseDto>;
  @useResult
  $Res call({
    int id,
    int restaurantId,
    String name,
    int sortOrder,
    bool isActive,
    int menuItemCount,
  });
}

/// @nodoc
class _$CategoryResponseDtoCopyWithImpl<$Res, $Val extends CategoryResponseDto>
    implements $CategoryResponseDtoCopyWith<$Res> {
  _$CategoryResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? menuItemCount = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            menuItemCount: null == menuItemCount
                ? _value.menuItemCount
                : menuItemCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryResponseDtoImplCopyWith<$Res>
    implements $CategoryResponseDtoCopyWith<$Res> {
  factory _$$CategoryResponseDtoImplCopyWith(
    _$CategoryResponseDtoImpl value,
    $Res Function(_$CategoryResponseDtoImpl) then,
  ) = __$$CategoryResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int restaurantId,
    String name,
    int sortOrder,
    bool isActive,
    int menuItemCount,
  });
}

/// @nodoc
class __$$CategoryResponseDtoImplCopyWithImpl<$Res>
    extends _$CategoryResponseDtoCopyWithImpl<$Res, _$CategoryResponseDtoImpl>
    implements _$$CategoryResponseDtoImplCopyWith<$Res> {
  __$$CategoryResponseDtoImplCopyWithImpl(
    _$CategoryResponseDtoImpl _value,
    $Res Function(_$CategoryResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? menuItemCount = null,
  }) {
    return _then(
      _$CategoryResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        restaurantId: null == restaurantId
            ? _value.restaurantId
            : restaurantId // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        menuItemCount: null == menuItemCount
            ? _value.menuItemCount
            : menuItemCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryResponseDtoImpl implements _CategoryResponseDto {
  const _$CategoryResponseDtoImpl({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.menuItemCount,
  });

  factory _$CategoryResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int restaurantId;
  @override
  final String name;
  @override
  final int sortOrder;
  @override
  final bool isActive;
  @override
  final int menuItemCount;

  @override
  String toString() {
    return 'CategoryResponseDto(id: $id, restaurantId: $restaurantId, name: $name, sortOrder: $sortOrder, isActive: $isActive, menuItemCount: $menuItemCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.restaurantId, restaurantId) ||
                other.restaurantId == restaurantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.menuItemCount, menuItemCount) ||
                other.menuItemCount == menuItemCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    restaurantId,
    name,
    sortOrder,
    isActive,
    menuItemCount,
  );

  /// Create a copy of CategoryResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryResponseDtoImplCopyWith<_$CategoryResponseDtoImpl> get copyWith =>
      __$$CategoryResponseDtoImplCopyWithImpl<_$CategoryResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryResponseDtoImplToJson(this);
  }
}

abstract class _CategoryResponseDto implements CategoryResponseDto {
  const factory _CategoryResponseDto({
    required final int id,
    required final int restaurantId,
    required final String name,
    required final int sortOrder,
    required final bool isActive,
    required final int menuItemCount,
  }) = _$CategoryResponseDtoImpl;

  factory _CategoryResponseDto.fromJson(Map<String, dynamic> json) =
      _$CategoryResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get restaurantId;
  @override
  String get name;
  @override
  int get sortOrder;
  @override
  bool get isActive;
  @override
  int get menuItemCount;

  /// Create a copy of CategoryResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryResponseDtoImplCopyWith<_$CategoryResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuItemResponseDto _$MenuItemResponseDtoFromJson(Map<String, dynamic> json) {
  return _MenuItemResponseDto.fromJson(json);
}

/// @nodoc
mixin _$MenuItemResponseDto {
  int get id => throw _privateConstructorUsedError;
  int get categoryId => throw _privateConstructorUsedError;
  String get categoryName => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDouble)
  double get price => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MenuItemResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemResponseDtoCopyWith<MenuItemResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemResponseDtoCopyWith<$Res> {
  factory $MenuItemResponseDtoCopyWith(
    MenuItemResponseDto value,
    $Res Function(MenuItemResponseDto) then,
  ) = _$MenuItemResponseDtoCopyWithImpl<$Res, MenuItemResponseDto>;
  @useResult
  $Res call({
    int id,
    int categoryId,
    String categoryName,
    String name,
    String? description,
    @JsonKey(fromJson: _toDouble) double price,
    String? imageUrl,
    bool isAvailable,
    bool isActive,
    int sortOrder,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$MenuItemResponseDtoCopyWithImpl<$Res, $Val extends MenuItemResponseDto>
    implements $MenuItemResponseDtoCopyWith<$Res> {
  _$MenuItemResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? categoryName = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? imageUrl = freezed,
    Object? isAvailable = null,
    Object? isActive = null,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int,
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$MenuItemResponseDtoImplCopyWith<$Res>
    implements $MenuItemResponseDtoCopyWith<$Res> {
  factory _$$MenuItemResponseDtoImplCopyWith(
    _$MenuItemResponseDtoImpl value,
    $Res Function(_$MenuItemResponseDtoImpl) then,
  ) = __$$MenuItemResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int categoryId,
    String categoryName,
    String name,
    String? description,
    @JsonKey(fromJson: _toDouble) double price,
    String? imageUrl,
    bool isAvailable,
    bool isActive,
    int sortOrder,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$MenuItemResponseDtoImplCopyWithImpl<$Res>
    extends _$MenuItemResponseDtoCopyWithImpl<$Res, _$MenuItemResponseDtoImpl>
    implements _$$MenuItemResponseDtoImplCopyWith<$Res> {
  __$$MenuItemResponseDtoImplCopyWithImpl(
    _$MenuItemResponseDtoImpl _value,
    $Res Function(_$MenuItemResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? categoryName = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? imageUrl = freezed,
    Object? isAvailable = null,
    Object? isActive = null,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$MenuItemResponseDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$MenuItemResponseDtoImpl implements _MenuItemResponseDto {
  const _$MenuItemResponseDtoImpl({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    @JsonKey(fromJson: _toDouble) required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });

  factory _$MenuItemResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemResponseDtoImplFromJson(json);

  @override
  final int id;
  @override
  final int categoryId;
  @override
  final String categoryName;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(fromJson: _toDouble)
  final double price;
  @override
  final String? imageUrl;
  @override
  final bool isAvailable;
  @override
  final bool isActive;
  @override
  final int sortOrder;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'MenuItemResponseDto(id: $id, categoryId: $categoryId, categoryName: $categoryName, name: $name, description: $description, price: $price, imageUrl: $imageUrl, isAvailable: $isAvailable, isActive: $isActive, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemResponseDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
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
    categoryId,
    categoryName,
    name,
    description,
    price,
    imageUrl,
    isAvailable,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );

  /// Create a copy of MenuItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemResponseDtoImplCopyWith<_$MenuItemResponseDtoImpl> get copyWith =>
      __$$MenuItemResponseDtoImplCopyWithImpl<_$MenuItemResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemResponseDtoImplToJson(this);
  }
}

abstract class _MenuItemResponseDto implements MenuItemResponseDto {
  const factory _MenuItemResponseDto({
    required final int id,
    required final int categoryId,
    required final String categoryName,
    required final String name,
    final String? description,
    @JsonKey(fromJson: _toDouble) required final double price,
    final String? imageUrl,
    required final bool isAvailable,
    required final bool isActive,
    required final int sortOrder,
    required final DateTime createdAt,
    final DateTime? updatedAt,
  }) = _$MenuItemResponseDtoImpl;

  factory _MenuItemResponseDto.fromJson(Map<String, dynamic> json) =
      _$MenuItemResponseDtoImpl.fromJson;

  @override
  int get id;
  @override
  int get categoryId;
  @override
  String get categoryName;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(fromJson: _toDouble)
  double get price;
  @override
  String? get imageUrl;
  @override
  bool get isAvailable;
  @override
  bool get isActive;
  @override
  int get sortOrder;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of MenuItemResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemResponseDtoImplCopyWith<_$MenuItemResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
