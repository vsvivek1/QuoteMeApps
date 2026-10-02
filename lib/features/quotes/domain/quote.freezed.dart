// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SellerSummary {

 String get id; String get businessName; String? get logoUrl; double get ratingAvg; int get ratingCount; bool get verified; int? get avgResponseMins; double? get distanceKm; bool get earlyPartner;
/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<SellerSummary> get copyWith => _$SellerSummaryCopyWithImpl<SellerSummary>(this as SellerSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SellerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.businessName, _this.businessName) || other.businessName == _this.businessName)&&(identical(other.logoUrl, _this.logoUrl) || other.logoUrl == _this.logoUrl)&&(identical(other.ratingAvg, _this.ratingAvg) || other.ratingAvg == _this.ratingAvg)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.avgResponseMins, _this.avgResponseMins) || other.avgResponseMins == _this.avgResponseMins)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.earlyPartner, _this.earlyPartner) || other.earlyPartner == _this.earlyPartner));
}


@override
int get hashCode {
  final _this = this as SellerSummary;
  return Object.hash(runtimeType,_this.id,_this.businessName,_this.logoUrl,_this.ratingAvg,_this.ratingCount,_this.verified,_this.avgResponseMins,_this.distanceKm,_this.earlyPartner);
}

@override
String toString() {
  final _this = this as SellerSummary;
  return 'SellerSummary(id: ${_this.id}, businessName: ${_this.businessName}, logoUrl: ${_this.logoUrl}, ratingAvg: ${_this.ratingAvg}, ratingCount: ${_this.ratingCount}, verified: ${_this.verified}, avgResponseMins: ${_this.avgResponseMins}, distanceKm: ${_this.distanceKm}, earlyPartner: ${_this.earlyPartner})';
}


}

/// @nodoc
abstract mixin class $SellerSummaryCopyWith<$Res>  {
  factory $SellerSummaryCopyWith(SellerSummary value, $Res Function(SellerSummary) _then) = _$SellerSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String businessName, String? logoUrl, double ratingAvg, int ratingCount, bool verified, int? avgResponseMins, double? distanceKm, bool earlyPartner
});




}
/// @nodoc
class _$SellerSummaryCopyWithImpl<$Res>
    implements $SellerSummaryCopyWith<$Res> {
  _$SellerSummaryCopyWithImpl(this._self, this._then);

  final SellerSummary _self;
  final $Res Function(SellerSummary) _then;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessName = null,Object? logoUrl = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? verified = null,Object? avgResponseMins = freezed,Object? distanceKm = freezed,Object? earlyPartner = null,}) {
  return _then(SellerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,earlyPartner: null == earlyPartner ? _self.earlyPartner : earlyPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerSummary].
extension SellerSummaryPatterns on SellerSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerSummary value)  $default,){
final _that = this;
switch (_that) {
case _SellerSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessName,  String? logoUrl,  double ratingAvg,  int ratingCount,  bool verified,  int? avgResponseMins,  double? distanceKm,  bool earlyPartner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that.id,_that.businessName,_that.logoUrl,_that.ratingAvg,_that.ratingCount,_that.verified,_that.avgResponseMins,_that.distanceKm,_that.earlyPartner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessName,  String? logoUrl,  double ratingAvg,  int ratingCount,  bool verified,  int? avgResponseMins,  double? distanceKm,  bool earlyPartner)  $default,) {final _that = this;
switch (_that) {
case _SellerSummary():
return $default(_that.id,_that.businessName,_that.logoUrl,_that.ratingAvg,_that.ratingCount,_that.verified,_that.avgResponseMins,_that.distanceKm,_that.earlyPartner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessName,  String? logoUrl,  double ratingAvg,  int ratingCount,  bool verified,  int? avgResponseMins,  double? distanceKm,  bool earlyPartner)?  $default,) {final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that.id,_that.businessName,_that.logoUrl,_that.ratingAvg,_that.ratingCount,_that.verified,_that.avgResponseMins,_that.distanceKm,_that.earlyPartner);case _:
  return null;

}
}

}

/// @nodoc


class _SellerSummary implements SellerSummary {
  const _SellerSummary({required this.id, required this.businessName, this.logoUrl, this.ratingAvg = 0, this.ratingCount = 0, this.verified = false, this.avgResponseMins, this.distanceKm, this.earlyPartner = false});
  

@override final  String id;
@override final  String businessName;
@override final  String? logoUrl;
@override@JsonKey() final  double ratingAvg;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  bool verified;
@override final  int? avgResponseMins;
@override final  double? distanceKm;
@override@JsonKey() final  bool earlyPartner;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerSummaryCopyWith<_SellerSummary> get copyWith => __$SellerSummaryCopyWithImpl<_SellerSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.ratingAvg, ratingAvg) || other.ratingAvg == ratingAvg)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.avgResponseMins, avgResponseMins) || other.avgResponseMins == avgResponseMins)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.earlyPartner, earlyPartner) || other.earlyPartner == earlyPartner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,businessName,logoUrl,ratingAvg,ratingCount,verified,avgResponseMins,distanceKm,earlyPartner);
}

@override
String toString() {
    return 'SellerSummary(id: $id, businessName: $businessName, logoUrl: $logoUrl, ratingAvg: $ratingAvg, ratingCount: $ratingCount, verified: $verified, avgResponseMins: $avgResponseMins, distanceKm: $distanceKm, earlyPartner: $earlyPartner)';
}


}

/// @nodoc
abstract mixin class _$SellerSummaryCopyWith<$Res> implements $SellerSummaryCopyWith<$Res> {
  factory _$SellerSummaryCopyWith(_SellerSummary value, $Res Function(_SellerSummary) _then) = __$SellerSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessName, String? logoUrl, double ratingAvg, int ratingCount, bool verified, int? avgResponseMins, double? distanceKm, bool earlyPartner
});




}
/// @nodoc
class __$SellerSummaryCopyWithImpl<$Res>
    implements _$SellerSummaryCopyWith<$Res> {
  __$SellerSummaryCopyWithImpl(this._self, this._then);

  final _SellerSummary _self;
  final $Res Function(_SellerSummary) _then;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessName = null,Object? logoUrl = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? verified = null,Object? avgResponseMins = freezed,Object? distanceKm = freezed,Object? earlyPartner = null,}) {
  return _then(_SellerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,earlyPartner: null == earlyPartner ? _self.earlyPartner : earlyPartner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Quote {

 String get id; String get requestId; SellerSummary get seller; List<QuoteLine> get lines; Money get subtotal; Money get tax; TaxBreakdown get taxBreakdown; Money get delivery; Money get total; String? get offeredBrandModel; DateTime? get deliveryDate; String? get warranty; DateTime? get validUntil; String? get notes; QuoteStatus get status; Money? get counterOfferTarget; String? get counterOfferNote; String? get declineReason; DateTime get createdAt; DateTime? get updatedAt; bool get viewedByBuyer;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Quote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.seller, _this.seller) || other.seller == _this.seller)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.subtotal, _this.subtotal) || other.subtotal == _this.subtotal)&&(identical(other.tax, _this.tax) || other.tax == _this.tax)&&(identical(other.taxBreakdown, _this.taxBreakdown) || other.taxBreakdown == _this.taxBreakdown)&&(identical(other.delivery, _this.delivery) || other.delivery == _this.delivery)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.offeredBrandModel, _this.offeredBrandModel) || other.offeredBrandModel == _this.offeredBrandModel)&&(identical(other.deliveryDate, _this.deliveryDate) || other.deliveryDate == _this.deliveryDate)&&(identical(other.warranty, _this.warranty) || other.warranty == _this.warranty)&&(identical(other.validUntil, _this.validUntil) || other.validUntil == _this.validUntil)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.counterOfferTarget, _this.counterOfferTarget) || other.counterOfferTarget == _this.counterOfferTarget)&&(identical(other.counterOfferNote, _this.counterOfferNote) || other.counterOfferNote == _this.counterOfferNote)&&(identical(other.declineReason, _this.declineReason) || other.declineReason == _this.declineReason)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.viewedByBuyer, _this.viewedByBuyer) || other.viewedByBuyer == _this.viewedByBuyer));
}


@override
int get hashCode {
  final _this = this as Quote;
  return Object.hashAll([runtimeType,_this.id,_this.requestId,_this.seller,const DeepCollectionEquality().hash(_this.lines),_this.subtotal,_this.tax,_this.taxBreakdown,_this.delivery,_this.total,_this.offeredBrandModel,_this.deliveryDate,_this.warranty,_this.validUntil,_this.notes,_this.status,_this.counterOfferTarget,_this.counterOfferNote,_this.declineReason,_this.createdAt,_this.updatedAt,_this.viewedByBuyer]);
}

@override
String toString() {
  final _this = this as Quote;
  return 'Quote(id: ${_this.id}, requestId: ${_this.requestId}, seller: ${_this.seller}, lines: ${_this.lines}, subtotal: ${_this.subtotal}, tax: ${_this.tax}, taxBreakdown: ${_this.taxBreakdown}, delivery: ${_this.delivery}, total: ${_this.total}, offeredBrandModel: ${_this.offeredBrandModel}, deliveryDate: ${_this.deliveryDate}, warranty: ${_this.warranty}, validUntil: ${_this.validUntil}, notes: ${_this.notes}, status: ${_this.status}, counterOfferTarget: ${_this.counterOfferTarget}, counterOfferNote: ${_this.counterOfferNote}, declineReason: ${_this.declineReason}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, viewedByBuyer: ${_this.viewedByBuyer})';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, SellerSummary seller, List<QuoteLine> lines, Money subtotal, Money tax, TaxBreakdown taxBreakdown, Money delivery, Money total, String? offeredBrandModel, DateTime? deliveryDate, String? warranty, DateTime? validUntil, String? notes, QuoteStatus status, Money? counterOfferTarget, String? counterOfferNote, String? declineReason, DateTime createdAt, DateTime? updatedAt, bool viewedByBuyer
});


$SellerSummaryCopyWith<$Res> get seller;

}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? seller = null,Object? lines = null,Object? subtotal = null,Object? tax = null,Object? taxBreakdown = null,Object? delivery = null,Object? total = null,Object? offeredBrandModel = freezed,Object? deliveryDate = freezed,Object? warranty = freezed,Object? validUntil = freezed,Object? notes = freezed,Object? status = null,Object? counterOfferTarget = freezed,Object? counterOfferNote = freezed,Object? declineReason = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? viewedByBuyer = null,}) {
  return _then(Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,seller: null == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as SellerSummary,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuoteLine>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as Money,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as Money,taxBreakdown: null == taxBreakdown ? _self.taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,offeredBrandModel: freezed == offeredBrandModel ? _self.offeredBrandModel : offeredBrandModel // ignore: cast_nullable_to_non_nullable
as String?,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warranty: freezed == warranty ? _self.warranty : warranty // ignore: cast_nullable_to_non_nullable
as String?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuoteStatus,counterOfferTarget: freezed == counterOfferTarget ? _self.counterOfferTarget : counterOfferTarget // ignore: cast_nullable_to_non_nullable
as Money?,counterOfferNote: freezed == counterOfferNote ? _self.counterOfferNote : counterOfferNote // ignore: cast_nullable_to_non_nullable
as String?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewedByBuyer: null == viewedByBuyer ? _self.viewedByBuyer : viewedByBuyer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<$Res> get seller {
  
  return $SellerSummaryCopyWith<$Res>(_self.seller, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requestId,  SellerSummary seller,  List<QuoteLine> lines,  Money subtotal,  Money tax,  TaxBreakdown taxBreakdown,  Money delivery,  Money total,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  DateTime? validUntil,  String? notes,  QuoteStatus status,  Money? counterOfferTarget,  String? counterOfferNote,  String? declineReason,  DateTime createdAt,  DateTime? updatedAt,  bool viewedByBuyer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.requestId,_that.seller,_that.lines,_that.subtotal,_that.tax,_that.taxBreakdown,_that.delivery,_that.total,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validUntil,_that.notes,_that.status,_that.counterOfferTarget,_that.counterOfferNote,_that.declineReason,_that.createdAt,_that.updatedAt,_that.viewedByBuyer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requestId,  SellerSummary seller,  List<QuoteLine> lines,  Money subtotal,  Money tax,  TaxBreakdown taxBreakdown,  Money delivery,  Money total,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  DateTime? validUntil,  String? notes,  QuoteStatus status,  Money? counterOfferTarget,  String? counterOfferNote,  String? declineReason,  DateTime createdAt,  DateTime? updatedAt,  bool viewedByBuyer)  $default,) {final _that = this;
switch (_that) {
case _Quote():
return $default(_that.id,_that.requestId,_that.seller,_that.lines,_that.subtotal,_that.tax,_that.taxBreakdown,_that.delivery,_that.total,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validUntil,_that.notes,_that.status,_that.counterOfferTarget,_that.counterOfferNote,_that.declineReason,_that.createdAt,_that.updatedAt,_that.viewedByBuyer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requestId,  SellerSummary seller,  List<QuoteLine> lines,  Money subtotal,  Money tax,  TaxBreakdown taxBreakdown,  Money delivery,  Money total,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  DateTime? validUntil,  String? notes,  QuoteStatus status,  Money? counterOfferTarget,  String? counterOfferNote,  String? declineReason,  DateTime createdAt,  DateTime? updatedAt,  bool viewedByBuyer)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.requestId,_that.seller,_that.lines,_that.subtotal,_that.tax,_that.taxBreakdown,_that.delivery,_that.total,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validUntil,_that.notes,_that.status,_that.counterOfferTarget,_that.counterOfferNote,_that.declineReason,_that.createdAt,_that.updatedAt,_that.viewedByBuyer);case _:
  return null;

}
}

}

/// @nodoc


class _Quote extends Quote {
  const _Quote({required this.id, required this.requestId, required this.seller,  List<QuoteLine> lines = const [], required this.subtotal, required this.tax, this.taxBreakdown = const NoTaxBreakdown(), required this.delivery, required this.total, this.offeredBrandModel, this.deliveryDate, this.warranty, this.validUntil, this.notes, this.status = QuoteStatus.sent, this.counterOfferTarget, this.counterOfferNote, this.declineReason, required this.createdAt, this.updatedAt, this.viewedByBuyer = false}): _lines = lines,super._();
  

@override final  String id;
@override final  String requestId;
@override final  SellerSummary seller;
 final  List<QuoteLine> _lines;
@override@JsonKey() List<QuoteLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  Money subtotal;
@override final  Money tax;
@override@JsonKey() final  TaxBreakdown taxBreakdown;
@override final  Money delivery;
@override final  Money total;
@override final  String? offeredBrandModel;
@override final  DateTime? deliveryDate;
@override final  String? warranty;
@override final  DateTime? validUntil;
@override final  String? notes;
@override@JsonKey() final  QuoteStatus status;
@override final  Money? counterOfferTarget;
@override final  String? counterOfferNote;
@override final  String? declineReason;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;
@override@JsonKey() final  bool viewedByBuyer;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.seller, seller) || other.seller == seller)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.taxBreakdown, taxBreakdown) || other.taxBreakdown == taxBreakdown)&&(identical(other.delivery, delivery) || other.delivery == delivery)&&(identical(other.total, total) || other.total == total)&&(identical(other.offeredBrandModel, offeredBrandModel) || other.offeredBrandModel == offeredBrandModel)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.warranty, warranty) || other.warranty == warranty)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.counterOfferTarget, counterOfferTarget) || other.counterOfferTarget == counterOfferTarget)&&(identical(other.counterOfferNote, counterOfferNote) || other.counterOfferNote == counterOfferNote)&&(identical(other.declineReason, declineReason) || other.declineReason == declineReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.viewedByBuyer, viewedByBuyer) || other.viewedByBuyer == viewedByBuyer));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,requestId,seller,const DeepCollectionEquality().hash(_lines),subtotal,tax,taxBreakdown,delivery,total,offeredBrandModel,deliveryDate,warranty,validUntil,notes,status,counterOfferTarget,counterOfferNote,declineReason,createdAt,updatedAt,viewedByBuyer]);
}

@override
String toString() {
    return 'Quote(id: $id, requestId: $requestId, seller: $seller, lines: $lines, subtotal: $subtotal, tax: $tax, taxBreakdown: $taxBreakdown, delivery: $delivery, total: $total, offeredBrandModel: $offeredBrandModel, deliveryDate: $deliveryDate, warranty: $warranty, validUntil: $validUntil, notes: $notes, status: $status, counterOfferTarget: $counterOfferTarget, counterOfferNote: $counterOfferNote, declineReason: $declineReason, createdAt: $createdAt, updatedAt: $updatedAt, viewedByBuyer: $viewedByBuyer)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, SellerSummary seller, List<QuoteLine> lines, Money subtotal, Money tax, TaxBreakdown taxBreakdown, Money delivery, Money total, String? offeredBrandModel, DateTime? deliveryDate, String? warranty, DateTime? validUntil, String? notes, QuoteStatus status, Money? counterOfferTarget, String? counterOfferNote, String? declineReason, DateTime createdAt, DateTime? updatedAt, bool viewedByBuyer
});


@override $SellerSummaryCopyWith<$Res> get seller;

}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? seller = null,Object? lines = null,Object? subtotal = null,Object? tax = null,Object? taxBreakdown = null,Object? delivery = null,Object? total = null,Object? offeredBrandModel = freezed,Object? deliveryDate = freezed,Object? warranty = freezed,Object? validUntil = freezed,Object? notes = freezed,Object? status = null,Object? counterOfferTarget = freezed,Object? counterOfferNote = freezed,Object? declineReason = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? viewedByBuyer = null,}) {
  return _then(_Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,seller: null == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as SellerSummary,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuoteLine>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as Money,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as Money,taxBreakdown: null == taxBreakdown ? _self.taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as TaxBreakdown,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,offeredBrandModel: freezed == offeredBrandModel ? _self.offeredBrandModel : offeredBrandModel // ignore: cast_nullable_to_non_nullable
as String?,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warranty: freezed == warranty ? _self.warranty : warranty // ignore: cast_nullable_to_non_nullable
as String?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuoteStatus,counterOfferTarget: freezed == counterOfferTarget ? _self.counterOfferTarget : counterOfferTarget // ignore: cast_nullable_to_non_nullable
as Money?,counterOfferNote: freezed == counterOfferNote ? _self.counterOfferNote : counterOfferNote // ignore: cast_nullable_to_non_nullable
as String?,declineReason: freezed == declineReason ? _self.declineReason : declineReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewedByBuyer: null == viewedByBuyer ? _self.viewedByBuyer : viewedByBuyer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<$Res> get seller {
  
  return $SellerSummaryCopyWith<$Res>(_self.seller, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}

/// @nodoc
mixin _$QuoteDraft {

 String get requestId; List<QuoteLine> get lines; Money get delivery;/// India: GST rate in basis points (sent per line).
 int get taxRateBp;/// USA: sales tax rate in parts per million (8.875% = 88750).
 int get salesTaxRatePpm; String? get offeredBrandModel; DateTime? get deliveryDate; String? get warranty; int get validDays; String? get notes; List<String> get attachmentPaths;
/// Create a copy of QuoteDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteDraftCopyWith<QuoteDraft> get copyWith => _$QuoteDraftCopyWithImpl<QuoteDraft>(this as QuoteDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QuoteDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteDraft&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.delivery, _this.delivery) || other.delivery == _this.delivery)&&(identical(other.taxRateBp, _this.taxRateBp) || other.taxRateBp == _this.taxRateBp)&&(identical(other.salesTaxRatePpm, _this.salesTaxRatePpm) || other.salesTaxRatePpm == _this.salesTaxRatePpm)&&(identical(other.offeredBrandModel, _this.offeredBrandModel) || other.offeredBrandModel == _this.offeredBrandModel)&&(identical(other.deliveryDate, _this.deliveryDate) || other.deliveryDate == _this.deliveryDate)&&(identical(other.warranty, _this.warranty) || other.warranty == _this.warranty)&&(identical(other.validDays, _this.validDays) || other.validDays == _this.validDays)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.attachmentPaths, _this.attachmentPaths));
}


@override
int get hashCode {
  final _this = this as QuoteDraft;
  return Object.hash(runtimeType,_this.requestId,const DeepCollectionEquality().hash(_this.lines),_this.delivery,_this.taxRateBp,_this.salesTaxRatePpm,_this.offeredBrandModel,_this.deliveryDate,_this.warranty,_this.validDays,_this.notes,const DeepCollectionEquality().hash(_this.attachmentPaths));
}

@override
String toString() {
  final _this = this as QuoteDraft;
  return 'QuoteDraft(requestId: ${_this.requestId}, lines: ${_this.lines}, delivery: ${_this.delivery}, taxRateBp: ${_this.taxRateBp}, salesTaxRatePpm: ${_this.salesTaxRatePpm}, offeredBrandModel: ${_this.offeredBrandModel}, deliveryDate: ${_this.deliveryDate}, warranty: ${_this.warranty}, validDays: ${_this.validDays}, notes: ${_this.notes}, attachmentPaths: ${_this.attachmentPaths})';
}


}

/// @nodoc
abstract mixin class $QuoteDraftCopyWith<$Res>  {
  factory $QuoteDraftCopyWith(QuoteDraft value, $Res Function(QuoteDraft) _then) = _$QuoteDraftCopyWithImpl;
@useResult
$Res call({
 String requestId, List<QuoteLine> lines, Money delivery, int taxRateBp, int salesTaxRatePpm, String? offeredBrandModel, DateTime? deliveryDate, String? warranty, int validDays, String? notes, List<String> attachmentPaths
});




}
/// @nodoc
class _$QuoteDraftCopyWithImpl<$Res>
    implements $QuoteDraftCopyWith<$Res> {
  _$QuoteDraftCopyWithImpl(this._self, this._then);

  final QuoteDraft _self;
  final $Res Function(QuoteDraft) _then;

/// Create a copy of QuoteDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? lines = null,Object? delivery = null,Object? taxRateBp = null,Object? salesTaxRatePpm = null,Object? offeredBrandModel = freezed,Object? deliveryDate = freezed,Object? warranty = freezed,Object? validDays = null,Object? notes = freezed,Object? attachmentPaths = null,}) {
  return _then(QuoteDraft(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuoteLine>,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Money,taxRateBp: null == taxRateBp ? _self.taxRateBp : taxRateBp // ignore: cast_nullable_to_non_nullable
as int,salesTaxRatePpm: null == salesTaxRatePpm ? _self.salesTaxRatePpm : salesTaxRatePpm // ignore: cast_nullable_to_non_nullable
as int,offeredBrandModel: freezed == offeredBrandModel ? _self.offeredBrandModel : offeredBrandModel // ignore: cast_nullable_to_non_nullable
as String?,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warranty: freezed == warranty ? _self.warranty : warranty // ignore: cast_nullable_to_non_nullable
as String?,validDays: null == validDays ? _self.validDays : validDays // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentPaths: null == attachmentPaths ? _self.attachmentPaths : attachmentPaths // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteDraft].
extension QuoteDraftPatterns on QuoteDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteDraft value)  $default,){
final _that = this;
switch (_that) {
case _QuoteDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteDraft value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  List<QuoteLine> lines,  Money delivery,  int taxRateBp,  int salesTaxRatePpm,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  int validDays,  String? notes,  List<String> attachmentPaths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteDraft() when $default != null:
return $default(_that.requestId,_that.lines,_that.delivery,_that.taxRateBp,_that.salesTaxRatePpm,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validDays,_that.notes,_that.attachmentPaths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  List<QuoteLine> lines,  Money delivery,  int taxRateBp,  int salesTaxRatePpm,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  int validDays,  String? notes,  List<String> attachmentPaths)  $default,) {final _that = this;
switch (_that) {
case _QuoteDraft():
return $default(_that.requestId,_that.lines,_that.delivery,_that.taxRateBp,_that.salesTaxRatePpm,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validDays,_that.notes,_that.attachmentPaths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  List<QuoteLine> lines,  Money delivery,  int taxRateBp,  int salesTaxRatePpm,  String? offeredBrandModel,  DateTime? deliveryDate,  String? warranty,  int validDays,  String? notes,  List<String> attachmentPaths)?  $default,) {final _that = this;
switch (_that) {
case _QuoteDraft() when $default != null:
return $default(_that.requestId,_that.lines,_that.delivery,_that.taxRateBp,_that.salesTaxRatePpm,_that.offeredBrandModel,_that.deliveryDate,_that.warranty,_that.validDays,_that.notes,_that.attachmentPaths);case _:
  return null;

}
}

}

/// @nodoc


class _QuoteDraft implements QuoteDraft {
  const _QuoteDraft({required this.requestId, required  List<QuoteLine> lines, required this.delivery, this.taxRateBp = 0, this.salesTaxRatePpm = 0, this.offeredBrandModel, this.deliveryDate, this.warranty, required this.validDays, this.notes,  List<String> attachmentPaths = const []}): _lines = lines,_attachmentPaths = attachmentPaths;
  

@override final  String requestId;
 final  List<QuoteLine> _lines;
@override List<QuoteLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  Money delivery;
/// India: GST rate in basis points (sent per line).
@override@JsonKey() final  int taxRateBp;
/// USA: sales tax rate in parts per million (8.875% = 88750).
@override@JsonKey() final  int salesTaxRatePpm;
@override final  String? offeredBrandModel;
@override final  DateTime? deliveryDate;
@override final  String? warranty;
@override final  int validDays;
@override final  String? notes;
 final  List<String> _attachmentPaths;
@override@JsonKey() List<String> get attachmentPaths {
  if (_attachmentPaths is EqualUnmodifiableListView) return _attachmentPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachmentPaths);
}


/// Create a copy of QuoteDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteDraftCopyWith<_QuoteDraft> get copyWith => __$QuoteDraftCopyWithImpl<_QuoteDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteDraft&&(identical(other.requestId, requestId) || other.requestId == requestId)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.delivery, delivery) || other.delivery == delivery)&&(identical(other.taxRateBp, taxRateBp) || other.taxRateBp == taxRateBp)&&(identical(other.salesTaxRatePpm, salesTaxRatePpm) || other.salesTaxRatePpm == salesTaxRatePpm)&&(identical(other.offeredBrandModel, offeredBrandModel) || other.offeredBrandModel == offeredBrandModel)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.warranty, warranty) || other.warranty == warranty)&&(identical(other.validDays, validDays) || other.validDays == validDays)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.attachmentPaths, _attachmentPaths));
}


@override
int get hashCode {
    return Object.hash(runtimeType,requestId,const DeepCollectionEquality().hash(_lines),delivery,taxRateBp,salesTaxRatePpm,offeredBrandModel,deliveryDate,warranty,validDays,notes,const DeepCollectionEquality().hash(_attachmentPaths));
}

@override
String toString() {
    return 'QuoteDraft(requestId: $requestId, lines: $lines, delivery: $delivery, taxRateBp: $taxRateBp, salesTaxRatePpm: $salesTaxRatePpm, offeredBrandModel: $offeredBrandModel, deliveryDate: $deliveryDate, warranty: $warranty, validDays: $validDays, notes: $notes, attachmentPaths: $attachmentPaths)';
}


}

/// @nodoc
abstract mixin class _$QuoteDraftCopyWith<$Res> implements $QuoteDraftCopyWith<$Res> {
  factory _$QuoteDraftCopyWith(_QuoteDraft value, $Res Function(_QuoteDraft) _then) = __$QuoteDraftCopyWithImpl;
@override @useResult
$Res call({
 String requestId, List<QuoteLine> lines, Money delivery, int taxRateBp, int salesTaxRatePpm, String? offeredBrandModel, DateTime? deliveryDate, String? warranty, int validDays, String? notes, List<String> attachmentPaths
});




}
/// @nodoc
class __$QuoteDraftCopyWithImpl<$Res>
    implements _$QuoteDraftCopyWith<$Res> {
  __$QuoteDraftCopyWithImpl(this._self, this._then);

  final _QuoteDraft _self;
  final $Res Function(_QuoteDraft) _then;

/// Create a copy of QuoteDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? lines = null,Object? delivery = null,Object? taxRateBp = null,Object? salesTaxRatePpm = null,Object? offeredBrandModel = freezed,Object? deliveryDate = freezed,Object? warranty = freezed,Object? validDays = null,Object? notes = freezed,Object? attachmentPaths = null,}) {
  return _then(_QuoteDraft(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuoteLine>,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as Money,taxRateBp: null == taxRateBp ? _self.taxRateBp : taxRateBp // ignore: cast_nullable_to_non_nullable
as int,salesTaxRatePpm: null == salesTaxRatePpm ? _self.salesTaxRatePpm : salesTaxRatePpm // ignore: cast_nullable_to_non_nullable
as int,offeredBrandModel: freezed == offeredBrandModel ? _self.offeredBrandModel : offeredBrandModel // ignore: cast_nullable_to_non_nullable
as String?,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warranty: freezed == warranty ? _self.warranty : warranty // ignore: cast_nullable_to_non_nullable
as String?,validDays: null == validDays ? _self.validDays : validDays // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentPaths: null == attachmentPaths ? _self._attachmentPaths : attachmentPaths // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
