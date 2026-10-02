// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buyer_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RequestMedia {

 String get path; String get type; String? get url;
/// Create a copy of RequestMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestMediaCopyWith<RequestMedia> get copyWith => _$RequestMediaCopyWithImpl<RequestMedia>(this as RequestMedia, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RequestMedia;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestMedia&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.url, _this.url) || other.url == _this.url));
}


@override
int get hashCode {
  final _this = this as RequestMedia;
  return Object.hash(runtimeType,_this.path,_this.type,_this.url);
}

@override
String toString() {
  final _this = this as RequestMedia;
  return 'RequestMedia(path: ${_this.path}, type: ${_this.type}, url: ${_this.url})';
}


}

/// @nodoc
abstract mixin class $RequestMediaCopyWith<$Res>  {
  factory $RequestMediaCopyWith(RequestMedia value, $Res Function(RequestMedia) _then) = _$RequestMediaCopyWithImpl;
@useResult
$Res call({
 String path, String type, String? url
});




}
/// @nodoc
class _$RequestMediaCopyWithImpl<$Res>
    implements $RequestMediaCopyWith<$Res> {
  _$RequestMediaCopyWithImpl(this._self, this._then);

  final RequestMedia _self;
  final $Res Function(RequestMedia) _then;

/// Create a copy of RequestMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? type = null,Object? url = freezed,}) {
  return _then(RequestMedia(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestMedia].
extension RequestMediaPatterns on RequestMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestMedia value)  $default,){
final _that = this;
switch (_that) {
case _RequestMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestMedia value)?  $default,){
final _that = this;
switch (_that) {
case _RequestMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String type,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestMedia() when $default != null:
return $default(_that.path,_that.type,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String type,  String? url)  $default,) {final _that = this;
switch (_that) {
case _RequestMedia():
return $default(_that.path,_that.type,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String type,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _RequestMedia() when $default != null:
return $default(_that.path,_that.type,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _RequestMedia implements RequestMedia {
  const _RequestMedia({required this.path, this.type = 'image', this.url});
  

@override final  String path;
@override@JsonKey() final  String type;
@override final  String? url;

/// Create a copy of RequestMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestMediaCopyWith<_RequestMedia> get copyWith => __$RequestMediaCopyWithImpl<_RequestMedia>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestMedia&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,type,url);
}

@override
String toString() {
    return 'RequestMedia(path: $path, type: $type, url: $url)';
}


}

/// @nodoc
abstract mixin class _$RequestMediaCopyWith<$Res> implements $RequestMediaCopyWith<$Res> {
  factory _$RequestMediaCopyWith(_RequestMedia value, $Res Function(_RequestMedia) _then) = __$RequestMediaCopyWithImpl;
@override @useResult
$Res call({
 String path, String type, String? url
});




}
/// @nodoc
class __$RequestMediaCopyWithImpl<$Res>
    implements _$RequestMediaCopyWith<$Res> {
  __$RequestMediaCopyWithImpl(this._self, this._then);

  final _RequestMedia _self;
  final $Res Function(_RequestMedia) _then;

/// Create a copy of RequestMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? type = null,Object? url = freezed,}) {
  return _then(_RequestMedia(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$BuyerRequest {

 String get id; String get buyerId; int get categoryId; String get title; String get description; Map<String, Object?> get fields; Money? get budgetMin; Money? get budgetMax; bool get budgetVisible; DateTime? get neededBy; double? get lat; double? get lng; String? get locationCode; String? get locality; String? get state; Audience get audience; RequestStatus get status; int get quoteCount; int get maxQuotes; DateTime? get quoteWindowEndsAt; DateTime? get priorityUntil; String? get acceptedQuoteId; String? get referenceLink; List<RequestMedia> get media; DateTime get createdAt; int get notifiedSellers; int get unreadQuotes;
/// Create a copy of BuyerRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuyerRequestCopyWith<BuyerRequest> get copyWith => _$BuyerRequestCopyWithImpl<BuyerRequest>(this as BuyerRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BuyerRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuyerRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.buyerId, _this.buyerId) || other.buyerId == _this.buyerId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.fields, _this.fields)&&(identical(other.budgetMin, _this.budgetMin) || other.budgetMin == _this.budgetMin)&&(identical(other.budgetMax, _this.budgetMax) || other.budgetMax == _this.budgetMax)&&(identical(other.budgetVisible, _this.budgetVisible) || other.budgetVisible == _this.budgetVisible)&&(identical(other.neededBy, _this.neededBy) || other.neededBy == _this.neededBy)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.locationCode, _this.locationCode) || other.locationCode == _this.locationCode)&&(identical(other.locality, _this.locality) || other.locality == _this.locality)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.quoteCount, _this.quoteCount) || other.quoteCount == _this.quoteCount)&&(identical(other.maxQuotes, _this.maxQuotes) || other.maxQuotes == _this.maxQuotes)&&(identical(other.quoteWindowEndsAt, _this.quoteWindowEndsAt) || other.quoteWindowEndsAt == _this.quoteWindowEndsAt)&&(identical(other.priorityUntil, _this.priorityUntil) || other.priorityUntil == _this.priorityUntil)&&(identical(other.acceptedQuoteId, _this.acceptedQuoteId) || other.acceptedQuoteId == _this.acceptedQuoteId)&&(identical(other.referenceLink, _this.referenceLink) || other.referenceLink == _this.referenceLink)&&const DeepCollectionEquality().equals(other.media, _this.media)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.notifiedSellers, _this.notifiedSellers) || other.notifiedSellers == _this.notifiedSellers)&&(identical(other.unreadQuotes, _this.unreadQuotes) || other.unreadQuotes == _this.unreadQuotes));
}


@override
int get hashCode {
  final _this = this as BuyerRequest;
  return Object.hashAll([runtimeType,_this.id,_this.buyerId,_this.categoryId,_this.title,_this.description,const DeepCollectionEquality().hash(_this.fields),_this.budgetMin,_this.budgetMax,_this.budgetVisible,_this.neededBy,_this.lat,_this.lng,_this.locationCode,_this.locality,_this.state,_this.audience,_this.status,_this.quoteCount,_this.maxQuotes,_this.quoteWindowEndsAt,_this.priorityUntil,_this.acceptedQuoteId,_this.referenceLink,const DeepCollectionEquality().hash(_this.media),_this.createdAt,_this.notifiedSellers,_this.unreadQuotes]);
}

@override
String toString() {
  final _this = this as BuyerRequest;
  return 'BuyerRequest(id: ${_this.id}, buyerId: ${_this.buyerId}, categoryId: ${_this.categoryId}, title: ${_this.title}, description: ${_this.description}, fields: ${_this.fields}, budgetMin: ${_this.budgetMin}, budgetMax: ${_this.budgetMax}, budgetVisible: ${_this.budgetVisible}, neededBy: ${_this.neededBy}, lat: ${_this.lat}, lng: ${_this.lng}, locationCode: ${_this.locationCode}, locality: ${_this.locality}, state: ${_this.state}, audience: ${_this.audience}, status: ${_this.status}, quoteCount: ${_this.quoteCount}, maxQuotes: ${_this.maxQuotes}, quoteWindowEndsAt: ${_this.quoteWindowEndsAt}, priorityUntil: ${_this.priorityUntil}, acceptedQuoteId: ${_this.acceptedQuoteId}, referenceLink: ${_this.referenceLink}, media: ${_this.media}, createdAt: ${_this.createdAt}, notifiedSellers: ${_this.notifiedSellers}, unreadQuotes: ${_this.unreadQuotes})';
}


}

/// @nodoc
abstract mixin class $BuyerRequestCopyWith<$Res>  {
  factory $BuyerRequestCopyWith(BuyerRequest value, $Res Function(BuyerRequest) _then) = _$BuyerRequestCopyWithImpl;
@useResult
$Res call({
 String id, String buyerId, int categoryId, String title, String description, Map<String, Object?> fields, Money? budgetMin, Money? budgetMax, bool budgetVisible, DateTime? neededBy, double? lat, double? lng, String? locationCode, String? locality, String? state, Audience audience, RequestStatus status, int quoteCount, int maxQuotes, DateTime? quoteWindowEndsAt, DateTime? priorityUntil, String? acceptedQuoteId, String? referenceLink, List<RequestMedia> media, DateTime createdAt, int notifiedSellers, int unreadQuotes
});




}
/// @nodoc
class _$BuyerRequestCopyWithImpl<$Res>
    implements $BuyerRequestCopyWith<$Res> {
  _$BuyerRequestCopyWithImpl(this._self, this._then);

  final BuyerRequest _self;
  final $Res Function(BuyerRequest) _then;

/// Create a copy of BuyerRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buyerId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? fields = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? budgetVisible = null,Object? neededBy = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationCode = freezed,Object? locality = freezed,Object? state = freezed,Object? audience = null,Object? status = null,Object? quoteCount = null,Object? maxQuotes = null,Object? quoteWindowEndsAt = freezed,Object? priorityUntil = freezed,Object? acceptedQuoteId = freezed,Object? referenceLink = freezed,Object? media = null,Object? createdAt = null,Object? notifiedSellers = null,Object? unreadQuotes = null,}) {
  return _then(BuyerRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,budgetVisible: null == budgetVisible ? _self.budgetVisible : budgetVisible // ignore: cast_nullable_to_non_nullable
as bool,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,maxQuotes: null == maxQuotes ? _self.maxQuotes : maxQuotes // ignore: cast_nullable_to_non_nullable
as int,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priorityUntil: freezed == priorityUntil ? _self.priorityUntil : priorityUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedQuoteId: freezed == acceptedQuoteId ? _self.acceptedQuoteId : acceptedQuoteId // ignore: cast_nullable_to_non_nullable
as String?,referenceLink: freezed == referenceLink ? _self.referenceLink : referenceLink // ignore: cast_nullable_to_non_nullable
as String?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<RequestMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,notifiedSellers: null == notifiedSellers ? _self.notifiedSellers : notifiedSellers // ignore: cast_nullable_to_non_nullable
as int,unreadQuotes: null == unreadQuotes ? _self.unreadQuotes : unreadQuotes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuyerRequest].
extension BuyerRequestPatterns on BuyerRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuyerRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuyerRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuyerRequest value)  $default,){
final _that = this;
switch (_that) {
case _BuyerRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuyerRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BuyerRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buyerId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  Audience audience,  RequestStatus status,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime? priorityUntil,  String? acceptedQuoteId,  String? referenceLink,  List<RequestMedia> media,  DateTime createdAt,  int notifiedSellers,  int unreadQuotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuyerRequest() when $default != null:
return $default(_that.id,_that.buyerId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.audience,_that.status,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.priorityUntil,_that.acceptedQuoteId,_that.referenceLink,_that.media,_that.createdAt,_that.notifiedSellers,_that.unreadQuotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buyerId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  Audience audience,  RequestStatus status,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime? priorityUntil,  String? acceptedQuoteId,  String? referenceLink,  List<RequestMedia> media,  DateTime createdAt,  int notifiedSellers,  int unreadQuotes)  $default,) {final _that = this;
switch (_that) {
case _BuyerRequest():
return $default(_that.id,_that.buyerId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.audience,_that.status,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.priorityUntil,_that.acceptedQuoteId,_that.referenceLink,_that.media,_that.createdAt,_that.notifiedSellers,_that.unreadQuotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buyerId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  Audience audience,  RequestStatus status,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime? priorityUntil,  String? acceptedQuoteId,  String? referenceLink,  List<RequestMedia> media,  DateTime createdAt,  int notifiedSellers,  int unreadQuotes)?  $default,) {final _that = this;
switch (_that) {
case _BuyerRequest() when $default != null:
return $default(_that.id,_that.buyerId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.audience,_that.status,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.priorityUntil,_that.acceptedQuoteId,_that.referenceLink,_that.media,_that.createdAt,_that.notifiedSellers,_that.unreadQuotes);case _:
  return null;

}
}

}

/// @nodoc


class _BuyerRequest extends BuyerRequest {
  const _BuyerRequest({required this.id, required this.buyerId, required this.categoryId, required this.title, this.description = '',  Map<String, Object?> fields = const {}, this.budgetMin, this.budgetMax, this.budgetVisible = true, this.neededBy, this.lat, this.lng, this.locationCode, this.locality, this.state, this.audience = Audience.both, this.status = RequestStatus.open, this.quoteCount = 0, this.maxQuotes = 10, this.quoteWindowEndsAt, this.priorityUntil, this.acceptedQuoteId, this.referenceLink,  List<RequestMedia> media = const [], required this.createdAt, this.notifiedSellers = 0, this.unreadQuotes = 0}): _fields = fields,_media = media,super._();
  

@override final  String id;
@override final  String buyerId;
@override final  int categoryId;
@override final  String title;
@override@JsonKey() final  String description;
 final  Map<String, Object?> _fields;
@override@JsonKey() Map<String, Object?> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}

@override final  Money? budgetMin;
@override final  Money? budgetMax;
@override@JsonKey() final  bool budgetVisible;
@override final  DateTime? neededBy;
@override final  double? lat;
@override final  double? lng;
@override final  String? locationCode;
@override final  String? locality;
@override final  String? state;
@override@JsonKey() final  Audience audience;
@override@JsonKey() final  RequestStatus status;
@override@JsonKey() final  int quoteCount;
@override@JsonKey() final  int maxQuotes;
@override final  DateTime? quoteWindowEndsAt;
@override final  DateTime? priorityUntil;
@override final  String? acceptedQuoteId;
@override final  String? referenceLink;
 final  List<RequestMedia> _media;
@override@JsonKey() List<RequestMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override final  DateTime createdAt;
@override@JsonKey() final  int notifiedSellers;
@override@JsonKey() final  int unreadQuotes;

/// Create a copy of BuyerRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuyerRequestCopyWith<_BuyerRequest> get copyWith => __$BuyerRequestCopyWithImpl<_BuyerRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuyerRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.fields, _fields)&&(identical(other.budgetMin, budgetMin) || other.budgetMin == budgetMin)&&(identical(other.budgetMax, budgetMax) || other.budgetMax == budgetMax)&&(identical(other.budgetVisible, budgetVisible) || other.budgetVisible == budgetVisible)&&(identical(other.neededBy, neededBy) || other.neededBy == neededBy)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationCode, locationCode) || other.locationCode == locationCode)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.state, state) || other.state == state)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.status, status) || other.status == status)&&(identical(other.quoteCount, quoteCount) || other.quoteCount == quoteCount)&&(identical(other.maxQuotes, maxQuotes) || other.maxQuotes == maxQuotes)&&(identical(other.quoteWindowEndsAt, quoteWindowEndsAt) || other.quoteWindowEndsAt == quoteWindowEndsAt)&&(identical(other.priorityUntil, priorityUntil) || other.priorityUntil == priorityUntil)&&(identical(other.acceptedQuoteId, acceptedQuoteId) || other.acceptedQuoteId == acceptedQuoteId)&&(identical(other.referenceLink, referenceLink) || other.referenceLink == referenceLink)&&const DeepCollectionEquality().equals(other.media, _media)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.notifiedSellers, notifiedSellers) || other.notifiedSellers == notifiedSellers)&&(identical(other.unreadQuotes, unreadQuotes) || other.unreadQuotes == unreadQuotes));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,buyerId,categoryId,title,description,const DeepCollectionEquality().hash(_fields),budgetMin,budgetMax,budgetVisible,neededBy,lat,lng,locationCode,locality,state,audience,status,quoteCount,maxQuotes,quoteWindowEndsAt,priorityUntil,acceptedQuoteId,referenceLink,const DeepCollectionEquality().hash(_media),createdAt,notifiedSellers,unreadQuotes]);
}

@override
String toString() {
    return 'BuyerRequest(id: $id, buyerId: $buyerId, categoryId: $categoryId, title: $title, description: $description, fields: $fields, budgetMin: $budgetMin, budgetMax: $budgetMax, budgetVisible: $budgetVisible, neededBy: $neededBy, lat: $lat, lng: $lng, locationCode: $locationCode, locality: $locality, state: $state, audience: $audience, status: $status, quoteCount: $quoteCount, maxQuotes: $maxQuotes, quoteWindowEndsAt: $quoteWindowEndsAt, priorityUntil: $priorityUntil, acceptedQuoteId: $acceptedQuoteId, referenceLink: $referenceLink, media: $media, createdAt: $createdAt, notifiedSellers: $notifiedSellers, unreadQuotes: $unreadQuotes)';
}


}

/// @nodoc
abstract mixin class _$BuyerRequestCopyWith<$Res> implements $BuyerRequestCopyWith<$Res> {
  factory _$BuyerRequestCopyWith(_BuyerRequest value, $Res Function(_BuyerRequest) _then) = __$BuyerRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String buyerId, int categoryId, String title, String description, Map<String, Object?> fields, Money? budgetMin, Money? budgetMax, bool budgetVisible, DateTime? neededBy, double? lat, double? lng, String? locationCode, String? locality, String? state, Audience audience, RequestStatus status, int quoteCount, int maxQuotes, DateTime? quoteWindowEndsAt, DateTime? priorityUntil, String? acceptedQuoteId, String? referenceLink, List<RequestMedia> media, DateTime createdAt, int notifiedSellers, int unreadQuotes
});




}
/// @nodoc
class __$BuyerRequestCopyWithImpl<$Res>
    implements _$BuyerRequestCopyWith<$Res> {
  __$BuyerRequestCopyWithImpl(this._self, this._then);

  final _BuyerRequest _self;
  final $Res Function(_BuyerRequest) _then;

/// Create a copy of BuyerRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buyerId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? fields = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? budgetVisible = null,Object? neededBy = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationCode = freezed,Object? locality = freezed,Object? state = freezed,Object? audience = null,Object? status = null,Object? quoteCount = null,Object? maxQuotes = null,Object? quoteWindowEndsAt = freezed,Object? priorityUntil = freezed,Object? acceptedQuoteId = freezed,Object? referenceLink = freezed,Object? media = null,Object? createdAt = null,Object? notifiedSellers = null,Object? unreadQuotes = null,}) {
  return _then(_BuyerRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,budgetVisible: null == budgetVisible ? _self.budgetVisible : budgetVisible // ignore: cast_nullable_to_non_nullable
as bool,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,maxQuotes: null == maxQuotes ? _self.maxQuotes : maxQuotes // ignore: cast_nullable_to_non_nullable
as int,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priorityUntil: freezed == priorityUntil ? _self.priorityUntil : priorityUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedQuoteId: freezed == acceptedQuoteId ? _self.acceptedQuoteId : acceptedQuoteId // ignore: cast_nullable_to_non_nullable
as String?,referenceLink: freezed == referenceLink ? _self.referenceLink : referenceLink // ignore: cast_nullable_to_non_nullable
as String?,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<RequestMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,notifiedSellers: null == notifiedSellers ? _self.notifiedSellers : notifiedSellers // ignore: cast_nullable_to_non_nullable
as int,unreadQuotes: null == unreadQuotes ? _self.unreadQuotes : unreadQuotes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$RequestDraft {

 String get text; int? get categoryId; Map<String, Object?> get fields; List<String> get localMediaPaths; String? get referenceLink; Money? get budgetMin; Money? get budgetMax; bool get budgetVisible; DateTime? get neededBy; double? get lat; double? get lng; String? get locationCode; String? get locality; String? get state; String? get fullAddress; QuoteWindow get quoteWindow; Audience get audience; String? get invitedBySellerId;
/// Create a copy of RequestDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestDraftCopyWith<RequestDraft> get copyWith => _$RequestDraftCopyWithImpl<RequestDraft>(this as RequestDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RequestDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestDraft&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&const DeepCollectionEquality().equals(other.fields, _this.fields)&&const DeepCollectionEquality().equals(other.localMediaPaths, _this.localMediaPaths)&&(identical(other.referenceLink, _this.referenceLink) || other.referenceLink == _this.referenceLink)&&(identical(other.budgetMin, _this.budgetMin) || other.budgetMin == _this.budgetMin)&&(identical(other.budgetMax, _this.budgetMax) || other.budgetMax == _this.budgetMax)&&(identical(other.budgetVisible, _this.budgetVisible) || other.budgetVisible == _this.budgetVisible)&&(identical(other.neededBy, _this.neededBy) || other.neededBy == _this.neededBy)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.locationCode, _this.locationCode) || other.locationCode == _this.locationCode)&&(identical(other.locality, _this.locality) || other.locality == _this.locality)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.fullAddress, _this.fullAddress) || other.fullAddress == _this.fullAddress)&&(identical(other.quoteWindow, _this.quoteWindow) || other.quoteWindow == _this.quoteWindow)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.invitedBySellerId, _this.invitedBySellerId) || other.invitedBySellerId == _this.invitedBySellerId));
}


@override
int get hashCode {
  final _this = this as RequestDraft;
  return Object.hash(runtimeType,_this.text,_this.categoryId,const DeepCollectionEquality().hash(_this.fields),const DeepCollectionEquality().hash(_this.localMediaPaths),_this.referenceLink,_this.budgetMin,_this.budgetMax,_this.budgetVisible,_this.neededBy,_this.lat,_this.lng,_this.locationCode,_this.locality,_this.state,_this.fullAddress,_this.quoteWindow,_this.audience,_this.invitedBySellerId);
}

@override
String toString() {
  final _this = this as RequestDraft;
  return 'RequestDraft(text: ${_this.text}, categoryId: ${_this.categoryId}, fields: ${_this.fields}, localMediaPaths: ${_this.localMediaPaths}, referenceLink: ${_this.referenceLink}, budgetMin: ${_this.budgetMin}, budgetMax: ${_this.budgetMax}, budgetVisible: ${_this.budgetVisible}, neededBy: ${_this.neededBy}, lat: ${_this.lat}, lng: ${_this.lng}, locationCode: ${_this.locationCode}, locality: ${_this.locality}, state: ${_this.state}, fullAddress: ${_this.fullAddress}, quoteWindow: ${_this.quoteWindow}, audience: ${_this.audience}, invitedBySellerId: ${_this.invitedBySellerId})';
}


}

/// @nodoc
abstract mixin class $RequestDraftCopyWith<$Res>  {
  factory $RequestDraftCopyWith(RequestDraft value, $Res Function(RequestDraft) _then) = _$RequestDraftCopyWithImpl;
@useResult
$Res call({
 String text, int? categoryId, Map<String, Object?> fields, List<String> localMediaPaths, String? referenceLink, Money? budgetMin, Money? budgetMax, bool budgetVisible, DateTime? neededBy, double? lat, double? lng, String? locationCode, String? locality, String? state, String? fullAddress, QuoteWindow quoteWindow, Audience audience, String? invitedBySellerId
});




}
/// @nodoc
class _$RequestDraftCopyWithImpl<$Res>
    implements $RequestDraftCopyWith<$Res> {
  _$RequestDraftCopyWithImpl(this._self, this._then);

  final RequestDraft _self;
  final $Res Function(RequestDraft) _then;

/// Create a copy of RequestDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? categoryId = freezed,Object? fields = null,Object? localMediaPaths = null,Object? referenceLink = freezed,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? budgetVisible = null,Object? neededBy = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationCode = freezed,Object? locality = freezed,Object? state = freezed,Object? fullAddress = freezed,Object? quoteWindow = null,Object? audience = null,Object? invitedBySellerId = freezed,}) {
  return _then(RequestDraft(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,localMediaPaths: null == localMediaPaths ? _self.localMediaPaths : localMediaPaths // ignore: cast_nullable_to_non_nullable
as List<String>,referenceLink: freezed == referenceLink ? _self.referenceLink : referenceLink // ignore: cast_nullable_to_non_nullable
as String?,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,budgetVisible: null == budgetVisible ? _self.budgetVisible : budgetVisible // ignore: cast_nullable_to_non_nullable
as bool,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,quoteWindow: null == quoteWindow ? _self.quoteWindow : quoteWindow // ignore: cast_nullable_to_non_nullable
as QuoteWindow,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,invitedBySellerId: freezed == invitedBySellerId ? _self.invitedBySellerId : invitedBySellerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestDraft].
extension RequestDraftPatterns on RequestDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestDraft value)  $default,){
final _that = this;
switch (_that) {
case _RequestDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestDraft value)?  $default,){
final _that = this;
switch (_that) {
case _RequestDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int? categoryId,  Map<String, Object?> fields,  List<String> localMediaPaths,  String? referenceLink,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  String? fullAddress,  QuoteWindow quoteWindow,  Audience audience,  String? invitedBySellerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestDraft() when $default != null:
return $default(_that.text,_that.categoryId,_that.fields,_that.localMediaPaths,_that.referenceLink,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.fullAddress,_that.quoteWindow,_that.audience,_that.invitedBySellerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int? categoryId,  Map<String, Object?> fields,  List<String> localMediaPaths,  String? referenceLink,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  String? fullAddress,  QuoteWindow quoteWindow,  Audience audience,  String? invitedBySellerId)  $default,) {final _that = this;
switch (_that) {
case _RequestDraft():
return $default(_that.text,_that.categoryId,_that.fields,_that.localMediaPaths,_that.referenceLink,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.fullAddress,_that.quoteWindow,_that.audience,_that.invitedBySellerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int? categoryId,  Map<String, Object?> fields,  List<String> localMediaPaths,  String? referenceLink,  Money? budgetMin,  Money? budgetMax,  bool budgetVisible,  DateTime? neededBy,  double? lat,  double? lng,  String? locationCode,  String? locality,  String? state,  String? fullAddress,  QuoteWindow quoteWindow,  Audience audience,  String? invitedBySellerId)?  $default,) {final _that = this;
switch (_that) {
case _RequestDraft() when $default != null:
return $default(_that.text,_that.categoryId,_that.fields,_that.localMediaPaths,_that.referenceLink,_that.budgetMin,_that.budgetMax,_that.budgetVisible,_that.neededBy,_that.lat,_that.lng,_that.locationCode,_that.locality,_that.state,_that.fullAddress,_that.quoteWindow,_that.audience,_that.invitedBySellerId);case _:
  return null;

}
}

}

/// @nodoc


class _RequestDraft implements RequestDraft {
  const _RequestDraft({this.text = '', this.categoryId,  Map<String, Object?> fields = const {},  List<String> localMediaPaths = const [], this.referenceLink, this.budgetMin, this.budgetMax, this.budgetVisible = true, this.neededBy, this.lat, this.lng, this.locationCode, this.locality, this.state, this.fullAddress, this.quoteWindow = QuoteWindow.h48, this.audience = Audience.both, this.invitedBySellerId}): _fields = fields,_localMediaPaths = localMediaPaths;
  

@override@JsonKey() final  String text;
@override final  int? categoryId;
 final  Map<String, Object?> _fields;
@override@JsonKey() Map<String, Object?> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}

 final  List<String> _localMediaPaths;
@override@JsonKey() List<String> get localMediaPaths {
  if (_localMediaPaths is EqualUnmodifiableListView) return _localMediaPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_localMediaPaths);
}

@override final  String? referenceLink;
@override final  Money? budgetMin;
@override final  Money? budgetMax;
@override@JsonKey() final  bool budgetVisible;
@override final  DateTime? neededBy;
@override final  double? lat;
@override final  double? lng;
@override final  String? locationCode;
@override final  String? locality;
@override final  String? state;
@override final  String? fullAddress;
@override@JsonKey() final  QuoteWindow quoteWindow;
@override@JsonKey() final  Audience audience;
@override final  String? invitedBySellerId;

/// Create a copy of RequestDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestDraftCopyWith<_RequestDraft> get copyWith => __$RequestDraftCopyWithImpl<_RequestDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestDraft&&(identical(other.text, text) || other.text == text)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.fields, _fields)&&const DeepCollectionEquality().equals(other.localMediaPaths, _localMediaPaths)&&(identical(other.referenceLink, referenceLink) || other.referenceLink == referenceLink)&&(identical(other.budgetMin, budgetMin) || other.budgetMin == budgetMin)&&(identical(other.budgetMax, budgetMax) || other.budgetMax == budgetMax)&&(identical(other.budgetVisible, budgetVisible) || other.budgetVisible == budgetVisible)&&(identical(other.neededBy, neededBy) || other.neededBy == neededBy)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationCode, locationCode) || other.locationCode == locationCode)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.state, state) || other.state == state)&&(identical(other.fullAddress, fullAddress) || other.fullAddress == fullAddress)&&(identical(other.quoteWindow, quoteWindow) || other.quoteWindow == quoteWindow)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.invitedBySellerId, invitedBySellerId) || other.invitedBySellerId == invitedBySellerId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text,categoryId,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_localMediaPaths),referenceLink,budgetMin,budgetMax,budgetVisible,neededBy,lat,lng,locationCode,locality,state,fullAddress,quoteWindow,audience,invitedBySellerId);
}

@override
String toString() {
    return 'RequestDraft(text: $text, categoryId: $categoryId, fields: $fields, localMediaPaths: $localMediaPaths, referenceLink: $referenceLink, budgetMin: $budgetMin, budgetMax: $budgetMax, budgetVisible: $budgetVisible, neededBy: $neededBy, lat: $lat, lng: $lng, locationCode: $locationCode, locality: $locality, state: $state, fullAddress: $fullAddress, quoteWindow: $quoteWindow, audience: $audience, invitedBySellerId: $invitedBySellerId)';
}


}

/// @nodoc
abstract mixin class _$RequestDraftCopyWith<$Res> implements $RequestDraftCopyWith<$Res> {
  factory _$RequestDraftCopyWith(_RequestDraft value, $Res Function(_RequestDraft) _then) = __$RequestDraftCopyWithImpl;
@override @useResult
$Res call({
 String text, int? categoryId, Map<String, Object?> fields, List<String> localMediaPaths, String? referenceLink, Money? budgetMin, Money? budgetMax, bool budgetVisible, DateTime? neededBy, double? lat, double? lng, String? locationCode, String? locality, String? state, String? fullAddress, QuoteWindow quoteWindow, Audience audience, String? invitedBySellerId
});




}
/// @nodoc
class __$RequestDraftCopyWithImpl<$Res>
    implements _$RequestDraftCopyWith<$Res> {
  __$RequestDraftCopyWithImpl(this._self, this._then);

  final _RequestDraft _self;
  final $Res Function(_RequestDraft) _then;

/// Create a copy of RequestDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? categoryId = freezed,Object? fields = null,Object? localMediaPaths = null,Object? referenceLink = freezed,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? budgetVisible = null,Object? neededBy = freezed,Object? lat = freezed,Object? lng = freezed,Object? locationCode = freezed,Object? locality = freezed,Object? state = freezed,Object? fullAddress = freezed,Object? quoteWindow = null,Object? audience = null,Object? invitedBySellerId = freezed,}) {
  return _then(_RequestDraft(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,localMediaPaths: null == localMediaPaths ? _self._localMediaPaths : localMediaPaths // ignore: cast_nullable_to_non_nullable
as List<String>,referenceLink: freezed == referenceLink ? _self.referenceLink : referenceLink // ignore: cast_nullable_to_non_nullable
as String?,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,budgetVisible: null == budgetVisible ? _self.budgetVisible : budgetVisible // ignore: cast_nullable_to_non_nullable
as bool,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,fullAddress: freezed == fullAddress ? _self.fullAddress : fullAddress // ignore: cast_nullable_to_non_nullable
as String?,quoteWindow: null == quoteWindow ? _self.quoteWindow : quoteWindow // ignore: cast_nullable_to_non_nullable
as QuoteWindow,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,invitedBySellerId: freezed == invitedBySellerId ? _self.invitedBySellerId : invitedBySellerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
