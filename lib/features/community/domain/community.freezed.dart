// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PriceTier {

 num get minQty; Money get unitPrice;
/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceTierCopyWith<PriceTier> get copyWith => _$PriceTierCopyWithImpl<PriceTier>(this as PriceTier, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PriceTier;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceTier&&(identical(other.minQty, _this.minQty) || other.minQty == _this.minQty)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice));
}


@override
int get hashCode {
  final _this = this as PriceTier;
  return Object.hash(runtimeType,_this.minQty,_this.unitPrice);
}

@override
String toString() {
  final _this = this as PriceTier;
  return 'PriceTier(minQty: ${_this.minQty}, unitPrice: ${_this.unitPrice})';
}


}

/// @nodoc
abstract mixin class $PriceTierCopyWith<$Res>  {
  factory $PriceTierCopyWith(PriceTier value, $Res Function(PriceTier) _then) = _$PriceTierCopyWithImpl;
@useResult
$Res call({
 num minQty, Money unitPrice
});




}
/// @nodoc
class _$PriceTierCopyWithImpl<$Res>
    implements $PriceTierCopyWith<$Res> {
  _$PriceTierCopyWithImpl(this._self, this._then);

  final PriceTier _self;
  final $Res Function(PriceTier) _then;

/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQty = null,Object? unitPrice = null,}) {
  return _then(PriceTier(
minQty: null == minQty ? _self.minQty : minQty // ignore: cast_nullable_to_non_nullable
as num,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceTier].
extension PriceTierPatterns on PriceTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceTier value)  $default,){
final _that = this;
switch (_that) {
case _PriceTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceTier value)?  $default,){
final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num minQty,  Money unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
return $default(_that.minQty,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num minQty,  Money unitPrice)  $default,) {final _that = this;
switch (_that) {
case _PriceTier():
return $default(_that.minQty,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num minQty,  Money unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
return $default(_that.minQty,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc


class _PriceTier implements PriceTier {
  const _PriceTier({required this.minQty, required this.unitPrice});
  

@override final  num minQty;
@override final  Money unitPrice;

/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceTierCopyWith<_PriceTier> get copyWith => __$PriceTierCopyWithImpl<_PriceTier>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceTier&&(identical(other.minQty, minQty) || other.minQty == minQty)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,minQty,unitPrice);
}

@override
String toString() {
    return 'PriceTier(minQty: $minQty, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$PriceTierCopyWith<$Res> implements $PriceTierCopyWith<$Res> {
  factory _$PriceTierCopyWith(_PriceTier value, $Res Function(_PriceTier) _then) = __$PriceTierCopyWithImpl;
@override @useResult
$Res call({
 num minQty, Money unitPrice
});




}
/// @nodoc
class __$PriceTierCopyWithImpl<$Res>
    implements _$PriceTierCopyWith<$Res> {
  __$PriceTierCopyWithImpl(this._self, this._then);

  final _PriceTier _self;
  final $Res Function(_PriceTier) _then;

/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQty = null,Object? unitPrice = null,}) {
  return _then(_PriceTier(
minQty: null == minQty ? _self.minQty : minQty // ignore: cast_nullable_to_non_nullable
as num,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}

/// @nodoc
mixin _$GroupWinner {

 String get sellerId; String get businessName; bool get verified; Money? get unitPrice;
/// Create a copy of GroupWinner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupWinnerCopyWith<GroupWinner> get copyWith => _$GroupWinnerCopyWithImpl<GroupWinner>(this as GroupWinner, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupWinner;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupWinner&&(identical(other.sellerId, _this.sellerId) || other.sellerId == _this.sellerId)&&(identical(other.businessName, _this.businessName) || other.businessName == _this.businessName)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice));
}


@override
int get hashCode {
  final _this = this as GroupWinner;
  return Object.hash(runtimeType,_this.sellerId,_this.businessName,_this.verified,_this.unitPrice);
}

@override
String toString() {
  final _this = this as GroupWinner;
  return 'GroupWinner(sellerId: ${_this.sellerId}, businessName: ${_this.businessName}, verified: ${_this.verified}, unitPrice: ${_this.unitPrice})';
}


}

/// @nodoc
abstract mixin class $GroupWinnerCopyWith<$Res>  {
  factory $GroupWinnerCopyWith(GroupWinner value, $Res Function(GroupWinner) _then) = _$GroupWinnerCopyWithImpl;
@useResult
$Res call({
 String sellerId, String businessName, bool verified, Money? unitPrice
});




}
/// @nodoc
class _$GroupWinnerCopyWithImpl<$Res>
    implements $GroupWinnerCopyWith<$Res> {
  _$GroupWinnerCopyWithImpl(this._self, this._then);

  final GroupWinner _self;
  final $Res Function(GroupWinner) _then;

/// Create a copy of GroupWinner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sellerId = null,Object? businessName = null,Object? verified = null,Object? unitPrice = freezed,}) {
  return _then(GroupWinner(
sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupWinner].
extension GroupWinnerPatterns on GroupWinner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupWinner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupWinner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupWinner value)  $default,){
final _that = this;
switch (_that) {
case _GroupWinner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupWinner value)?  $default,){
final _that = this;
switch (_that) {
case _GroupWinner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sellerId,  String businessName,  bool verified,  Money? unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupWinner() when $default != null:
return $default(_that.sellerId,_that.businessName,_that.verified,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sellerId,  String businessName,  bool verified,  Money? unitPrice)  $default,) {final _that = this;
switch (_that) {
case _GroupWinner():
return $default(_that.sellerId,_that.businessName,_that.verified,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sellerId,  String businessName,  bool verified,  Money? unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _GroupWinner() when $default != null:
return $default(_that.sellerId,_that.businessName,_that.verified,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc


class _GroupWinner implements GroupWinner {
  const _GroupWinner({required this.sellerId, required this.businessName, this.verified = false, this.unitPrice});
  

@override final  String sellerId;
@override final  String businessName;
@override@JsonKey() final  bool verified;
@override final  Money? unitPrice;

/// Create a copy of GroupWinner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupWinnerCopyWith<_GroupWinner> get copyWith => __$GroupWinnerCopyWithImpl<_GroupWinner>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupWinner&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sellerId,businessName,verified,unitPrice);
}

@override
String toString() {
    return 'GroupWinner(sellerId: $sellerId, businessName: $businessName, verified: $verified, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$GroupWinnerCopyWith<$Res> implements $GroupWinnerCopyWith<$Res> {
  factory _$GroupWinnerCopyWith(_GroupWinner value, $Res Function(_GroupWinner) _then) = __$GroupWinnerCopyWithImpl;
@override @useResult
$Res call({
 String sellerId, String businessName, bool verified, Money? unitPrice
});




}
/// @nodoc
class __$GroupWinnerCopyWithImpl<$Res>
    implements _$GroupWinnerCopyWith<$Res> {
  __$GroupWinnerCopyWithImpl(this._self, this._then);

  final _GroupWinner _self;
  final $Res Function(_GroupWinner) _then;

/// Create a copy of GroupWinner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sellerId = null,Object? businessName = null,Object? verified = null,Object? unitPrice = freezed,}) {
  return _then(_GroupWinner(
sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}


}

/// @nodoc
mixin _$GroupBuy {

 String get unit; num get totalQty; int get members;/// The viewer's quantity when they joined (the organiser included).
 num? get myQty;/// Best per-unit price at each step any seller offered; prices drop.
 List<PriceTier> get ladder;/// Best price for the group's current quantity.
 Money? get currentUnitPrice; num? get nextMinQty; Money? get nextUnitPrice; num? get qtyToNext; int get offers; GroupWinner? get winner;
/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupBuyCopyWith<GroupBuy> get copyWith => _$GroupBuyCopyWithImpl<GroupBuy>(this as GroupBuy, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupBuy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupBuy&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.totalQty, _this.totalQty) || other.totalQty == _this.totalQty)&&(identical(other.members, _this.members) || other.members == _this.members)&&(identical(other.myQty, _this.myQty) || other.myQty == _this.myQty)&&const DeepCollectionEquality().equals(other.ladder, _this.ladder)&&(identical(other.currentUnitPrice, _this.currentUnitPrice) || other.currentUnitPrice == _this.currentUnitPrice)&&(identical(other.nextMinQty, _this.nextMinQty) || other.nextMinQty == _this.nextMinQty)&&(identical(other.nextUnitPrice, _this.nextUnitPrice) || other.nextUnitPrice == _this.nextUnitPrice)&&(identical(other.qtyToNext, _this.qtyToNext) || other.qtyToNext == _this.qtyToNext)&&(identical(other.offers, _this.offers) || other.offers == _this.offers)&&(identical(other.winner, _this.winner) || other.winner == _this.winner));
}


@override
int get hashCode {
  final _this = this as GroupBuy;
  return Object.hash(runtimeType,_this.unit,_this.totalQty,_this.members,_this.myQty,const DeepCollectionEquality().hash(_this.ladder),_this.currentUnitPrice,_this.nextMinQty,_this.nextUnitPrice,_this.qtyToNext,_this.offers,_this.winner);
}

@override
String toString() {
  final _this = this as GroupBuy;
  return 'GroupBuy(unit: ${_this.unit}, totalQty: ${_this.totalQty}, members: ${_this.members}, myQty: ${_this.myQty}, ladder: ${_this.ladder}, currentUnitPrice: ${_this.currentUnitPrice}, nextMinQty: ${_this.nextMinQty}, nextUnitPrice: ${_this.nextUnitPrice}, qtyToNext: ${_this.qtyToNext}, offers: ${_this.offers}, winner: ${_this.winner})';
}


}

/// @nodoc
abstract mixin class $GroupBuyCopyWith<$Res>  {
  factory $GroupBuyCopyWith(GroupBuy value, $Res Function(GroupBuy) _then) = _$GroupBuyCopyWithImpl;
@useResult
$Res call({
 String unit, num totalQty, int members, num? myQty, List<PriceTier> ladder, Money? currentUnitPrice, num? nextMinQty, Money? nextUnitPrice, num? qtyToNext, int offers, GroupWinner? winner
});


$GroupWinnerCopyWith<$Res>? get winner;

}
/// @nodoc
class _$GroupBuyCopyWithImpl<$Res>
    implements $GroupBuyCopyWith<$Res> {
  _$GroupBuyCopyWithImpl(this._self, this._then);

  final GroupBuy _self;
  final $Res Function(GroupBuy) _then;

/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unit = null,Object? totalQty = null,Object? members = null,Object? myQty = freezed,Object? ladder = null,Object? currentUnitPrice = freezed,Object? nextMinQty = freezed,Object? nextUnitPrice = freezed,Object? qtyToNext = freezed,Object? offers = null,Object? winner = freezed,}) {
  return _then(GroupBuy(
unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,totalQty: null == totalQty ? _self.totalQty : totalQty // ignore: cast_nullable_to_non_nullable
as num,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as int,myQty: freezed == myQty ? _self.myQty : myQty // ignore: cast_nullable_to_non_nullable
as num?,ladder: null == ladder ? _self.ladder : ladder // ignore: cast_nullable_to_non_nullable
as List<PriceTier>,currentUnitPrice: freezed == currentUnitPrice ? _self.currentUnitPrice : currentUnitPrice // ignore: cast_nullable_to_non_nullable
as Money?,nextMinQty: freezed == nextMinQty ? _self.nextMinQty : nextMinQty // ignore: cast_nullable_to_non_nullable
as num?,nextUnitPrice: freezed == nextUnitPrice ? _self.nextUnitPrice : nextUnitPrice // ignore: cast_nullable_to_non_nullable
as Money?,qtyToNext: freezed == qtyToNext ? _self.qtyToNext : qtyToNext // ignore: cast_nullable_to_non_nullable
as num?,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as int,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as GroupWinner?,
  ));
}
/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupWinnerCopyWith<$Res>? get winner {
    if (_self.winner == null) {
    return null;
  }

  return $GroupWinnerCopyWith<$Res>(_self.winner!, (value) {
    return _then(_self.copyWith(winner: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupBuy].
extension GroupBuyPatterns on GroupBuy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupBuy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupBuy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupBuy value)  $default,){
final _that = this;
switch (_that) {
case _GroupBuy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupBuy value)?  $default,){
final _that = this;
switch (_that) {
case _GroupBuy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String unit,  num totalQty,  int members,  num? myQty,  List<PriceTier> ladder,  Money? currentUnitPrice,  num? nextMinQty,  Money? nextUnitPrice,  num? qtyToNext,  int offers,  GroupWinner? winner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupBuy() when $default != null:
return $default(_that.unit,_that.totalQty,_that.members,_that.myQty,_that.ladder,_that.currentUnitPrice,_that.nextMinQty,_that.nextUnitPrice,_that.qtyToNext,_that.offers,_that.winner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String unit,  num totalQty,  int members,  num? myQty,  List<PriceTier> ladder,  Money? currentUnitPrice,  num? nextMinQty,  Money? nextUnitPrice,  num? qtyToNext,  int offers,  GroupWinner? winner)  $default,) {final _that = this;
switch (_that) {
case _GroupBuy():
return $default(_that.unit,_that.totalQty,_that.members,_that.myQty,_that.ladder,_that.currentUnitPrice,_that.nextMinQty,_that.nextUnitPrice,_that.qtyToNext,_that.offers,_that.winner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String unit,  num totalQty,  int members,  num? myQty,  List<PriceTier> ladder,  Money? currentUnitPrice,  num? nextMinQty,  Money? nextUnitPrice,  num? qtyToNext,  int offers,  GroupWinner? winner)?  $default,) {final _that = this;
switch (_that) {
case _GroupBuy() when $default != null:
return $default(_that.unit,_that.totalQty,_that.members,_that.myQty,_that.ladder,_that.currentUnitPrice,_that.nextMinQty,_that.nextUnitPrice,_that.qtyToNext,_that.offers,_that.winner);case _:
  return null;

}
}

}

/// @nodoc


class _GroupBuy extends GroupBuy {
  const _GroupBuy({this.unit = 'units', this.totalQty = 0, this.members = 0, this.myQty,  List<PriceTier> ladder = const [], this.currentUnitPrice, this.nextMinQty, this.nextUnitPrice, this.qtyToNext, this.offers = 0, this.winner}): _ladder = ladder,super._();
  

@override@JsonKey() final  String unit;
@override@JsonKey() final  num totalQty;
@override@JsonKey() final  int members;
/// The viewer's quantity when they joined (the organiser included).
@override final  num? myQty;
/// Best per-unit price at each step any seller offered; prices drop.
 final  List<PriceTier> _ladder;
/// Best per-unit price at each step any seller offered; prices drop.
@override@JsonKey() List<PriceTier> get ladder {
  if (_ladder is EqualUnmodifiableListView) return _ladder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ladder);
}

/// Best price for the group's current quantity.
@override final  Money? currentUnitPrice;
@override final  num? nextMinQty;
@override final  Money? nextUnitPrice;
@override final  num? qtyToNext;
@override@JsonKey() final  int offers;
@override final  GroupWinner? winner;

/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupBuyCopyWith<_GroupBuy> get copyWith => __$GroupBuyCopyWithImpl<_GroupBuy>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupBuy&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.totalQty, totalQty) || other.totalQty == totalQty)&&(identical(other.members, members) || other.members == members)&&(identical(other.myQty, myQty) || other.myQty == myQty)&&const DeepCollectionEquality().equals(other.ladder, _ladder)&&(identical(other.currentUnitPrice, currentUnitPrice) || other.currentUnitPrice == currentUnitPrice)&&(identical(other.nextMinQty, nextMinQty) || other.nextMinQty == nextMinQty)&&(identical(other.nextUnitPrice, nextUnitPrice) || other.nextUnitPrice == nextUnitPrice)&&(identical(other.qtyToNext, qtyToNext) || other.qtyToNext == qtyToNext)&&(identical(other.offers, offers) || other.offers == offers)&&(identical(other.winner, winner) || other.winner == winner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,unit,totalQty,members,myQty,const DeepCollectionEquality().hash(_ladder),currentUnitPrice,nextMinQty,nextUnitPrice,qtyToNext,offers,winner);
}

@override
String toString() {
    return 'GroupBuy(unit: $unit, totalQty: $totalQty, members: $members, myQty: $myQty, ladder: $ladder, currentUnitPrice: $currentUnitPrice, nextMinQty: $nextMinQty, nextUnitPrice: $nextUnitPrice, qtyToNext: $qtyToNext, offers: $offers, winner: $winner)';
}


}

/// @nodoc
abstract mixin class _$GroupBuyCopyWith<$Res> implements $GroupBuyCopyWith<$Res> {
  factory _$GroupBuyCopyWith(_GroupBuy value, $Res Function(_GroupBuy) _then) = __$GroupBuyCopyWithImpl;
@override @useResult
$Res call({
 String unit, num totalQty, int members, num? myQty, List<PriceTier> ladder, Money? currentUnitPrice, num? nextMinQty, Money? nextUnitPrice, num? qtyToNext, int offers, GroupWinner? winner
});


@override $GroupWinnerCopyWith<$Res>? get winner;

}
/// @nodoc
class __$GroupBuyCopyWithImpl<$Res>
    implements _$GroupBuyCopyWith<$Res> {
  __$GroupBuyCopyWithImpl(this._self, this._then);

  final _GroupBuy _self;
  final $Res Function(_GroupBuy) _then;

/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unit = null,Object? totalQty = null,Object? members = null,Object? myQty = freezed,Object? ladder = null,Object? currentUnitPrice = freezed,Object? nextMinQty = freezed,Object? nextUnitPrice = freezed,Object? qtyToNext = freezed,Object? offers = null,Object? winner = freezed,}) {
  return _then(_GroupBuy(
unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,totalQty: null == totalQty ? _self.totalQty : totalQty // ignore: cast_nullable_to_non_nullable
as num,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as int,myQty: freezed == myQty ? _self.myQty : myQty // ignore: cast_nullable_to_non_nullable
as num?,ladder: null == ladder ? _self._ladder : ladder // ignore: cast_nullable_to_non_nullable
as List<PriceTier>,currentUnitPrice: freezed == currentUnitPrice ? _self.currentUnitPrice : currentUnitPrice // ignore: cast_nullable_to_non_nullable
as Money?,nextMinQty: freezed == nextMinQty ? _self.nextMinQty : nextMinQty // ignore: cast_nullable_to_non_nullable
as num?,nextUnitPrice: freezed == nextUnitPrice ? _self.nextUnitPrice : nextUnitPrice // ignore: cast_nullable_to_non_nullable
as Money?,qtyToNext: freezed == qtyToNext ? _self.qtyToNext : qtyToNext // ignore: cast_nullable_to_non_nullable
as num?,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as int,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as GroupWinner?,
  ));
}

/// Create a copy of GroupBuy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupWinnerCopyWith<$Res>? get winner {
    if (_self.winner == null) {
    return null;
  }

  return $GroupWinnerCopyWith<$Res>(_self.winner!, (value) {
    return _then(_self.copyWith(winner: value));
  });
}
}

/// @nodoc
mixin _$FeedPost {

 String get id; int get categoryId; String get title; String get description; Money? get budgetMin; Money? get budgetMax; DateTime? get neededBy; String? get locality; String? get city; String? get state; RequestStatus get status; int get quoteCount; int get commentCount; int get likeCount; bool get likedByMe; bool get isMine; String get authorName; String? get authorPhotoUrl; DateTime? get quoteWindowEndsAt; DateTime get publishedAt; GroupBuy? get group;
/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedPostCopyWith<FeedPost> get copyWith => _$FeedPostCopyWithImpl<FeedPost>(this as FeedPost, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedPost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedPost&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.budgetMin, _this.budgetMin) || other.budgetMin == _this.budgetMin)&&(identical(other.budgetMax, _this.budgetMax) || other.budgetMax == _this.budgetMax)&&(identical(other.neededBy, _this.neededBy) || other.neededBy == _this.neededBy)&&(identical(other.locality, _this.locality) || other.locality == _this.locality)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.quoteCount, _this.quoteCount) || other.quoteCount == _this.quoteCount)&&(identical(other.commentCount, _this.commentCount) || other.commentCount == _this.commentCount)&&(identical(other.likeCount, _this.likeCount) || other.likeCount == _this.likeCount)&&(identical(other.likedByMe, _this.likedByMe) || other.likedByMe == _this.likedByMe)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.authorPhotoUrl, _this.authorPhotoUrl) || other.authorPhotoUrl == _this.authorPhotoUrl)&&(identical(other.quoteWindowEndsAt, _this.quoteWindowEndsAt) || other.quoteWindowEndsAt == _this.quoteWindowEndsAt)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.group, _this.group) || other.group == _this.group));
}


@override
int get hashCode {
  final _this = this as FeedPost;
  return Object.hashAll([runtimeType,_this.id,_this.categoryId,_this.title,_this.description,_this.budgetMin,_this.budgetMax,_this.neededBy,_this.locality,_this.city,_this.state,_this.status,_this.quoteCount,_this.commentCount,_this.likeCount,_this.likedByMe,_this.isMine,_this.authorName,_this.authorPhotoUrl,_this.quoteWindowEndsAt,_this.publishedAt,_this.group]);
}

@override
String toString() {
  final _this = this as FeedPost;
  return 'FeedPost(id: ${_this.id}, categoryId: ${_this.categoryId}, title: ${_this.title}, description: ${_this.description}, budgetMin: ${_this.budgetMin}, budgetMax: ${_this.budgetMax}, neededBy: ${_this.neededBy}, locality: ${_this.locality}, city: ${_this.city}, state: ${_this.state}, status: ${_this.status}, quoteCount: ${_this.quoteCount}, commentCount: ${_this.commentCount}, likeCount: ${_this.likeCount}, likedByMe: ${_this.likedByMe}, isMine: ${_this.isMine}, authorName: ${_this.authorName}, authorPhotoUrl: ${_this.authorPhotoUrl}, quoteWindowEndsAt: ${_this.quoteWindowEndsAt}, publishedAt: ${_this.publishedAt}, group: ${_this.group})';
}


}

/// @nodoc
abstract mixin class $FeedPostCopyWith<$Res>  {
  factory $FeedPostCopyWith(FeedPost value, $Res Function(FeedPost) _then) = _$FeedPostCopyWithImpl;
@useResult
$Res call({
 String id, int categoryId, String title, String description, Money? budgetMin, Money? budgetMax, DateTime? neededBy, String? locality, String? city, String? state, RequestStatus status, int quoteCount, int commentCount, int likeCount, bool likedByMe, bool isMine, String authorName, String? authorPhotoUrl, DateTime? quoteWindowEndsAt, DateTime publishedAt, GroupBuy? group
});


$GroupBuyCopyWith<$Res>? get group;

}
/// @nodoc
class _$FeedPostCopyWithImpl<$Res>
    implements $FeedPostCopyWith<$Res> {
  _$FeedPostCopyWithImpl(this._self, this._then);

  final FeedPost _self;
  final $Res Function(FeedPost) _then;

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? neededBy = freezed,Object? locality = freezed,Object? city = freezed,Object? state = freezed,Object? status = null,Object? quoteCount = null,Object? commentCount = null,Object? likeCount = null,Object? likedByMe = null,Object? isMine = null,Object? authorName = null,Object? authorPhotoUrl = freezed,Object? quoteWindowEndsAt = freezed,Object? publishedAt = null,Object? group = freezed,}) {
  return _then(FeedPost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,likedByMe: null == likedByMe ? _self.likedByMe : likedByMe // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as GroupBuy?,
  ));
}
/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupBuyCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $GroupBuyCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}


/// Adds pattern-matching-related methods to [FeedPost].
extension FeedPostPatterns on FeedPost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedPost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedPost value)  $default,){
final _that = this;
switch (_that) {
case _FeedPost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedPost value)?  $default,){
final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int categoryId,  String title,  String description,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? city,  String? state,  RequestStatus status,  int quoteCount,  int commentCount,  int likeCount,  bool likedByMe,  bool isMine,  String authorName,  String? authorPhotoUrl,  DateTime? quoteWindowEndsAt,  DateTime publishedAt,  GroupBuy? group)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
return $default(_that.id,_that.categoryId,_that.title,_that.description,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.city,_that.state,_that.status,_that.quoteCount,_that.commentCount,_that.likeCount,_that.likedByMe,_that.isMine,_that.authorName,_that.authorPhotoUrl,_that.quoteWindowEndsAt,_that.publishedAt,_that.group);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int categoryId,  String title,  String description,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? city,  String? state,  RequestStatus status,  int quoteCount,  int commentCount,  int likeCount,  bool likedByMe,  bool isMine,  String authorName,  String? authorPhotoUrl,  DateTime? quoteWindowEndsAt,  DateTime publishedAt,  GroupBuy? group)  $default,) {final _that = this;
switch (_that) {
case _FeedPost():
return $default(_that.id,_that.categoryId,_that.title,_that.description,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.city,_that.state,_that.status,_that.quoteCount,_that.commentCount,_that.likeCount,_that.likedByMe,_that.isMine,_that.authorName,_that.authorPhotoUrl,_that.quoteWindowEndsAt,_that.publishedAt,_that.group);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int categoryId,  String title,  String description,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? city,  String? state,  RequestStatus status,  int quoteCount,  int commentCount,  int likeCount,  bool likedByMe,  bool isMine,  String authorName,  String? authorPhotoUrl,  DateTime? quoteWindowEndsAt,  DateTime publishedAt,  GroupBuy? group)?  $default,) {final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
return $default(_that.id,_that.categoryId,_that.title,_that.description,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.city,_that.state,_that.status,_that.quoteCount,_that.commentCount,_that.likeCount,_that.likedByMe,_that.isMine,_that.authorName,_that.authorPhotoUrl,_that.quoteWindowEndsAt,_that.publishedAt,_that.group);case _:
  return null;

}
}

}

/// @nodoc


class _FeedPost extends FeedPost {
  const _FeedPost({required this.id, required this.categoryId, required this.title, this.description = '', this.budgetMin, this.budgetMax, this.neededBy, this.locality, this.city, this.state, this.status = RequestStatus.open, this.quoteCount = 0, this.commentCount = 0, this.likeCount = 0, this.likedByMe = false, this.isMine = false, this.authorName = '', this.authorPhotoUrl, this.quoteWindowEndsAt, required this.publishedAt, this.group}): super._();
  

@override final  String id;
@override final  int categoryId;
@override final  String title;
@override@JsonKey() final  String description;
@override final  Money? budgetMin;
@override final  Money? budgetMax;
@override final  DateTime? neededBy;
@override final  String? locality;
@override final  String? city;
@override final  String? state;
@override@JsonKey() final  RequestStatus status;
@override@JsonKey() final  int quoteCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  bool likedByMe;
@override@JsonKey() final  bool isMine;
@override@JsonKey() final  String authorName;
@override final  String? authorPhotoUrl;
@override final  DateTime? quoteWindowEndsAt;
@override final  DateTime publishedAt;
@override final  GroupBuy? group;

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedPostCopyWith<_FeedPost> get copyWith => __$FeedPostCopyWithImpl<_FeedPost>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedPost&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.budgetMin, budgetMin) || other.budgetMin == budgetMin)&&(identical(other.budgetMax, budgetMax) || other.budgetMax == budgetMax)&&(identical(other.neededBy, neededBy) || other.neededBy == neededBy)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.status, status) || other.status == status)&&(identical(other.quoteCount, quoteCount) || other.quoteCount == quoteCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.likedByMe, likedByMe) || other.likedByMe == likedByMe)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorPhotoUrl, authorPhotoUrl) || other.authorPhotoUrl == authorPhotoUrl)&&(identical(other.quoteWindowEndsAt, quoteWindowEndsAt) || other.quoteWindowEndsAt == quoteWindowEndsAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,categoryId,title,description,budgetMin,budgetMax,neededBy,locality,city,state,status,quoteCount,commentCount,likeCount,likedByMe,isMine,authorName,authorPhotoUrl,quoteWindowEndsAt,publishedAt,group]);
}

@override
String toString() {
    return 'FeedPost(id: $id, categoryId: $categoryId, title: $title, description: $description, budgetMin: $budgetMin, budgetMax: $budgetMax, neededBy: $neededBy, locality: $locality, city: $city, state: $state, status: $status, quoteCount: $quoteCount, commentCount: $commentCount, likeCount: $likeCount, likedByMe: $likedByMe, isMine: $isMine, authorName: $authorName, authorPhotoUrl: $authorPhotoUrl, quoteWindowEndsAt: $quoteWindowEndsAt, publishedAt: $publishedAt, group: $group)';
}


}

/// @nodoc
abstract mixin class _$FeedPostCopyWith<$Res> implements $FeedPostCopyWith<$Res> {
  factory _$FeedPostCopyWith(_FeedPost value, $Res Function(_FeedPost) _then) = __$FeedPostCopyWithImpl;
@override @useResult
$Res call({
 String id, int categoryId, String title, String description, Money? budgetMin, Money? budgetMax, DateTime? neededBy, String? locality, String? city, String? state, RequestStatus status, int quoteCount, int commentCount, int likeCount, bool likedByMe, bool isMine, String authorName, String? authorPhotoUrl, DateTime? quoteWindowEndsAt, DateTime publishedAt, GroupBuy? group
});


@override $GroupBuyCopyWith<$Res>? get group;

}
/// @nodoc
class __$FeedPostCopyWithImpl<$Res>
    implements _$FeedPostCopyWith<$Res> {
  __$FeedPostCopyWithImpl(this._self, this._then);

  final _FeedPost _self;
  final $Res Function(_FeedPost) _then;

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? neededBy = freezed,Object? locality = freezed,Object? city = freezed,Object? state = freezed,Object? status = null,Object? quoteCount = null,Object? commentCount = null,Object? likeCount = null,Object? likedByMe = null,Object? isMine = null,Object? authorName = null,Object? authorPhotoUrl = freezed,Object? quoteWindowEndsAt = freezed,Object? publishedAt = null,Object? group = freezed,}) {
  return _then(_FeedPost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,likedByMe: null == likedByMe ? _self.likedByMe : likedByMe // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as GroupBuy?,
  ));
}

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupBuyCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $GroupBuyCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc
mixin _$FeedComment {

 String get id; String get requestId; String? get parentId; String get body; DateTime get createdAt; String get authorName; String? get authorPhotoUrl;/// Posted as a business: [sellerId] links the seller profile.
 bool get asSeller; String? get sellerId; bool get sellerVerified; bool get isMine; bool get isPostAuthor;
/// Create a copy of FeedComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedCommentCopyWith<FeedComment> get copyWith => _$FeedCommentCopyWithImpl<FeedComment>(this as FeedComment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FeedComment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedComment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.authorPhotoUrl, _this.authorPhotoUrl) || other.authorPhotoUrl == _this.authorPhotoUrl)&&(identical(other.asSeller, _this.asSeller) || other.asSeller == _this.asSeller)&&(identical(other.sellerId, _this.sellerId) || other.sellerId == _this.sellerId)&&(identical(other.sellerVerified, _this.sellerVerified) || other.sellerVerified == _this.sellerVerified)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.isPostAuthor, _this.isPostAuthor) || other.isPostAuthor == _this.isPostAuthor));
}


@override
int get hashCode {
  final _this = this as FeedComment;
  return Object.hash(runtimeType,_this.id,_this.requestId,_this.parentId,_this.body,_this.createdAt,_this.authorName,_this.authorPhotoUrl,_this.asSeller,_this.sellerId,_this.sellerVerified,_this.isMine,_this.isPostAuthor);
}

@override
String toString() {
  final _this = this as FeedComment;
  return 'FeedComment(id: ${_this.id}, requestId: ${_this.requestId}, parentId: ${_this.parentId}, body: ${_this.body}, createdAt: ${_this.createdAt}, authorName: ${_this.authorName}, authorPhotoUrl: ${_this.authorPhotoUrl}, asSeller: ${_this.asSeller}, sellerId: ${_this.sellerId}, sellerVerified: ${_this.sellerVerified}, isMine: ${_this.isMine}, isPostAuthor: ${_this.isPostAuthor})';
}


}

/// @nodoc
abstract mixin class $FeedCommentCopyWith<$Res>  {
  factory $FeedCommentCopyWith(FeedComment value, $Res Function(FeedComment) _then) = _$FeedCommentCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, String? parentId, String body, DateTime createdAt, String authorName, String? authorPhotoUrl, bool asSeller, String? sellerId, bool sellerVerified, bool isMine, bool isPostAuthor
});




}
/// @nodoc
class _$FeedCommentCopyWithImpl<$Res>
    implements $FeedCommentCopyWith<$Res> {
  _$FeedCommentCopyWithImpl(this._self, this._then);

  final FeedComment _self;
  final $Res Function(FeedComment) _then;

/// Create a copy of FeedComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? parentId = freezed,Object? body = null,Object? createdAt = null,Object? authorName = null,Object? authorPhotoUrl = freezed,Object? asSeller = null,Object? sellerId = freezed,Object? sellerVerified = null,Object? isMine = null,Object? isPostAuthor = null,}) {
  return _then(FeedComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,asSeller: null == asSeller ? _self.asSeller : asSeller // ignore: cast_nullable_to_non_nullable
as bool,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,sellerVerified: null == sellerVerified ? _self.sellerVerified : sellerVerified // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,isPostAuthor: null == isPostAuthor ? _self.isPostAuthor : isPostAuthor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedComment].
extension FeedCommentPatterns on FeedComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedComment value)  $default,){
final _that = this;
switch (_that) {
case _FeedComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedComment value)?  $default,){
final _that = this;
switch (_that) {
case _FeedComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requestId,  String? parentId,  String body,  DateTime createdAt,  String authorName,  String? authorPhotoUrl,  bool asSeller,  String? sellerId,  bool sellerVerified,  bool isMine,  bool isPostAuthor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedComment() when $default != null:
return $default(_that.id,_that.requestId,_that.parentId,_that.body,_that.createdAt,_that.authorName,_that.authorPhotoUrl,_that.asSeller,_that.sellerId,_that.sellerVerified,_that.isMine,_that.isPostAuthor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requestId,  String? parentId,  String body,  DateTime createdAt,  String authorName,  String? authorPhotoUrl,  bool asSeller,  String? sellerId,  bool sellerVerified,  bool isMine,  bool isPostAuthor)  $default,) {final _that = this;
switch (_that) {
case _FeedComment():
return $default(_that.id,_that.requestId,_that.parentId,_that.body,_that.createdAt,_that.authorName,_that.authorPhotoUrl,_that.asSeller,_that.sellerId,_that.sellerVerified,_that.isMine,_that.isPostAuthor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requestId,  String? parentId,  String body,  DateTime createdAt,  String authorName,  String? authorPhotoUrl,  bool asSeller,  String? sellerId,  bool sellerVerified,  bool isMine,  bool isPostAuthor)?  $default,) {final _that = this;
switch (_that) {
case _FeedComment() when $default != null:
return $default(_that.id,_that.requestId,_that.parentId,_that.body,_that.createdAt,_that.authorName,_that.authorPhotoUrl,_that.asSeller,_that.sellerId,_that.sellerVerified,_that.isMine,_that.isPostAuthor);case _:
  return null;

}
}

}

/// @nodoc


class _FeedComment implements FeedComment {
  const _FeedComment({required this.id, required this.requestId, this.parentId, required this.body, required this.createdAt, this.authorName = '', this.authorPhotoUrl, this.asSeller = false, this.sellerId, this.sellerVerified = false, this.isMine = false, this.isPostAuthor = false});
  

@override final  String id;
@override final  String requestId;
@override final  String? parentId;
@override final  String body;
@override final  DateTime createdAt;
@override@JsonKey() final  String authorName;
@override final  String? authorPhotoUrl;
/// Posted as a business: [sellerId] links the seller profile.
@override@JsonKey() final  bool asSeller;
@override final  String? sellerId;
@override@JsonKey() final  bool sellerVerified;
@override@JsonKey() final  bool isMine;
@override@JsonKey() final  bool isPostAuthor;

/// Create a copy of FeedComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedCommentCopyWith<_FeedComment> get copyWith => __$FeedCommentCopyWithImpl<_FeedComment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedComment&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorPhotoUrl, authorPhotoUrl) || other.authorPhotoUrl == authorPhotoUrl)&&(identical(other.asSeller, asSeller) || other.asSeller == asSeller)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerVerified, sellerVerified) || other.sellerVerified == sellerVerified)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.isPostAuthor, isPostAuthor) || other.isPostAuthor == isPostAuthor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,requestId,parentId,body,createdAt,authorName,authorPhotoUrl,asSeller,sellerId,sellerVerified,isMine,isPostAuthor);
}

@override
String toString() {
    return 'FeedComment(id: $id, requestId: $requestId, parentId: $parentId, body: $body, createdAt: $createdAt, authorName: $authorName, authorPhotoUrl: $authorPhotoUrl, asSeller: $asSeller, sellerId: $sellerId, sellerVerified: $sellerVerified, isMine: $isMine, isPostAuthor: $isPostAuthor)';
}


}

/// @nodoc
abstract mixin class _$FeedCommentCopyWith<$Res> implements $FeedCommentCopyWith<$Res> {
  factory _$FeedCommentCopyWith(_FeedComment value, $Res Function(_FeedComment) _then) = __$FeedCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, String? parentId, String body, DateTime createdAt, String authorName, String? authorPhotoUrl, bool asSeller, String? sellerId, bool sellerVerified, bool isMine, bool isPostAuthor
});




}
/// @nodoc
class __$FeedCommentCopyWithImpl<$Res>
    implements _$FeedCommentCopyWith<$Res> {
  __$FeedCommentCopyWithImpl(this._self, this._then);

  final _FeedComment _self;
  final $Res Function(_FeedComment) _then;

/// Create a copy of FeedComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? parentId = freezed,Object? body = null,Object? createdAt = null,Object? authorName = null,Object? authorPhotoUrl = freezed,Object? asSeller = null,Object? sellerId = freezed,Object? sellerVerified = null,Object? isMine = null,Object? isPostAuthor = null,}) {
  return _then(_FeedComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorPhotoUrl: freezed == authorPhotoUrl ? _self.authorPhotoUrl : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,asSeller: null == asSeller ? _self.asSeller : asSeller // ignore: cast_nullable_to_non_nullable
as bool,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,sellerVerified: null == sellerVerified ? _self.sellerVerified : sellerVerified // ignore: cast_nullable_to_non_nullable
as bool,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,isPostAuthor: null == isPostAuthor ? _self.isPostAuthor : isPostAuthor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GroupMember {

 String get userId; String get name; num get qty; String? get note; String? get phone;
/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMemberCopyWith<GroupMember> get copyWith => _$GroupMemberCopyWithImpl<GroupMember>(this as GroupMember, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMember&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.qty, _this.qty) || other.qty == _this.qty)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.phone, _this.phone) || other.phone == _this.phone));
}


@override
int get hashCode {
  final _this = this as GroupMember;
  return Object.hash(runtimeType,_this.userId,_this.name,_this.qty,_this.note,_this.phone);
}

@override
String toString() {
  final _this = this as GroupMember;
  return 'GroupMember(userId: ${_this.userId}, name: ${_this.name}, qty: ${_this.qty}, note: ${_this.note}, phone: ${_this.phone})';
}


}

/// @nodoc
abstract mixin class $GroupMemberCopyWith<$Res>  {
  factory $GroupMemberCopyWith(GroupMember value, $Res Function(GroupMember) _then) = _$GroupMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String name, num qty, String? note, String? phone
});




}
/// @nodoc
class _$GroupMemberCopyWithImpl<$Res>
    implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._self, this._then);

  final GroupMember _self;
  final $Res Function(GroupMember) _then;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? qty = null,Object? note = freezed,Object? phone = freezed,}) {
  return _then(GroupMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as num,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMember].
extension GroupMemberPatterns on GroupMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMember value)  $default,){
final _that = this;
switch (_that) {
case _GroupMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMember value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  num qty,  String? note,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
return $default(_that.userId,_that.name,_that.qty,_that.note,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  num qty,  String? note,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _GroupMember():
return $default(_that.userId,_that.name,_that.qty,_that.note,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  num qty,  String? note,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _GroupMember() when $default != null:
return $default(_that.userId,_that.name,_that.qty,_that.note,_that.phone);case _:
  return null;

}
}

}

/// @nodoc


class _GroupMember implements GroupMember {
  const _GroupMember({required this.userId, required this.name, required this.qty, this.note, this.phone});
  

@override final  String userId;
@override final  String name;
@override final  num qty;
@override final  String? note;
@override final  String? phone;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMemberCopyWith<_GroupMember> get copyWith => __$GroupMemberCopyWithImpl<_GroupMember>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.note, note) || other.note == note)&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,name,qty,note,phone);
}

@override
String toString() {
    return 'GroupMember(userId: $userId, name: $name, qty: $qty, note: $note, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$GroupMemberCopyWith<$Res> implements $GroupMemberCopyWith<$Res> {
  factory _$GroupMemberCopyWith(_GroupMember value, $Res Function(_GroupMember) _then) = __$GroupMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, num qty, String? note, String? phone
});




}
/// @nodoc
class __$GroupMemberCopyWithImpl<$Res>
    implements _$GroupMemberCopyWith<$Res> {
  __$GroupMemberCopyWithImpl(this._self, this._then);

  final _GroupMember _self;
  final $Res Function(_GroupMember) _then;

/// Create a copy of GroupMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? qty = null,Object? note = freezed,Object? phone = freezed,}) {
  return _then(_GroupMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as num,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
