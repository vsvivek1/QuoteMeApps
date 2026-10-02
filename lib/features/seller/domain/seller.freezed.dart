// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Seller {

 String get id; String get businessName; String? get logoUrl; List<String> get photos; String get description; int? get yearsInBusiness; List<String> get brands; List<int> get categoryIds; AreaType get areaType; double? get lat; double? get lng; int get radiusKm; List<String> get serviceCodes; String? get state; String? get locality; VerificationStatus get verificationStatus; DateTime? get verifiedAt; double get ratingAvg; int get ratingCount; int get quotesSent; int get quotesWon; int? get avgResponseMins; NotifyPreference get notifyPreference; int? get quietStartHour; int? get quietEndHour; bool get earlyPartner; DateTime? get freeUntil; String? get phone;
/// Create a copy of Seller
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerCopyWith<Seller> get copyWith => _$SellerCopyWithImpl<Seller>(this as Seller, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Seller;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Seller&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.businessName, _this.businessName) || other.businessName == _this.businessName)&&(identical(other.logoUrl, _this.logoUrl) || other.logoUrl == _this.logoUrl)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.yearsInBusiness, _this.yearsInBusiness) || other.yearsInBusiness == _this.yearsInBusiness)&&const DeepCollectionEquality().equals(other.brands, _this.brands)&&const DeepCollectionEquality().equals(other.categoryIds, _this.categoryIds)&&(identical(other.areaType, _this.areaType) || other.areaType == _this.areaType)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.radiusKm, _this.radiusKm) || other.radiusKm == _this.radiusKm)&&const DeepCollectionEquality().equals(other.serviceCodes, _this.serviceCodes)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.locality, _this.locality) || other.locality == _this.locality)&&(identical(other.verificationStatus, _this.verificationStatus) || other.verificationStatus == _this.verificationStatus)&&(identical(other.verifiedAt, _this.verifiedAt) || other.verifiedAt == _this.verifiedAt)&&(identical(other.ratingAvg, _this.ratingAvg) || other.ratingAvg == _this.ratingAvg)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.quotesSent, _this.quotesSent) || other.quotesSent == _this.quotesSent)&&(identical(other.quotesWon, _this.quotesWon) || other.quotesWon == _this.quotesWon)&&(identical(other.avgResponseMins, _this.avgResponseMins) || other.avgResponseMins == _this.avgResponseMins)&&(identical(other.notifyPreference, _this.notifyPreference) || other.notifyPreference == _this.notifyPreference)&&(identical(other.quietStartHour, _this.quietStartHour) || other.quietStartHour == _this.quietStartHour)&&(identical(other.quietEndHour, _this.quietEndHour) || other.quietEndHour == _this.quietEndHour)&&(identical(other.earlyPartner, _this.earlyPartner) || other.earlyPartner == _this.earlyPartner)&&(identical(other.freeUntil, _this.freeUntil) || other.freeUntil == _this.freeUntil)&&(identical(other.phone, _this.phone) || other.phone == _this.phone));
}


@override
int get hashCode {
  final _this = this as Seller;
  return Object.hashAll([runtimeType,_this.id,_this.businessName,_this.logoUrl,const DeepCollectionEquality().hash(_this.photos),_this.description,_this.yearsInBusiness,const DeepCollectionEquality().hash(_this.brands),const DeepCollectionEquality().hash(_this.categoryIds),_this.areaType,_this.lat,_this.lng,_this.radiusKm,const DeepCollectionEquality().hash(_this.serviceCodes),_this.state,_this.locality,_this.verificationStatus,_this.verifiedAt,_this.ratingAvg,_this.ratingCount,_this.quotesSent,_this.quotesWon,_this.avgResponseMins,_this.notifyPreference,_this.quietStartHour,_this.quietEndHour,_this.earlyPartner,_this.freeUntil,_this.phone]);
}

@override
String toString() {
  final _this = this as Seller;
  return 'Seller(id: ${_this.id}, businessName: ${_this.businessName}, logoUrl: ${_this.logoUrl}, photos: ${_this.photos}, description: ${_this.description}, yearsInBusiness: ${_this.yearsInBusiness}, brands: ${_this.brands}, categoryIds: ${_this.categoryIds}, areaType: ${_this.areaType}, lat: ${_this.lat}, lng: ${_this.lng}, radiusKm: ${_this.radiusKm}, serviceCodes: ${_this.serviceCodes}, state: ${_this.state}, locality: ${_this.locality}, verificationStatus: ${_this.verificationStatus}, verifiedAt: ${_this.verifiedAt}, ratingAvg: ${_this.ratingAvg}, ratingCount: ${_this.ratingCount}, quotesSent: ${_this.quotesSent}, quotesWon: ${_this.quotesWon}, avgResponseMins: ${_this.avgResponseMins}, notifyPreference: ${_this.notifyPreference}, quietStartHour: ${_this.quietStartHour}, quietEndHour: ${_this.quietEndHour}, earlyPartner: ${_this.earlyPartner}, freeUntil: ${_this.freeUntil}, phone: ${_this.phone})';
}


}

/// @nodoc
abstract mixin class $SellerCopyWith<$Res>  {
  factory $SellerCopyWith(Seller value, $Res Function(Seller) _then) = _$SellerCopyWithImpl;
@useResult
$Res call({
 String id, String businessName, String? logoUrl, List<String> photos, String description, int? yearsInBusiness, List<String> brands, List<int> categoryIds, AreaType areaType, double? lat, double? lng, int radiusKm, List<String> serviceCodes, String? state, String? locality, VerificationStatus verificationStatus, DateTime? verifiedAt, double ratingAvg, int ratingCount, int quotesSent, int quotesWon, int? avgResponseMins, NotifyPreference notifyPreference, int? quietStartHour, int? quietEndHour, bool earlyPartner, DateTime? freeUntil, String? phone
});




}
/// @nodoc
class _$SellerCopyWithImpl<$Res>
    implements $SellerCopyWith<$Res> {
  _$SellerCopyWithImpl(this._self, this._then);

  final Seller _self;
  final $Res Function(Seller) _then;

/// Create a copy of Seller
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessName = null,Object? logoUrl = freezed,Object? photos = null,Object? description = null,Object? yearsInBusiness = freezed,Object? brands = null,Object? categoryIds = null,Object? areaType = null,Object? lat = freezed,Object? lng = freezed,Object? radiusKm = null,Object? serviceCodes = null,Object? state = freezed,Object? locality = freezed,Object? verificationStatus = null,Object? verifiedAt = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? quotesSent = null,Object? quotesWon = null,Object? avgResponseMins = freezed,Object? notifyPreference = null,Object? quietStartHour = freezed,Object? quietEndHour = freezed,Object? earlyPartner = null,Object? freeUntil = freezed,Object? phone = freezed,}) {
  return _then(Seller(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,yearsInBusiness: freezed == yearsInBusiness ? _self.yearsInBusiness : yearsInBusiness // ignore: cast_nullable_to_non_nullable
as int?,brands: null == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,areaType: null == areaType ? _self.areaType : areaType // ignore: cast_nullable_to_non_nullable
as AreaType,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as int,serviceCodes: null == serviceCodes ? _self.serviceCodes : serviceCodes // ignore: cast_nullable_to_non_nullable
as List<String>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,quotesSent: null == quotesSent ? _self.quotesSent : quotesSent // ignore: cast_nullable_to_non_nullable
as int,quotesWon: null == quotesWon ? _self.quotesWon : quotesWon // ignore: cast_nullable_to_non_nullable
as int,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,notifyPreference: null == notifyPreference ? _self.notifyPreference : notifyPreference // ignore: cast_nullable_to_non_nullable
as NotifyPreference,quietStartHour: freezed == quietStartHour ? _self.quietStartHour : quietStartHour // ignore: cast_nullable_to_non_nullable
as int?,quietEndHour: freezed == quietEndHour ? _self.quietEndHour : quietEndHour // ignore: cast_nullable_to_non_nullable
as int?,earlyPartner: null == earlyPartner ? _self.earlyPartner : earlyPartner // ignore: cast_nullable_to_non_nullable
as bool,freeUntil: freezed == freeUntil ? _self.freeUntil : freeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Seller].
extension SellerPatterns on Seller {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Seller value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Seller() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Seller value)  $default,){
final _that = this;
switch (_that) {
case _Seller():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Seller value)?  $default,){
final _that = this;
switch (_that) {
case _Seller() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessName,  String? logoUrl,  List<String> photos,  String description,  int? yearsInBusiness,  List<String> brands,  List<int> categoryIds,  AreaType areaType,  double? lat,  double? lng,  int radiusKm,  List<String> serviceCodes,  String? state,  String? locality,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  double ratingAvg,  int ratingCount,  int quotesSent,  int quotesWon,  int? avgResponseMins,  NotifyPreference notifyPreference,  int? quietStartHour,  int? quietEndHour,  bool earlyPartner,  DateTime? freeUntil,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Seller() when $default != null:
return $default(_that.id,_that.businessName,_that.logoUrl,_that.photos,_that.description,_that.yearsInBusiness,_that.brands,_that.categoryIds,_that.areaType,_that.lat,_that.lng,_that.radiusKm,_that.serviceCodes,_that.state,_that.locality,_that.verificationStatus,_that.verifiedAt,_that.ratingAvg,_that.ratingCount,_that.quotesSent,_that.quotesWon,_that.avgResponseMins,_that.notifyPreference,_that.quietStartHour,_that.quietEndHour,_that.earlyPartner,_that.freeUntil,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessName,  String? logoUrl,  List<String> photos,  String description,  int? yearsInBusiness,  List<String> brands,  List<int> categoryIds,  AreaType areaType,  double? lat,  double? lng,  int radiusKm,  List<String> serviceCodes,  String? state,  String? locality,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  double ratingAvg,  int ratingCount,  int quotesSent,  int quotesWon,  int? avgResponseMins,  NotifyPreference notifyPreference,  int? quietStartHour,  int? quietEndHour,  bool earlyPartner,  DateTime? freeUntil,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _Seller():
return $default(_that.id,_that.businessName,_that.logoUrl,_that.photos,_that.description,_that.yearsInBusiness,_that.brands,_that.categoryIds,_that.areaType,_that.lat,_that.lng,_that.radiusKm,_that.serviceCodes,_that.state,_that.locality,_that.verificationStatus,_that.verifiedAt,_that.ratingAvg,_that.ratingCount,_that.quotesSent,_that.quotesWon,_that.avgResponseMins,_that.notifyPreference,_that.quietStartHour,_that.quietEndHour,_that.earlyPartner,_that.freeUntil,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessName,  String? logoUrl,  List<String> photos,  String description,  int? yearsInBusiness,  List<String> brands,  List<int> categoryIds,  AreaType areaType,  double? lat,  double? lng,  int radiusKm,  List<String> serviceCodes,  String? state,  String? locality,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  double ratingAvg,  int ratingCount,  int quotesSent,  int quotesWon,  int? avgResponseMins,  NotifyPreference notifyPreference,  int? quietStartHour,  int? quietEndHour,  bool earlyPartner,  DateTime? freeUntil,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _Seller() when $default != null:
return $default(_that.id,_that.businessName,_that.logoUrl,_that.photos,_that.description,_that.yearsInBusiness,_that.brands,_that.categoryIds,_that.areaType,_that.lat,_that.lng,_that.radiusKm,_that.serviceCodes,_that.state,_that.locality,_that.verificationStatus,_that.verifiedAt,_that.ratingAvg,_that.ratingCount,_that.quotesSent,_that.quotesWon,_that.avgResponseMins,_that.notifyPreference,_that.quietStartHour,_that.quietEndHour,_that.earlyPartner,_that.freeUntil,_that.phone);case _:
  return null;

}
}

}

/// @nodoc


class _Seller extends Seller {
  const _Seller({required this.id, required this.businessName, this.logoUrl,  List<String> photos = const [], this.description = '', this.yearsInBusiness,  List<String> brands = const [],  List<int> categoryIds = const [], this.areaType = AreaType.radius, this.lat, this.lng, this.radiusKm = 10,  List<String> serviceCodes = const [], this.state, this.locality, this.verificationStatus = VerificationStatus.none, this.verifiedAt, this.ratingAvg = 0, this.ratingCount = 0, this.quotesSent = 0, this.quotesWon = 0, this.avgResponseMins, this.notifyPreference = NotifyPreference.instant, this.quietStartHour, this.quietEndHour, this.earlyPartner = false, this.freeUntil, this.phone}): _photos = photos,_brands = brands,_categoryIds = categoryIds,_serviceCodes = serviceCodes,super._();
  

@override final  String id;
@override final  String businessName;
@override final  String? logoUrl;
 final  List<String> _photos;
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  String description;
@override final  int? yearsInBusiness;
 final  List<String> _brands;
@override@JsonKey() List<String> get brands {
  if (_brands is EqualUnmodifiableListView) return _brands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_brands);
}

 final  List<int> _categoryIds;
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override@JsonKey() final  AreaType areaType;
@override final  double? lat;
@override final  double? lng;
@override@JsonKey() final  int radiusKm;
 final  List<String> _serviceCodes;
@override@JsonKey() List<String> get serviceCodes {
  if (_serviceCodes is EqualUnmodifiableListView) return _serviceCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceCodes);
}

@override final  String? state;
@override final  String? locality;
@override@JsonKey() final  VerificationStatus verificationStatus;
@override final  DateTime? verifiedAt;
@override@JsonKey() final  double ratingAvg;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  int quotesSent;
@override@JsonKey() final  int quotesWon;
@override final  int? avgResponseMins;
@override@JsonKey() final  NotifyPreference notifyPreference;
@override final  int? quietStartHour;
@override final  int? quietEndHour;
@override@JsonKey() final  bool earlyPartner;
@override final  DateTime? freeUntil;
@override final  String? phone;

/// Create a copy of Seller
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerCopyWith<_Seller> get copyWith => __$SellerCopyWithImpl<_Seller>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Seller&&(identical(other.id, id) || other.id == id)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.description, description) || other.description == description)&&(identical(other.yearsInBusiness, yearsInBusiness) || other.yearsInBusiness == yearsInBusiness)&&const DeepCollectionEquality().equals(other.brands, _brands)&&const DeepCollectionEquality().equals(other.categoryIds, _categoryIds)&&(identical(other.areaType, areaType) || other.areaType == areaType)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&const DeepCollectionEquality().equals(other.serviceCodes, _serviceCodes)&&(identical(other.state, state) || other.state == state)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.ratingAvg, ratingAvg) || other.ratingAvg == ratingAvg)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.quotesSent, quotesSent) || other.quotesSent == quotesSent)&&(identical(other.quotesWon, quotesWon) || other.quotesWon == quotesWon)&&(identical(other.avgResponseMins, avgResponseMins) || other.avgResponseMins == avgResponseMins)&&(identical(other.notifyPreference, notifyPreference) || other.notifyPreference == notifyPreference)&&(identical(other.quietStartHour, quietStartHour) || other.quietStartHour == quietStartHour)&&(identical(other.quietEndHour, quietEndHour) || other.quietEndHour == quietEndHour)&&(identical(other.earlyPartner, earlyPartner) || other.earlyPartner == earlyPartner)&&(identical(other.freeUntil, freeUntil) || other.freeUntil == freeUntil)&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,businessName,logoUrl,const DeepCollectionEquality().hash(_photos),description,yearsInBusiness,const DeepCollectionEquality().hash(_brands),const DeepCollectionEquality().hash(_categoryIds),areaType,lat,lng,radiusKm,const DeepCollectionEquality().hash(_serviceCodes),state,locality,verificationStatus,verifiedAt,ratingAvg,ratingCount,quotesSent,quotesWon,avgResponseMins,notifyPreference,quietStartHour,quietEndHour,earlyPartner,freeUntil,phone]);
}

@override
String toString() {
    return 'Seller(id: $id, businessName: $businessName, logoUrl: $logoUrl, photos: $photos, description: $description, yearsInBusiness: $yearsInBusiness, brands: $brands, categoryIds: $categoryIds, areaType: $areaType, lat: $lat, lng: $lng, radiusKm: $radiusKm, serviceCodes: $serviceCodes, state: $state, locality: $locality, verificationStatus: $verificationStatus, verifiedAt: $verifiedAt, ratingAvg: $ratingAvg, ratingCount: $ratingCount, quotesSent: $quotesSent, quotesWon: $quotesWon, avgResponseMins: $avgResponseMins, notifyPreference: $notifyPreference, quietStartHour: $quietStartHour, quietEndHour: $quietEndHour, earlyPartner: $earlyPartner, freeUntil: $freeUntil, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$SellerCopyWith<$Res> implements $SellerCopyWith<$Res> {
  factory _$SellerCopyWith(_Seller value, $Res Function(_Seller) _then) = __$SellerCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessName, String? logoUrl, List<String> photos, String description, int? yearsInBusiness, List<String> brands, List<int> categoryIds, AreaType areaType, double? lat, double? lng, int radiusKm, List<String> serviceCodes, String? state, String? locality, VerificationStatus verificationStatus, DateTime? verifiedAt, double ratingAvg, int ratingCount, int quotesSent, int quotesWon, int? avgResponseMins, NotifyPreference notifyPreference, int? quietStartHour, int? quietEndHour, bool earlyPartner, DateTime? freeUntil, String? phone
});




}
/// @nodoc
class __$SellerCopyWithImpl<$Res>
    implements _$SellerCopyWith<$Res> {
  __$SellerCopyWithImpl(this._self, this._then);

  final _Seller _self;
  final $Res Function(_Seller) _then;

/// Create a copy of Seller
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessName = null,Object? logoUrl = freezed,Object? photos = null,Object? description = null,Object? yearsInBusiness = freezed,Object? brands = null,Object? categoryIds = null,Object? areaType = null,Object? lat = freezed,Object? lng = freezed,Object? radiusKm = null,Object? serviceCodes = null,Object? state = freezed,Object? locality = freezed,Object? verificationStatus = null,Object? verifiedAt = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? quotesSent = null,Object? quotesWon = null,Object? avgResponseMins = freezed,Object? notifyPreference = null,Object? quietStartHour = freezed,Object? quietEndHour = freezed,Object? earlyPartner = null,Object? freeUntil = freezed,Object? phone = freezed,}) {
  return _then(_Seller(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,yearsInBusiness: freezed == yearsInBusiness ? _self.yearsInBusiness : yearsInBusiness // ignore: cast_nullable_to_non_nullable
as int?,brands: null == brands ? _self._brands : brands // ignore: cast_nullable_to_non_nullable
as List<String>,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,areaType: null == areaType ? _self.areaType : areaType // ignore: cast_nullable_to_non_nullable
as AreaType,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as int,serviceCodes: null == serviceCodes ? _self._serviceCodes : serviceCodes // ignore: cast_nullable_to_non_nullable
as List<String>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,quotesSent: null == quotesSent ? _self.quotesSent : quotesSent // ignore: cast_nullable_to_non_nullable
as int,quotesWon: null == quotesWon ? _self.quotesWon : quotesWon // ignore: cast_nullable_to_non_nullable
as int,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,notifyPreference: null == notifyPreference ? _self.notifyPreference : notifyPreference // ignore: cast_nullable_to_non_nullable
as NotifyPreference,quietStartHour: freezed == quietStartHour ? _self.quietStartHour : quietStartHour // ignore: cast_nullable_to_non_nullable
as int?,quietEndHour: freezed == quietEndHour ? _self.quietEndHour : quietEndHour // ignore: cast_nullable_to_non_nullable
as int?,earlyPartner: null == earlyPartner ? _self.earlyPartner : earlyPartner // ignore: cast_nullable_to_non_nullable
as bool,freeUntil: freezed == freeUntil ? _self.freeUntil : freeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SellerDocument {

 String get id; String get docType; String? get docNumber; String? get filePath; VerificationStatus get status; String? get rejectionReason;
/// Create a copy of SellerDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerDocumentCopyWith<SellerDocument> get copyWith => _$SellerDocumentCopyWithImpl<SellerDocument>(this as SellerDocument, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SellerDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerDocument&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.docType, _this.docType) || other.docType == _this.docType)&&(identical(other.docNumber, _this.docNumber) || other.docNumber == _this.docNumber)&&(identical(other.filePath, _this.filePath) || other.filePath == _this.filePath)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.rejectionReason, _this.rejectionReason) || other.rejectionReason == _this.rejectionReason));
}


@override
int get hashCode {
  final _this = this as SellerDocument;
  return Object.hash(runtimeType,_this.id,_this.docType,_this.docNumber,_this.filePath,_this.status,_this.rejectionReason);
}

@override
String toString() {
  final _this = this as SellerDocument;
  return 'SellerDocument(id: ${_this.id}, docType: ${_this.docType}, docNumber: ${_this.docNumber}, filePath: ${_this.filePath}, status: ${_this.status}, rejectionReason: ${_this.rejectionReason})';
}


}

/// @nodoc
abstract mixin class $SellerDocumentCopyWith<$Res>  {
  factory $SellerDocumentCopyWith(SellerDocument value, $Res Function(SellerDocument) _then) = _$SellerDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String docType, String? docNumber, String? filePath, VerificationStatus status, String? rejectionReason
});




}
/// @nodoc
class _$SellerDocumentCopyWithImpl<$Res>
    implements $SellerDocumentCopyWith<$Res> {
  _$SellerDocumentCopyWithImpl(this._self, this._then);

  final SellerDocument _self;
  final $Res Function(SellerDocument) _then;

/// Create a copy of SellerDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? docType = null,Object? docNumber = freezed,Object? filePath = freezed,Object? status = null,Object? rejectionReason = freezed,}) {
  return _then(SellerDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as String,docNumber: freezed == docNumber ? _self.docNumber : docNumber // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerDocument].
extension SellerDocumentPatterns on SellerDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerDocument value)  $default,){
final _that = this;
switch (_that) {
case _SellerDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerDocument value)?  $default,){
final _that = this;
switch (_that) {
case _SellerDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String docType,  String? docNumber,  String? filePath,  VerificationStatus status,  String? rejectionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerDocument() when $default != null:
return $default(_that.id,_that.docType,_that.docNumber,_that.filePath,_that.status,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String docType,  String? docNumber,  String? filePath,  VerificationStatus status,  String? rejectionReason)  $default,) {final _that = this;
switch (_that) {
case _SellerDocument():
return $default(_that.id,_that.docType,_that.docNumber,_that.filePath,_that.status,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String docType,  String? docNumber,  String? filePath,  VerificationStatus status,  String? rejectionReason)?  $default,) {final _that = this;
switch (_that) {
case _SellerDocument() when $default != null:
return $default(_that.id,_that.docType,_that.docNumber,_that.filePath,_that.status,_that.rejectionReason);case _:
  return null;

}
}

}

/// @nodoc


class _SellerDocument implements SellerDocument {
  const _SellerDocument({required this.id, required this.docType, this.docNumber, this.filePath, this.status = VerificationStatus.pending, this.rejectionReason});
  

@override final  String id;
@override final  String docType;
@override final  String? docNumber;
@override final  String? filePath;
@override@JsonKey() final  VerificationStatus status;
@override final  String? rejectionReason;

/// Create a copy of SellerDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerDocumentCopyWith<_SellerDocument> get copyWith => __$SellerDocumentCopyWithImpl<_SellerDocument>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.docNumber, docNumber) || other.docNumber == docNumber)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,docType,docNumber,filePath,status,rejectionReason);
}

@override
String toString() {
    return 'SellerDocument(id: $id, docType: $docType, docNumber: $docNumber, filePath: $filePath, status: $status, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class _$SellerDocumentCopyWith<$Res> implements $SellerDocumentCopyWith<$Res> {
  factory _$SellerDocumentCopyWith(_SellerDocument value, $Res Function(_SellerDocument) _then) = __$SellerDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String docType, String? docNumber, String? filePath, VerificationStatus status, String? rejectionReason
});




}
/// @nodoc
class __$SellerDocumentCopyWithImpl<$Res>
    implements _$SellerDocumentCopyWith<$Res> {
  __$SellerDocumentCopyWithImpl(this._self, this._then);

  final _SellerDocument _self;
  final $Res Function(_SellerDocument) _then;

/// Create a copy of SellerDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? docType = null,Object? docNumber = freezed,Object? filePath = freezed,Object? status = null,Object? rejectionReason = freezed,}) {
  return _then(_SellerDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as String,docNumber: freezed == docNumber ? _self.docNumber : docNumber // ignore: cast_nullable_to_non_nullable
as String?,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SellerLicence {

 String get id; String get licenceType; String get number; String? get issuer; String? get state; List<int> get categoryIds; DateTime? get expiresAt; VerificationStatus get status;
/// Create a copy of SellerLicence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerLicenceCopyWith<SellerLicence> get copyWith => _$SellerLicenceCopyWithImpl<SellerLicence>(this as SellerLicence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SellerLicence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerLicence&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.licenceType, _this.licenceType) || other.licenceType == _this.licenceType)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.issuer, _this.issuer) || other.issuer == _this.issuer)&&(identical(other.state, _this.state) || other.state == _this.state)&&const DeepCollectionEquality().equals(other.categoryIds, _this.categoryIds)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.status, _this.status) || other.status == _this.status));
}


@override
int get hashCode {
  final _this = this as SellerLicence;
  return Object.hash(runtimeType,_this.id,_this.licenceType,_this.number,_this.issuer,_this.state,const DeepCollectionEquality().hash(_this.categoryIds),_this.expiresAt,_this.status);
}

@override
String toString() {
  final _this = this as SellerLicence;
  return 'SellerLicence(id: ${_this.id}, licenceType: ${_this.licenceType}, number: ${_this.number}, issuer: ${_this.issuer}, state: ${_this.state}, categoryIds: ${_this.categoryIds}, expiresAt: ${_this.expiresAt}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $SellerLicenceCopyWith<$Res>  {
  factory $SellerLicenceCopyWith(SellerLicence value, $Res Function(SellerLicence) _then) = _$SellerLicenceCopyWithImpl;
@useResult
$Res call({
 String id, String licenceType, String number, String? issuer, String? state, List<int> categoryIds, DateTime? expiresAt, VerificationStatus status
});




}
/// @nodoc
class _$SellerLicenceCopyWithImpl<$Res>
    implements $SellerLicenceCopyWith<$Res> {
  _$SellerLicenceCopyWithImpl(this._self, this._then);

  final SellerLicence _self;
  final $Res Function(SellerLicence) _then;

/// Create a copy of SellerLicence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? licenceType = null,Object? number = null,Object? issuer = freezed,Object? state = freezed,Object? categoryIds = null,Object? expiresAt = freezed,Object? status = null,}) {
  return _then(SellerLicence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,licenceType: null == licenceType ? _self.licenceType : licenceType // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerLicence].
extension SellerLicencePatterns on SellerLicence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerLicence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerLicence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerLicence value)  $default,){
final _that = this;
switch (_that) {
case _SellerLicence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerLicence value)?  $default,){
final _that = this;
switch (_that) {
case _SellerLicence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String licenceType,  String number,  String? issuer,  String? state,  List<int> categoryIds,  DateTime? expiresAt,  VerificationStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerLicence() when $default != null:
return $default(_that.id,_that.licenceType,_that.number,_that.issuer,_that.state,_that.categoryIds,_that.expiresAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String licenceType,  String number,  String? issuer,  String? state,  List<int> categoryIds,  DateTime? expiresAt,  VerificationStatus status)  $default,) {final _that = this;
switch (_that) {
case _SellerLicence():
return $default(_that.id,_that.licenceType,_that.number,_that.issuer,_that.state,_that.categoryIds,_that.expiresAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String licenceType,  String number,  String? issuer,  String? state,  List<int> categoryIds,  DateTime? expiresAt,  VerificationStatus status)?  $default,) {final _that = this;
switch (_that) {
case _SellerLicence() when $default != null:
return $default(_that.id,_that.licenceType,_that.number,_that.issuer,_that.state,_that.categoryIds,_that.expiresAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _SellerLicence implements SellerLicence {
  const _SellerLicence({required this.id, required this.licenceType, required this.number, this.issuer, this.state,  List<int> categoryIds = const [], this.expiresAt, this.status = VerificationStatus.pending}): _categoryIds = categoryIds;
  

@override final  String id;
@override final  String licenceType;
@override final  String number;
@override final  String? issuer;
@override final  String? state;
 final  List<int> _categoryIds;
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override final  DateTime? expiresAt;
@override@JsonKey() final  VerificationStatus status;

/// Create a copy of SellerLicence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerLicenceCopyWith<_SellerLicence> get copyWith => __$SellerLicenceCopyWithImpl<_SellerLicence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerLicence&&(identical(other.id, id) || other.id == id)&&(identical(other.licenceType, licenceType) || other.licenceType == licenceType)&&(identical(other.number, number) || other.number == number)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.categoryIds, _categoryIds)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,licenceType,number,issuer,state,const DeepCollectionEquality().hash(_categoryIds),expiresAt,status);
}

@override
String toString() {
    return 'SellerLicence(id: $id, licenceType: $licenceType, number: $number, issuer: $issuer, state: $state, categoryIds: $categoryIds, expiresAt: $expiresAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SellerLicenceCopyWith<$Res> implements $SellerLicenceCopyWith<$Res> {
  factory _$SellerLicenceCopyWith(_SellerLicence value, $Res Function(_SellerLicence) _then) = __$SellerLicenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String licenceType, String number, String? issuer, String? state, List<int> categoryIds, DateTime? expiresAt, VerificationStatus status
});




}
/// @nodoc
class __$SellerLicenceCopyWithImpl<$Res>
    implements _$SellerLicenceCopyWith<$Res> {
  __$SellerLicenceCopyWithImpl(this._self, this._then);

  final _SellerLicence _self;
  final $Res Function(_SellerLicence) _then;

/// Create a copy of SellerLicence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? licenceType = null,Object? number = null,Object? issuer = freezed,Object? state = freezed,Object? categoryIds = null,Object? expiresAt = freezed,Object? status = null,}) {
  return _then(_SellerLicence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,licenceType: null == licenceType ? _self.licenceType : licenceType // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,
  ));
}


}

/// @nodoc
mixin _$QuoteTemplate {

 String get id; String get name; Map<String, Object?> get payload;
/// Create a copy of QuoteTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteTemplateCopyWith<QuoteTemplate> get copyWith => _$QuoteTemplateCopyWithImpl<QuoteTemplate>(this as QuoteTemplate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QuoteTemplate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteTemplate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}


@override
int get hashCode {
  final _this = this as QuoteTemplate;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as QuoteTemplate;
  return 'QuoteTemplate(id: ${_this.id}, name: ${_this.name}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $QuoteTemplateCopyWith<$Res>  {
  factory $QuoteTemplateCopyWith(QuoteTemplate value, $Res Function(QuoteTemplate) _then) = _$QuoteTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, Object?> payload
});




}
/// @nodoc
class _$QuoteTemplateCopyWithImpl<$Res>
    implements $QuoteTemplateCopyWith<$Res> {
  _$QuoteTemplateCopyWithImpl(this._self, this._then);

  final QuoteTemplate _self;
  final $Res Function(QuoteTemplate) _then;

/// Create a copy of QuoteTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? payload = null,}) {
  return _then(QuoteTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteTemplate].
extension QuoteTemplatePatterns on QuoteTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteTemplate value)  $default,){
final _that = this;
switch (_that) {
case _QuoteTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteTemplate() when $default != null:
return $default(_that.id,_that.name,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _QuoteTemplate():
return $default(_that.id,_that.name,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _QuoteTemplate() when $default != null:
return $default(_that.id,_that.name,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class _QuoteTemplate implements QuoteTemplate {
  const _QuoteTemplate({required this.id, required this.name, required  Map<String, Object?> payload}): _payload = payload;
  

@override final  String id;
@override final  String name;
 final  Map<String, Object?> _payload;
@override Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of QuoteTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteTemplateCopyWith<_QuoteTemplate> get copyWith => __$QuoteTemplateCopyWithImpl<_QuoteTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.payload, _payload));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'QuoteTemplate(id: $id, name: $name, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$QuoteTemplateCopyWith<$Res> implements $QuoteTemplateCopyWith<$Res> {
  factory _$QuoteTemplateCopyWith(_QuoteTemplate value, $Res Function(_QuoteTemplate) _then) = __$QuoteTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Map<String, Object?> payload
});




}
/// @nodoc
class __$QuoteTemplateCopyWithImpl<$Res>
    implements _$QuoteTemplateCopyWith<$Res> {
  __$QuoteTemplateCopyWithImpl(this._self, this._then);

  final _QuoteTemplate _self;
  final $Res Function(_QuoteTemplate) _then;

/// Create a copy of QuoteTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? payload = null,}) {
  return _then(_QuoteTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc
mixin _$SellerStats {

 int get activeQuotes; int get won; int get lost; double get winRate; int? get avgResponseMins; Money? get revenueLogged; double get ratingAvg; int get ratingCount; int get quotesThisMonth;
/// Create a copy of SellerStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerStatsCopyWith<SellerStats> get copyWith => _$SellerStatsCopyWithImpl<SellerStats>(this as SellerStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SellerStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerStats&&(identical(other.activeQuotes, _this.activeQuotes) || other.activeQuotes == _this.activeQuotes)&&(identical(other.won, _this.won) || other.won == _this.won)&&(identical(other.lost, _this.lost) || other.lost == _this.lost)&&(identical(other.winRate, _this.winRate) || other.winRate == _this.winRate)&&(identical(other.avgResponseMins, _this.avgResponseMins) || other.avgResponseMins == _this.avgResponseMins)&&(identical(other.revenueLogged, _this.revenueLogged) || other.revenueLogged == _this.revenueLogged)&&(identical(other.ratingAvg, _this.ratingAvg) || other.ratingAvg == _this.ratingAvg)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.quotesThisMonth, _this.quotesThisMonth) || other.quotesThisMonth == _this.quotesThisMonth));
}


@override
int get hashCode {
  final _this = this as SellerStats;
  return Object.hash(runtimeType,_this.activeQuotes,_this.won,_this.lost,_this.winRate,_this.avgResponseMins,_this.revenueLogged,_this.ratingAvg,_this.ratingCount,_this.quotesThisMonth);
}

@override
String toString() {
  final _this = this as SellerStats;
  return 'SellerStats(activeQuotes: ${_this.activeQuotes}, won: ${_this.won}, lost: ${_this.lost}, winRate: ${_this.winRate}, avgResponseMins: ${_this.avgResponseMins}, revenueLogged: ${_this.revenueLogged}, ratingAvg: ${_this.ratingAvg}, ratingCount: ${_this.ratingCount}, quotesThisMonth: ${_this.quotesThisMonth})';
}


}

/// @nodoc
abstract mixin class $SellerStatsCopyWith<$Res>  {
  factory $SellerStatsCopyWith(SellerStats value, $Res Function(SellerStats) _then) = _$SellerStatsCopyWithImpl;
@useResult
$Res call({
 int activeQuotes, int won, int lost, double winRate, int? avgResponseMins, Money? revenueLogged, double ratingAvg, int ratingCount, int quotesThisMonth
});




}
/// @nodoc
class _$SellerStatsCopyWithImpl<$Res>
    implements $SellerStatsCopyWith<$Res> {
  _$SellerStatsCopyWithImpl(this._self, this._then);

  final SellerStats _self;
  final $Res Function(SellerStats) _then;

/// Create a copy of SellerStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeQuotes = null,Object? won = null,Object? lost = null,Object? winRate = null,Object? avgResponseMins = freezed,Object? revenueLogged = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? quotesThisMonth = null,}) {
  return _then(SellerStats(
activeQuotes: null == activeQuotes ? _self.activeQuotes : activeQuotes // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as double,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,revenueLogged: freezed == revenueLogged ? _self.revenueLogged : revenueLogged // ignore: cast_nullable_to_non_nullable
as Money?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,quotesThisMonth: null == quotesThisMonth ? _self.quotesThisMonth : quotesThisMonth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerStats].
extension SellerStatsPatterns on SellerStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerStats value)  $default,){
final _that = this;
switch (_that) {
case _SellerStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerStats value)?  $default,){
final _that = this;
switch (_that) {
case _SellerStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int activeQuotes,  int won,  int lost,  double winRate,  int? avgResponseMins,  Money? revenueLogged,  double ratingAvg,  int ratingCount,  int quotesThisMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerStats() when $default != null:
return $default(_that.activeQuotes,_that.won,_that.lost,_that.winRate,_that.avgResponseMins,_that.revenueLogged,_that.ratingAvg,_that.ratingCount,_that.quotesThisMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int activeQuotes,  int won,  int lost,  double winRate,  int? avgResponseMins,  Money? revenueLogged,  double ratingAvg,  int ratingCount,  int quotesThisMonth)  $default,) {final _that = this;
switch (_that) {
case _SellerStats():
return $default(_that.activeQuotes,_that.won,_that.lost,_that.winRate,_that.avgResponseMins,_that.revenueLogged,_that.ratingAvg,_that.ratingCount,_that.quotesThisMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int activeQuotes,  int won,  int lost,  double winRate,  int? avgResponseMins,  Money? revenueLogged,  double ratingAvg,  int ratingCount,  int quotesThisMonth)?  $default,) {final _that = this;
switch (_that) {
case _SellerStats() when $default != null:
return $default(_that.activeQuotes,_that.won,_that.lost,_that.winRate,_that.avgResponseMins,_that.revenueLogged,_that.ratingAvg,_that.ratingCount,_that.quotesThisMonth);case _:
  return null;

}
}

}

/// @nodoc


class _SellerStats implements SellerStats {
  const _SellerStats({this.activeQuotes = 0, this.won = 0, this.lost = 0, this.winRate = 0, this.avgResponseMins, this.revenueLogged, this.ratingAvg = 0, this.ratingCount = 0, this.quotesThisMonth = 0});
  

@override@JsonKey() final  int activeQuotes;
@override@JsonKey() final  int won;
@override@JsonKey() final  int lost;
@override@JsonKey() final  double winRate;
@override final  int? avgResponseMins;
@override final  Money? revenueLogged;
@override@JsonKey() final  double ratingAvg;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  int quotesThisMonth;

/// Create a copy of SellerStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerStatsCopyWith<_SellerStats> get copyWith => __$SellerStatsCopyWithImpl<_SellerStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerStats&&(identical(other.activeQuotes, activeQuotes) || other.activeQuotes == activeQuotes)&&(identical(other.won, won) || other.won == won)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.avgResponseMins, avgResponseMins) || other.avgResponseMins == avgResponseMins)&&(identical(other.revenueLogged, revenueLogged) || other.revenueLogged == revenueLogged)&&(identical(other.ratingAvg, ratingAvg) || other.ratingAvg == ratingAvg)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.quotesThisMonth, quotesThisMonth) || other.quotesThisMonth == quotesThisMonth));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activeQuotes,won,lost,winRate,avgResponseMins,revenueLogged,ratingAvg,ratingCount,quotesThisMonth);
}

@override
String toString() {
    return 'SellerStats(activeQuotes: $activeQuotes, won: $won, lost: $lost, winRate: $winRate, avgResponseMins: $avgResponseMins, revenueLogged: $revenueLogged, ratingAvg: $ratingAvg, ratingCount: $ratingCount, quotesThisMonth: $quotesThisMonth)';
}


}

/// @nodoc
abstract mixin class _$SellerStatsCopyWith<$Res> implements $SellerStatsCopyWith<$Res> {
  factory _$SellerStatsCopyWith(_SellerStats value, $Res Function(_SellerStats) _then) = __$SellerStatsCopyWithImpl;
@override @useResult
$Res call({
 int activeQuotes, int won, int lost, double winRate, int? avgResponseMins, Money? revenueLogged, double ratingAvg, int ratingCount, int quotesThisMonth
});




}
/// @nodoc
class __$SellerStatsCopyWithImpl<$Res>
    implements _$SellerStatsCopyWith<$Res> {
  __$SellerStatsCopyWithImpl(this._self, this._then);

  final _SellerStats _self;
  final $Res Function(_SellerStats) _then;

/// Create a copy of SellerStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeQuotes = null,Object? won = null,Object? lost = null,Object? winRate = null,Object? avgResponseMins = freezed,Object? revenueLogged = freezed,Object? ratingAvg = null,Object? ratingCount = null,Object? quotesThisMonth = null,}) {
  return _then(_SellerStats(
activeQuotes: null == activeQuotes ? _self.activeQuotes : activeQuotes // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as double,avgResponseMins: freezed == avgResponseMins ? _self.avgResponseMins : avgResponseMins // ignore: cast_nullable_to_non_nullable
as int?,revenueLogged: freezed == revenueLogged ? _self.revenueLogged : revenueLogged // ignore: cast_nullable_to_non_nullable
as Money?,ratingAvg: null == ratingAvg ? _self.ratingAvg : ratingAvg // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,quotesThisMonth: null == quotesThisMonth ? _self.quotesThisMonth : quotesThisMonth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Entitlement {

 String get tier; String get status; String? get store; String? get productId; int get creditsBalance; DateTime? get renewsAt; bool get inGracePeriod;
/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntitlementCopyWith<Entitlement> get copyWith => _$EntitlementCopyWithImpl<Entitlement>(this as Entitlement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Entitlement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Entitlement&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.store, _this.store) || other.store == _this.store)&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.creditsBalance, _this.creditsBalance) || other.creditsBalance == _this.creditsBalance)&&(identical(other.renewsAt, _this.renewsAt) || other.renewsAt == _this.renewsAt)&&(identical(other.inGracePeriod, _this.inGracePeriod) || other.inGracePeriod == _this.inGracePeriod));
}


@override
int get hashCode {
  final _this = this as Entitlement;
  return Object.hash(runtimeType,_this.tier,_this.status,_this.store,_this.productId,_this.creditsBalance,_this.renewsAt,_this.inGracePeriod);
}

@override
String toString() {
  final _this = this as Entitlement;
  return 'Entitlement(tier: ${_this.tier}, status: ${_this.status}, store: ${_this.store}, productId: ${_this.productId}, creditsBalance: ${_this.creditsBalance}, renewsAt: ${_this.renewsAt}, inGracePeriod: ${_this.inGracePeriod})';
}


}

/// @nodoc
abstract mixin class $EntitlementCopyWith<$Res>  {
  factory $EntitlementCopyWith(Entitlement value, $Res Function(Entitlement) _then) = _$EntitlementCopyWithImpl;
@useResult
$Res call({
 String tier, String status, String? store, String? productId, int creditsBalance, DateTime? renewsAt, bool inGracePeriod
});




}
/// @nodoc
class _$EntitlementCopyWithImpl<$Res>
    implements $EntitlementCopyWith<$Res> {
  _$EntitlementCopyWithImpl(this._self, this._then);

  final Entitlement _self;
  final $Res Function(Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? status = null,Object? store = freezed,Object? productId = freezed,Object? creditsBalance = null,Object? renewsAt = freezed,Object? inGracePeriod = null,}) {
  return _then(Entitlement(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,creditsBalance: null == creditsBalance ? _self.creditsBalance : creditsBalance // ignore: cast_nullable_to_non_nullable
as int,renewsAt: freezed == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inGracePeriod: null == inGracePeriod ? _self.inGracePeriod : inGracePeriod // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Entitlement].
extension EntitlementPatterns on Entitlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Entitlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Entitlement value)  $default,){
final _that = this;
switch (_that) {
case _Entitlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Entitlement value)?  $default,){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tier,  String status,  String? store,  String? productId,  int creditsBalance,  DateTime? renewsAt,  bool inGracePeriod)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.tier,_that.status,_that.store,_that.productId,_that.creditsBalance,_that.renewsAt,_that.inGracePeriod);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tier,  String status,  String? store,  String? productId,  int creditsBalance,  DateTime? renewsAt,  bool inGracePeriod)  $default,) {final _that = this;
switch (_that) {
case _Entitlement():
return $default(_that.tier,_that.status,_that.store,_that.productId,_that.creditsBalance,_that.renewsAt,_that.inGracePeriod);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tier,  String status,  String? store,  String? productId,  int creditsBalance,  DateTime? renewsAt,  bool inGracePeriod)?  $default,) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.tier,_that.status,_that.store,_that.productId,_that.creditsBalance,_that.renewsAt,_that.inGracePeriod);case _:
  return null;

}
}

}

/// @nodoc


class _Entitlement extends Entitlement {
  const _Entitlement({this.tier = 'free', this.status = 'active', this.store, this.productId, this.creditsBalance = 0, this.renewsAt, this.inGracePeriod = false}): super._();
  

@override@JsonKey() final  String tier;
@override@JsonKey() final  String status;
@override final  String? store;
@override final  String? productId;
@override@JsonKey() final  int creditsBalance;
@override final  DateTime? renewsAt;
@override@JsonKey() final  bool inGracePeriod;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntitlementCopyWith<_Entitlement> get copyWith => __$EntitlementCopyWithImpl<_Entitlement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Entitlement&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.status, status) || other.status == status)&&(identical(other.store, store) || other.store == store)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.creditsBalance, creditsBalance) || other.creditsBalance == creditsBalance)&&(identical(other.renewsAt, renewsAt) || other.renewsAt == renewsAt)&&(identical(other.inGracePeriod, inGracePeriod) || other.inGracePeriod == inGracePeriod));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tier,status,store,productId,creditsBalance,renewsAt,inGracePeriod);
}

@override
String toString() {
    return 'Entitlement(tier: $tier, status: $status, store: $store, productId: $productId, creditsBalance: $creditsBalance, renewsAt: $renewsAt, inGracePeriod: $inGracePeriod)';
}


}

/// @nodoc
abstract mixin class _$EntitlementCopyWith<$Res> implements $EntitlementCopyWith<$Res> {
  factory _$EntitlementCopyWith(_Entitlement value, $Res Function(_Entitlement) _then) = __$EntitlementCopyWithImpl;
@override @useResult
$Res call({
 String tier, String status, String? store, String? productId, int creditsBalance, DateTime? renewsAt, bool inGracePeriod
});




}
/// @nodoc
class __$EntitlementCopyWithImpl<$Res>
    implements _$EntitlementCopyWith<$Res> {
  __$EntitlementCopyWithImpl(this._self, this._then);

  final _Entitlement _self;
  final $Res Function(_Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,Object? status = null,Object? store = freezed,Object? productId = freezed,Object? creditsBalance = null,Object? renewsAt = freezed,Object? inGracePeriod = null,}) {
  return _then(_Entitlement(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,creditsBalance: null == creditsBalance ? _self.creditsBalance : creditsBalance // ignore: cast_nullable_to_non_nullable
as int,renewsAt: freezed == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inGracePeriod: null == inGracePeriod ? _self.inGracePeriod : inGracePeriod // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
