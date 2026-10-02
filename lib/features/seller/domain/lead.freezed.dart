// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lead.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Lead {

 String get requestId; int get categoryId; String get title; String get description; Map<String, Object?> get fields; Money? get budgetMin; Money? get budgetMax; DateTime? get neededBy; String? get locality; String? get locationCode; String? get state; double? get distanceKm; Audience get audience; int get quoteCount; int get maxQuotes; DateTime? get quoteWindowEndsAt; DateTime get createdAt; List<RequestMedia> get media; bool get seen; bool get alreadyQuoted; String? get buyerFirstName;
/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadCopyWith<Lead> get copyWith => _$LeadCopyWithImpl<Lead>(this as Lead, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Lead;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lead&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.fields, _this.fields)&&(identical(other.budgetMin, _this.budgetMin) || other.budgetMin == _this.budgetMin)&&(identical(other.budgetMax, _this.budgetMax) || other.budgetMax == _this.budgetMax)&&(identical(other.neededBy, _this.neededBy) || other.neededBy == _this.neededBy)&&(identical(other.locality, _this.locality) || other.locality == _this.locality)&&(identical(other.locationCode, _this.locationCode) || other.locationCode == _this.locationCode)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.quoteCount, _this.quoteCount) || other.quoteCount == _this.quoteCount)&&(identical(other.maxQuotes, _this.maxQuotes) || other.maxQuotes == _this.maxQuotes)&&(identical(other.quoteWindowEndsAt, _this.quoteWindowEndsAt) || other.quoteWindowEndsAt == _this.quoteWindowEndsAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.media, _this.media)&&(identical(other.seen, _this.seen) || other.seen == _this.seen)&&(identical(other.alreadyQuoted, _this.alreadyQuoted) || other.alreadyQuoted == _this.alreadyQuoted)&&(identical(other.buyerFirstName, _this.buyerFirstName) || other.buyerFirstName == _this.buyerFirstName));
}


@override
int get hashCode {
  final _this = this as Lead;
  return Object.hashAll([runtimeType,_this.requestId,_this.categoryId,_this.title,_this.description,const DeepCollectionEquality().hash(_this.fields),_this.budgetMin,_this.budgetMax,_this.neededBy,_this.locality,_this.locationCode,_this.state,_this.distanceKm,_this.audience,_this.quoteCount,_this.maxQuotes,_this.quoteWindowEndsAt,_this.createdAt,const DeepCollectionEquality().hash(_this.media),_this.seen,_this.alreadyQuoted,_this.buyerFirstName]);
}

@override
String toString() {
  final _this = this as Lead;
  return 'Lead(requestId: ${_this.requestId}, categoryId: ${_this.categoryId}, title: ${_this.title}, description: ${_this.description}, fields: ${_this.fields}, budgetMin: ${_this.budgetMin}, budgetMax: ${_this.budgetMax}, neededBy: ${_this.neededBy}, locality: ${_this.locality}, locationCode: ${_this.locationCode}, state: ${_this.state}, distanceKm: ${_this.distanceKm}, audience: ${_this.audience}, quoteCount: ${_this.quoteCount}, maxQuotes: ${_this.maxQuotes}, quoteWindowEndsAt: ${_this.quoteWindowEndsAt}, createdAt: ${_this.createdAt}, media: ${_this.media}, seen: ${_this.seen}, alreadyQuoted: ${_this.alreadyQuoted}, buyerFirstName: ${_this.buyerFirstName})';
}


}

/// @nodoc
abstract mixin class $LeadCopyWith<$Res>  {
  factory $LeadCopyWith(Lead value, $Res Function(Lead) _then) = _$LeadCopyWithImpl;
@useResult
$Res call({
 String requestId, int categoryId, String title, String description, Map<String, Object?> fields, Money? budgetMin, Money? budgetMax, DateTime? neededBy, String? locality, String? locationCode, String? state, double? distanceKm, Audience audience, int quoteCount, int maxQuotes, DateTime? quoteWindowEndsAt, DateTime createdAt, List<RequestMedia> media, bool seen, bool alreadyQuoted, String? buyerFirstName
});




}
/// @nodoc
class _$LeadCopyWithImpl<$Res>
    implements $LeadCopyWith<$Res> {
  _$LeadCopyWithImpl(this._self, this._then);

  final Lead _self;
  final $Res Function(Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? fields = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? neededBy = freezed,Object? locality = freezed,Object? locationCode = freezed,Object? state = freezed,Object? distanceKm = freezed,Object? audience = null,Object? quoteCount = null,Object? maxQuotes = null,Object? quoteWindowEndsAt = freezed,Object? createdAt = null,Object? media = null,Object? seen = null,Object? alreadyQuoted = null,Object? buyerFirstName = freezed,}) {
  return _then(Lead(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,maxQuotes: null == maxQuotes ? _self.maxQuotes : maxQuotes // ignore: cast_nullable_to_non_nullable
as int,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<RequestMedia>,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,alreadyQuoted: null == alreadyQuoted ? _self.alreadyQuoted : alreadyQuoted // ignore: cast_nullable_to_non_nullable
as bool,buyerFirstName: freezed == buyerFirstName ? _self.buyerFirstName : buyerFirstName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Lead].
extension LeadPatterns on Lead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lead value)  $default,){
final _that = this;
switch (_that) {
case _Lead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lead value)?  $default,){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? locationCode,  String? state,  double? distanceKm,  Audience audience,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime createdAt,  List<RequestMedia> media,  bool seen,  bool alreadyQuoted,  String? buyerFirstName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.requestId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.locationCode,_that.state,_that.distanceKm,_that.audience,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.createdAt,_that.media,_that.seen,_that.alreadyQuoted,_that.buyerFirstName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? locationCode,  String? state,  double? distanceKm,  Audience audience,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime createdAt,  List<RequestMedia> media,  bool seen,  bool alreadyQuoted,  String? buyerFirstName)  $default,) {final _that = this;
switch (_that) {
case _Lead():
return $default(_that.requestId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.locationCode,_that.state,_that.distanceKm,_that.audience,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.createdAt,_that.media,_that.seen,_that.alreadyQuoted,_that.buyerFirstName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  int categoryId,  String title,  String description,  Map<String, Object?> fields,  Money? budgetMin,  Money? budgetMax,  DateTime? neededBy,  String? locality,  String? locationCode,  String? state,  double? distanceKm,  Audience audience,  int quoteCount,  int maxQuotes,  DateTime? quoteWindowEndsAt,  DateTime createdAt,  List<RequestMedia> media,  bool seen,  bool alreadyQuoted,  String? buyerFirstName)?  $default,) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.requestId,_that.categoryId,_that.title,_that.description,_that.fields,_that.budgetMin,_that.budgetMax,_that.neededBy,_that.locality,_that.locationCode,_that.state,_that.distanceKm,_that.audience,_that.quoteCount,_that.maxQuotes,_that.quoteWindowEndsAt,_that.createdAt,_that.media,_that.seen,_that.alreadyQuoted,_that.buyerFirstName);case _:
  return null;

}
}

}

/// @nodoc


class _Lead extends Lead {
  const _Lead({required this.requestId, required this.categoryId, required this.title, this.description = '',  Map<String, Object?> fields = const {}, this.budgetMin, this.budgetMax, this.neededBy, this.locality, this.locationCode, this.state, this.distanceKm, this.audience = Audience.both, this.quoteCount = 0, this.maxQuotes = 10, this.quoteWindowEndsAt, required this.createdAt,  List<RequestMedia> media = const [], this.seen = false, this.alreadyQuoted = false, this.buyerFirstName}): _fields = fields,_media = media,super._();
  

@override final  String requestId;
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
@override final  DateTime? neededBy;
@override final  String? locality;
@override final  String? locationCode;
@override final  String? state;
@override final  double? distanceKm;
@override@JsonKey() final  Audience audience;
@override@JsonKey() final  int quoteCount;
@override@JsonKey() final  int maxQuotes;
@override final  DateTime? quoteWindowEndsAt;
@override final  DateTime createdAt;
 final  List<RequestMedia> _media;
@override@JsonKey() List<RequestMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override@JsonKey() final  bool seen;
@override@JsonKey() final  bool alreadyQuoted;
@override final  String? buyerFirstName;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadCopyWith<_Lead> get copyWith => __$LeadCopyWithImpl<_Lead>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lead&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.fields, _fields)&&(identical(other.budgetMin, budgetMin) || other.budgetMin == budgetMin)&&(identical(other.budgetMax, budgetMax) || other.budgetMax == budgetMax)&&(identical(other.neededBy, neededBy) || other.neededBy == neededBy)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.locationCode, locationCode) || other.locationCode == locationCode)&&(identical(other.state, state) || other.state == state)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.quoteCount, quoteCount) || other.quoteCount == quoteCount)&&(identical(other.maxQuotes, maxQuotes) || other.maxQuotes == maxQuotes)&&(identical(other.quoteWindowEndsAt, quoteWindowEndsAt) || other.quoteWindowEndsAt == quoteWindowEndsAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.media, _media)&&(identical(other.seen, seen) || other.seen == seen)&&(identical(other.alreadyQuoted, alreadyQuoted) || other.alreadyQuoted == alreadyQuoted)&&(identical(other.buyerFirstName, buyerFirstName) || other.buyerFirstName == buyerFirstName));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,requestId,categoryId,title,description,const DeepCollectionEquality().hash(_fields),budgetMin,budgetMax,neededBy,locality,locationCode,state,distanceKm,audience,quoteCount,maxQuotes,quoteWindowEndsAt,createdAt,const DeepCollectionEquality().hash(_media),seen,alreadyQuoted,buyerFirstName]);
}

@override
String toString() {
    return 'Lead(requestId: $requestId, categoryId: $categoryId, title: $title, description: $description, fields: $fields, budgetMin: $budgetMin, budgetMax: $budgetMax, neededBy: $neededBy, locality: $locality, locationCode: $locationCode, state: $state, distanceKm: $distanceKm, audience: $audience, quoteCount: $quoteCount, maxQuotes: $maxQuotes, quoteWindowEndsAt: $quoteWindowEndsAt, createdAt: $createdAt, media: $media, seen: $seen, alreadyQuoted: $alreadyQuoted, buyerFirstName: $buyerFirstName)';
}


}

/// @nodoc
abstract mixin class _$LeadCopyWith<$Res> implements $LeadCopyWith<$Res> {
  factory _$LeadCopyWith(_Lead value, $Res Function(_Lead) _then) = __$LeadCopyWithImpl;
@override @useResult
$Res call({
 String requestId, int categoryId, String title, String description, Map<String, Object?> fields, Money? budgetMin, Money? budgetMax, DateTime? neededBy, String? locality, String? locationCode, String? state, double? distanceKm, Audience audience, int quoteCount, int maxQuotes, DateTime? quoteWindowEndsAt, DateTime createdAt, List<RequestMedia> media, bool seen, bool alreadyQuoted, String? buyerFirstName
});




}
/// @nodoc
class __$LeadCopyWithImpl<$Res>
    implements _$LeadCopyWith<$Res> {
  __$LeadCopyWithImpl(this._self, this._then);

  final _Lead _self;
  final $Res Function(_Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? fields = null,Object? budgetMin = freezed,Object? budgetMax = freezed,Object? neededBy = freezed,Object? locality = freezed,Object? locationCode = freezed,Object? state = freezed,Object? distanceKm = freezed,Object? audience = null,Object? quoteCount = null,Object? maxQuotes = null,Object? quoteWindowEndsAt = freezed,Object? createdAt = null,Object? media = null,Object? seen = null,Object? alreadyQuoted = null,Object? buyerFirstName = freezed,}) {
  return _then(_Lead(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,budgetMin: freezed == budgetMin ? _self.budgetMin : budgetMin // ignore: cast_nullable_to_non_nullable
as Money?,budgetMax: freezed == budgetMax ? _self.budgetMax : budgetMax // ignore: cast_nullable_to_non_nullable
as Money?,neededBy: freezed == neededBy ? _self.neededBy : neededBy // ignore: cast_nullable_to_non_nullable
as DateTime?,locality: freezed == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as String?,locationCode: freezed == locationCode ? _self.locationCode : locationCode // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Audience,quoteCount: null == quoteCount ? _self.quoteCount : quoteCount // ignore: cast_nullable_to_non_nullable
as int,maxQuotes: null == maxQuotes ? _self.maxQuotes : maxQuotes // ignore: cast_nullable_to_non_nullable
as int,quoteWindowEndsAt: freezed == quoteWindowEndsAt ? _self.quoteWindowEndsAt : quoteWindowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<RequestMedia>,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,alreadyQuoted: null == alreadyQuoted ? _self.alreadyQuoted : alreadyQuoted // ignore: cast_nullable_to_non_nullable
as bool,buyerFirstName: freezed == buyerFirstName ? _self.buyerFirstName : buyerFirstName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$LeadFilters {

 int? get categoryId; int? get maxDistanceKm; Money? get minBudget; DateTime? get neededBefore;
/// Create a copy of LeadFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadFiltersCopyWith<LeadFilters> get copyWith => _$LeadFiltersCopyWithImpl<LeadFilters>(this as LeadFilters, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeadFilters;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadFilters&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.maxDistanceKm, _this.maxDistanceKm) || other.maxDistanceKm == _this.maxDistanceKm)&&(identical(other.minBudget, _this.minBudget) || other.minBudget == _this.minBudget)&&(identical(other.neededBefore, _this.neededBefore) || other.neededBefore == _this.neededBefore));
}


@override
int get hashCode {
  final _this = this as LeadFilters;
  return Object.hash(runtimeType,_this.categoryId,_this.maxDistanceKm,_this.minBudget,_this.neededBefore);
}

@override
String toString() {
  final _this = this as LeadFilters;
  return 'LeadFilters(categoryId: ${_this.categoryId}, maxDistanceKm: ${_this.maxDistanceKm}, minBudget: ${_this.minBudget}, neededBefore: ${_this.neededBefore})';
}


}

/// @nodoc
abstract mixin class $LeadFiltersCopyWith<$Res>  {
  factory $LeadFiltersCopyWith(LeadFilters value, $Res Function(LeadFilters) _then) = _$LeadFiltersCopyWithImpl;
@useResult
$Res call({
 int? categoryId, int? maxDistanceKm, Money? minBudget, DateTime? neededBefore
});




}
/// @nodoc
class _$LeadFiltersCopyWithImpl<$Res>
    implements $LeadFiltersCopyWith<$Res> {
  _$LeadFiltersCopyWithImpl(this._self, this._then);

  final LeadFilters _self;
  final $Res Function(LeadFilters) _then;

/// Create a copy of LeadFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = freezed,Object? maxDistanceKm = freezed,Object? minBudget = freezed,Object? neededBefore = freezed,}) {
  return _then(LeadFilters(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,maxDistanceKm: freezed == maxDistanceKm ? _self.maxDistanceKm : maxDistanceKm // ignore: cast_nullable_to_non_nullable
as int?,minBudget: freezed == minBudget ? _self.minBudget : minBudget // ignore: cast_nullable_to_non_nullable
as Money?,neededBefore: freezed == neededBefore ? _self.neededBefore : neededBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadFilters].
extension LeadFiltersPatterns on LeadFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadFilters value)  $default,){
final _that = this;
switch (_that) {
case _LeadFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadFilters value)?  $default,){
final _that = this;
switch (_that) {
case _LeadFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? categoryId,  int? maxDistanceKm,  Money? minBudget,  DateTime? neededBefore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadFilters() when $default != null:
return $default(_that.categoryId,_that.maxDistanceKm,_that.minBudget,_that.neededBefore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? categoryId,  int? maxDistanceKm,  Money? minBudget,  DateTime? neededBefore)  $default,) {final _that = this;
switch (_that) {
case _LeadFilters():
return $default(_that.categoryId,_that.maxDistanceKm,_that.minBudget,_that.neededBefore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? categoryId,  int? maxDistanceKm,  Money? minBudget,  DateTime? neededBefore)?  $default,) {final _that = this;
switch (_that) {
case _LeadFilters() when $default != null:
return $default(_that.categoryId,_that.maxDistanceKm,_that.minBudget,_that.neededBefore);case _:
  return null;

}
}

}

/// @nodoc


class _LeadFilters implements LeadFilters {
  const _LeadFilters({this.categoryId, this.maxDistanceKm, this.minBudget, this.neededBefore});
  

@override final  int? categoryId;
@override final  int? maxDistanceKm;
@override final  Money? minBudget;
@override final  DateTime? neededBefore;

/// Create a copy of LeadFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadFiltersCopyWith<_LeadFilters> get copyWith => __$LeadFiltersCopyWithImpl<_LeadFilters>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadFilters&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.maxDistanceKm, maxDistanceKm) || other.maxDistanceKm == maxDistanceKm)&&(identical(other.minBudget, minBudget) || other.minBudget == minBudget)&&(identical(other.neededBefore, neededBefore) || other.neededBefore == neededBefore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,maxDistanceKm,minBudget,neededBefore);
}

@override
String toString() {
    return 'LeadFilters(categoryId: $categoryId, maxDistanceKm: $maxDistanceKm, minBudget: $minBudget, neededBefore: $neededBefore)';
}


}

/// @nodoc
abstract mixin class _$LeadFiltersCopyWith<$Res> implements $LeadFiltersCopyWith<$Res> {
  factory _$LeadFiltersCopyWith(_LeadFilters value, $Res Function(_LeadFilters) _then) = __$LeadFiltersCopyWithImpl;
@override @useResult
$Res call({
 int? categoryId, int? maxDistanceKm, Money? minBudget, DateTime? neededBefore
});




}
/// @nodoc
class __$LeadFiltersCopyWithImpl<$Res>
    implements _$LeadFiltersCopyWith<$Res> {
  __$LeadFiltersCopyWithImpl(this._self, this._then);

  final _LeadFilters _self;
  final $Res Function(_LeadFilters) _then;

/// Create a copy of LeadFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,Object? maxDistanceKm = freezed,Object? minBudget = freezed,Object? neededBefore = freezed,}) {
  return _then(_LeadFilters(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,maxDistanceKm: freezed == maxDistanceKm ? _self.maxDistanceKm : maxDistanceKm // ignore: cast_nullable_to_non_nullable
as int?,minBudget: freezed == minBudget ? _self.minBudget : minBudget // ignore: cast_nullable_to_non_nullable
as Money?,neededBefore: freezed == neededBefore ? _self.neededBefore : neededBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$LeadPage {

 List<Lead> get leads; String? get nextCursor;
/// Create a copy of LeadPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadPageCopyWith<LeadPage> get copyWith => _$LeadPageCopyWithImpl<LeadPage>(this as LeadPage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeadPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadPage&&const DeepCollectionEquality().equals(other.leads, _this.leads)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}


@override
int get hashCode {
  final _this = this as LeadPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.leads),_this.nextCursor);
}

@override
String toString() {
  final _this = this as LeadPage;
  return 'LeadPage(leads: ${_this.leads}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $LeadPageCopyWith<$Res>  {
  factory $LeadPageCopyWith(LeadPage value, $Res Function(LeadPage) _then) = _$LeadPageCopyWithImpl;
@useResult
$Res call({
 List<Lead> leads, String? nextCursor
});




}
/// @nodoc
class _$LeadPageCopyWithImpl<$Res>
    implements $LeadPageCopyWith<$Res> {
  _$LeadPageCopyWithImpl(this._self, this._then);

  final LeadPage _self;
  final $Res Function(LeadPage) _then;

/// Create a copy of LeadPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? leads = null,Object? nextCursor = freezed,}) {
  return _then(LeadPage(
leads: null == leads ? _self.leads : leads // ignore: cast_nullable_to_non_nullable
as List<Lead>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadPage].
extension LeadPagePatterns on LeadPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadPage value)  $default,){
final _that = this;
switch (_that) {
case _LeadPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadPage value)?  $default,){
final _that = this;
switch (_that) {
case _LeadPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Lead> leads,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadPage() when $default != null:
return $default(_that.leads,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Lead> leads,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _LeadPage():
return $default(_that.leads,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Lead> leads,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _LeadPage() when $default != null:
return $default(_that.leads,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc


class _LeadPage implements LeadPage {
  const _LeadPage({required  List<Lead> leads, this.nextCursor}): _leads = leads;
  

 final  List<Lead> _leads;
@override List<Lead> get leads {
  if (_leads is EqualUnmodifiableListView) return _leads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_leads);
}

@override final  String? nextCursor;

/// Create a copy of LeadPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadPageCopyWith<_LeadPage> get copyWith => __$LeadPageCopyWithImpl<_LeadPage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadPage&&const DeepCollectionEquality().equals(other.leads, _leads)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_leads),nextCursor);
}

@override
String toString() {
    return 'LeadPage(leads: $leads, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$LeadPageCopyWith<$Res> implements $LeadPageCopyWith<$Res> {
  factory _$LeadPageCopyWith(_LeadPage value, $Res Function(_LeadPage) _then) = __$LeadPageCopyWithImpl;
@override @useResult
$Res call({
 List<Lead> leads, String? nextCursor
});




}
/// @nodoc
class __$LeadPageCopyWithImpl<$Res>
    implements _$LeadPageCopyWith<$Res> {
  __$LeadPageCopyWithImpl(this._self, this._then);

  final _LeadPage _self;
  final $Res Function(_LeadPage) _then;

/// Create a copy of LeadPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leads = null,Object? nextCursor = freezed,}) {
  return _then(_LeadPage(
leads: null == leads ? _self._leads : leads // ignore: cast_nullable_to_non_nullable
as List<Lead>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
