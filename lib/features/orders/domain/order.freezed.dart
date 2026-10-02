// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderEvent {

 OrderStatus get status; DateTime get at; String? get note;
/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderEventCopyWith<OrderEvent> get copyWith => _$OrderEventCopyWithImpl<OrderEvent>(this as OrderEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrderEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderEvent&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as OrderEvent;
  return Object.hash(runtimeType,_this.status,_this.at,_this.note);
}

@override
String toString() {
  final _this = this as OrderEvent;
  return 'OrderEvent(status: ${_this.status}, at: ${_this.at}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $OrderEventCopyWith<$Res>  {
  factory $OrderEventCopyWith(OrderEvent value, $Res Function(OrderEvent) _then) = _$OrderEventCopyWithImpl;
@useResult
$Res call({
 OrderStatus status, DateTime at, String? note
});




}
/// @nodoc
class _$OrderEventCopyWithImpl<$Res>
    implements $OrderEventCopyWith<$Res> {
  _$OrderEventCopyWithImpl(this._self, this._then);

  final OrderEvent _self;
  final $Res Function(OrderEvent) _then;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? at = null,Object? note = freezed,}) {
  return _then(OrderEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderEvent].
extension OrderEventPatterns on OrderEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderEvent value)  $default,){
final _that = this;
switch (_that) {
case _OrderEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderEvent value)?  $default,){
final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderStatus status,  DateTime at,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that.status,_that.at,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderStatus status,  DateTime at,  String? note)  $default,) {final _that = this;
switch (_that) {
case _OrderEvent():
return $default(_that.status,_that.at,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderStatus status,  DateTime at,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _OrderEvent() when $default != null:
return $default(_that.status,_that.at,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _OrderEvent implements OrderEvent {
  const _OrderEvent({required this.status, required this.at, this.note});
  

@override final  OrderStatus status;
@override final  DateTime at;
@override final  String? note;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderEventCopyWith<_OrderEvent> get copyWith => __$OrderEventCopyWithImpl<_OrderEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.at, at) || other.at == at)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,at,note);
}

@override
String toString() {
    return 'OrderEvent(status: $status, at: $at, note: $note)';
}


}

/// @nodoc
abstract mixin class _$OrderEventCopyWith<$Res> implements $OrderEventCopyWith<$Res> {
  factory _$OrderEventCopyWith(_OrderEvent value, $Res Function(_OrderEvent) _then) = __$OrderEventCopyWithImpl;
@override @useResult
$Res call({
 OrderStatus status, DateTime at, String? note
});




}
/// @nodoc
class __$OrderEventCopyWithImpl<$Res>
    implements _$OrderEventCopyWith<$Res> {
  __$OrderEventCopyWithImpl(this._self, this._then);

  final _OrderEvent _self;
  final $Res Function(_OrderEvent) _then;

/// Create a copy of OrderEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? at = null,Object? note = freezed,}) {
  return _then(_OrderEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Order {

 String get id; String get requestId; String get quoteId; String get buyerId; String get sellerId; String get title; String get sellerName; String? get buyerName; String? get sellerPhone; String? get buyerPhone; String? get fullAddress; Money get total; OrderStatus get status; String? get paymentMethod; Money? get paymentAmount; DateTime? get paymentRecordedAt; List<OrderEvent> get events; DateTime get createdAt; bool get buyerReviewed; bool get sellerReviewed;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Order;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.quoteId, _this.quoteId) || other.quoteId == _this.quoteId)&&(identical(other.buyerId, _this.buyerId) || other.buyerId == _this.buyerId)&&(identical(other.sellerId, _this.sellerId) || other.sellerId == _this.sellerId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.sellerName, _this.sellerName) || other.sellerName == _this.sellerName)&&(identical(other.buyerName, _this.buyerName) || other.buyerName == _this.buyerName)&&(identical(other.sellerPhone, _this.sellerPhone) || other.sellerPhone == _this.sellerPhone)&&(identical(other.buyerPhone, _this.buyerPhone) || other.buyerPhone == _this.buyerPhone)&&(identical(other.fullAddress, _this.fullAddress) || other.fullAddress == _this.fullAddress)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.paymentAmount, _this.paymentAmount) || other.paymentAmount == _this.paymentAmount)&&(identical(other.paymentRecordedAt, _this.paymentRecordedAt) || other.paymentRecordedAt == _this.paymentRecordedAt)&&const DeepCollectionEquality().equals(other.events, _this.events)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.buyerReviewed, _this.buyerReviewed) || other.buyerReviewed == _this.buyerReviewed)&&(identical(other.sellerReviewed, _this.sellerReviewed) || other.sellerReviewed == _this.sellerReviewed));
}


@override
int get hashCode {
  final _this = this as Order;
  return Object.hashAll([runtimeType,_this.id,_this.requestId,_this.quoteId,_this.buyerId,_this.sellerId,_this.title,_this.sellerName,_this.buyerName,_this.sellerPhone,_this.buyerPhone,_this.fullAddress,_this.total,_this.status,_this.paymentMethod,_this.paymentAmount,_this.paymentRecordedAt,const DeepCollectionEquality().hash(_this.events),_this.createdAt,_this.buyerReviewed,_this.sellerReviewed]);
}

@override
String toString() {
  final _this = this as Order;
  return 'Order(id: ${_this.id}, requestId: ${_this.requestId}, quoteId: ${_this.quoteId}, buyerId: ${_this.buyerId}, sellerId: ${_this.sellerId}, title: ${_this.title}, sellerName: ${_this.sellerName}, buyerName: ${_this.buyerName}, sellerPhone: ${_this.sellerPhone}, buyerPhone: ${_this.buyerPhone}, fullAddress: ${_this.fullAddress}, total: ${_this.total}, status: ${_this.status}, paymentMethod: ${_this.paymentMethod}, paymentAmount: ${_this.paymentAmount}, paymentRecordedAt: ${_this.paymentRecordedAt}, events: ${_this.events}, createdAt: ${_this.createdAt}, buyerReviewed: ${_this.buyerReviewed}, sellerReviewed: ${_this.sellerReviewed})';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, String quoteId, String buyerId, String sellerId, String title, String sellerName, String? buyerName, String? sellerPhone, String? buyerPhone, String? fullAddress, Money total, OrderStatus status, String? paymentMethod, Money? paymentAmount, DateTime? paymentRecordedAt, List<OrderEvent> events, DateTime createdAt, bool buyerReviewed, bool sellerReviewed
});




}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? quoteId = null,Object? buyerId = null,Object? sellerId = null,Object? title = null,Object? sellerName = null,Object? buyerName = freezed,Object? sellerPhone = freezed,Object? buyerPhone = freezed,Object? fullAddress = freezed,Object? total = null,Object? status = null,Object? paymentMethod = freezed,Object? paymentAmount = freezed,Object? paymentRecordedAt = freezed,Object? events = null,Object? createdAt = null,Object? buyerReviewed = null,Object? sellerReviewed = null,}) {
  return _then(Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sellerName: null == sellerName ? _self.sellerName : sellerName // ignore: cast_nullable_to_non_nullable
as String,buyerName: freezed == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String?,sellerPhone: freezed == sellerPhone ? _self.sellerPhone : sellerPhone // ignore: cast_nullable_to_non_nullable
as String?,buyerPhone: freezed == buyerPhone ? _self.buyerPhone : buyerPhone // ignore: cast_nullable_to_non_nullable
as String?,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,paymentAmount: freezed == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,paymentRecordedAt: freezed == paymentRecordedAt ? _self.paymentRecordedAt : paymentRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<OrderEvent>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,buyerReviewed: null == buyerReviewed ? _self.buyerReviewed : buyerReviewed // ignore: cast_nullable_to_non_nullable
as bool,sellerReviewed: null == sellerReviewed ? _self.sellerReviewed : sellerReviewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requestId,  String quoteId,  String buyerId,  String sellerId,  String title,  String sellerName,  String? buyerName,  String? sellerPhone,  String? buyerPhone,  String? fullAddress,  Money total,  OrderStatus status,  String? paymentMethod,  Money? paymentAmount,  DateTime? paymentRecordedAt,  List<OrderEvent> events,  DateTime createdAt,  bool buyerReviewed,  bool sellerReviewed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.requestId,_that.quoteId,_that.buyerId,_that.sellerId,_that.title,_that.sellerName,_that.buyerName,_that.sellerPhone,_that.buyerPhone,_that.fullAddress,_that.total,_that.status,_that.paymentMethod,_that.paymentAmount,_that.paymentRecordedAt,_that.events,_that.createdAt,_that.buyerReviewed,_that.sellerReviewed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requestId,  String quoteId,  String buyerId,  String sellerId,  String title,  String sellerName,  String? buyerName,  String? sellerPhone,  String? buyerPhone,  String? fullAddress,  Money total,  OrderStatus status,  String? paymentMethod,  Money? paymentAmount,  DateTime? paymentRecordedAt,  List<OrderEvent> events,  DateTime createdAt,  bool buyerReviewed,  bool sellerReviewed)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.requestId,_that.quoteId,_that.buyerId,_that.sellerId,_that.title,_that.sellerName,_that.buyerName,_that.sellerPhone,_that.buyerPhone,_that.fullAddress,_that.total,_that.status,_that.paymentMethod,_that.paymentAmount,_that.paymentRecordedAt,_that.events,_that.createdAt,_that.buyerReviewed,_that.sellerReviewed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requestId,  String quoteId,  String buyerId,  String sellerId,  String title,  String sellerName,  String? buyerName,  String? sellerPhone,  String? buyerPhone,  String? fullAddress,  Money total,  OrderStatus status,  String? paymentMethod,  Money? paymentAmount,  DateTime? paymentRecordedAt,  List<OrderEvent> events,  DateTime createdAt,  bool buyerReviewed,  bool sellerReviewed)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.requestId,_that.quoteId,_that.buyerId,_that.sellerId,_that.title,_that.sellerName,_that.buyerName,_that.sellerPhone,_that.buyerPhone,_that.fullAddress,_that.total,_that.status,_that.paymentMethod,_that.paymentAmount,_that.paymentRecordedAt,_that.events,_that.createdAt,_that.buyerReviewed,_that.sellerReviewed);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.id, required this.requestId, required this.quoteId, required this.buyerId, required this.sellerId, required this.title, required this.sellerName, this.buyerName, this.sellerPhone, this.buyerPhone, this.fullAddress, required this.total, this.status = OrderStatus.accepted, this.paymentMethod, this.paymentAmount, this.paymentRecordedAt,  List<OrderEvent> events = const [], required this.createdAt, this.buyerReviewed = false, this.sellerReviewed = false}): _events = events,super._();
  

@override final  String id;
@override final  String requestId;
@override final  String quoteId;
@override final  String buyerId;
@override final  String sellerId;
@override final  String title;
@override final  String sellerName;
@override final  String? buyerName;
@override final  String? sellerPhone;
@override final  String? buyerPhone;
@override final  String? fullAddress;
@override final  Money total;
@override@JsonKey() final  OrderStatus status;
@override final  String? paymentMethod;
@override final  Money? paymentAmount;
@override final  DateTime? paymentRecordedAt;
 final  List<OrderEvent> _events;
@override@JsonKey() List<OrderEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  DateTime createdAt;
@override@JsonKey() final  bool buyerReviewed;
@override@JsonKey() final  bool sellerReviewed;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sellerName, sellerName) || other.sellerName == sellerName)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.sellerPhone, sellerPhone) || other.sellerPhone == sellerPhone)&&(identical(other.buyerPhone, buyerPhone) || other.buyerPhone == buyerPhone)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.total, total) || other.total == total)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentAmount, paymentAmount) || other.paymentAmount == paymentAmount)&&(identical(other.paymentRecordedAt, paymentRecordedAt) || other.paymentRecordedAt == paymentRecordedAt)&&const DeepCollectionEquality().equals(other.events, _events)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.buyerReviewed, buyerReviewed) || other.buyerReviewed == buyerReviewed)&&(identical(other.sellerReviewed, sellerReviewed) || other.sellerReviewed == sellerReviewed));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,requestId,quoteId,buyerId,sellerId,title,sellerName,buyerName,sellerPhone,buyerPhone,fullAddress,total,status,paymentMethod,paymentAmount,paymentRecordedAt,const DeepCollectionEquality().hash(_events),createdAt,buyerReviewed,sellerReviewed]);
}

@override
String toString() {
    return 'Order(id: $id, requestId: $requestId, quoteId: $quoteId, buyerId: $buyerId, sellerId: $sellerId, title: $title, sellerName: $sellerName, buyerName: $buyerName, sellerPhone: $sellerPhone, buyerPhone: $buyerPhone, fullAddress: $fullAddress, total: $total, status: $status, paymentMethod: $paymentMethod, paymentAmount: $paymentAmount, paymentRecordedAt: $paymentRecordedAt, events: $events, createdAt: $createdAt, buyerReviewed: $buyerReviewed, sellerReviewed: $sellerReviewed)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, String quoteId, String buyerId, String sellerId, String title, String sellerName, String? buyerName, String? sellerPhone, String? buyerPhone, String? fullAddress, Money total, OrderStatus status, String? paymentMethod, Money? paymentAmount, DateTime? paymentRecordedAt, List<OrderEvent> events, DateTime createdAt, bool buyerReviewed, bool sellerReviewed
});




}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? quoteId = null,Object? buyerId = null,Object? sellerId = null,Object? title = null,Object? sellerName = null,Object? buyerName = freezed,Object? sellerPhone = freezed,Object? buyerPhone = freezed,Object? fullAddress = freezed,Object? total = null,Object? status = null,Object? paymentMethod = freezed,Object? paymentAmount = freezed,Object? paymentRecordedAt = freezed,Object? events = null,Object? createdAt = null,Object? buyerReviewed = null,Object? sellerReviewed = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sellerName: null == sellerName ? _self.sellerName : sellerName // ignore: cast_nullable_to_non_nullable
as String,buyerName: freezed == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String?,sellerPhone: freezed == sellerPhone ? _self.sellerPhone : sellerPhone // ignore: cast_nullable_to_non_nullable
as String?,buyerPhone: freezed == buyerPhone ? _self.buyerPhone : buyerPhone // ignore: cast_nullable_to_non_nullable
as String?,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,paymentAmount: freezed == paymentAmount ? _self.paymentAmount : paymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,paymentRecordedAt: freezed == paymentRecordedAt ? _self.paymentRecordedAt : paymentRecordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<OrderEvent>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,buyerReviewed: null == buyerReviewed ? _self.buyerReviewed : buyerReviewed // ignore: cast_nullable_to_non_nullable
as bool,sellerReviewed: null == sellerReviewed ? _self.sellerReviewed : sellerReviewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
