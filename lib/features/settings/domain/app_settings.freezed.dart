// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFlags {

 bool get monetizationEnabled; int get quoteCap; int get priorityWindowMinutes; DateTime? get earlyPartnerFreeUntil; int get maxRequestsPerDay; bool get webPurchaseLinksAllowed; String get paywallDefaultPeriod; bool get whatsappNotifications; String get termsVersion; String get privacyVersion;
/// Create a copy of AppFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppFlagsCopyWith<AppFlags> get copyWith => _$AppFlagsCopyWithImpl<AppFlags>(this as AppFlags, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppFlags;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFlags&&(identical(other.monetizationEnabled, _this.monetizationEnabled) || other.monetizationEnabled == _this.monetizationEnabled)&&(identical(other.quoteCap, _this.quoteCap) || other.quoteCap == _this.quoteCap)&&(identical(other.priorityWindowMinutes, _this.priorityWindowMinutes) || other.priorityWindowMinutes == _this.priorityWindowMinutes)&&(identical(other.earlyPartnerFreeUntil, _this.earlyPartnerFreeUntil) || other.earlyPartnerFreeUntil == _this.earlyPartnerFreeUntil)&&(identical(other.maxRequestsPerDay, _this.maxRequestsPerDay) || other.maxRequestsPerDay == _this.maxRequestsPerDay)&&(identical(other.webPurchaseLinksAllowed, _this.webPurchaseLinksAllowed) || other.webPurchaseLinksAllowed == _this.webPurchaseLinksAllowed)&&(identical(other.paywallDefaultPeriod, _this.paywallDefaultPeriod) || other.paywallDefaultPeriod == _this.paywallDefaultPeriod)&&(identical(other.whatsappNotifications, _this.whatsappNotifications) || other.whatsappNotifications == _this.whatsappNotifications)&&(identical(other.termsVersion, _this.termsVersion) || other.termsVersion == _this.termsVersion)&&(identical(other.privacyVersion, _this.privacyVersion) || other.privacyVersion == _this.privacyVersion));
}


@override
int get hashCode {
  final _this = this as AppFlags;
  return Object.hash(runtimeType,_this.monetizationEnabled,_this.quoteCap,_this.priorityWindowMinutes,_this.earlyPartnerFreeUntil,_this.maxRequestsPerDay,_this.webPurchaseLinksAllowed,_this.paywallDefaultPeriod,_this.whatsappNotifications,_this.termsVersion,_this.privacyVersion);
}

@override
String toString() {
  final _this = this as AppFlags;
  return 'AppFlags(monetizationEnabled: ${_this.monetizationEnabled}, quoteCap: ${_this.quoteCap}, priorityWindowMinutes: ${_this.priorityWindowMinutes}, earlyPartnerFreeUntil: ${_this.earlyPartnerFreeUntil}, maxRequestsPerDay: ${_this.maxRequestsPerDay}, webPurchaseLinksAllowed: ${_this.webPurchaseLinksAllowed}, paywallDefaultPeriod: ${_this.paywallDefaultPeriod}, whatsappNotifications: ${_this.whatsappNotifications}, termsVersion: ${_this.termsVersion}, privacyVersion: ${_this.privacyVersion})';
}


}

/// @nodoc
abstract mixin class $AppFlagsCopyWith<$Res>  {
  factory $AppFlagsCopyWith(AppFlags value, $Res Function(AppFlags) _then) = _$AppFlagsCopyWithImpl;
@useResult
$Res call({
 bool monetizationEnabled, int quoteCap, int priorityWindowMinutes, DateTime? earlyPartnerFreeUntil, int maxRequestsPerDay, bool webPurchaseLinksAllowed, String paywallDefaultPeriod, bool whatsappNotifications, String termsVersion, String privacyVersion
});




}
/// @nodoc
class _$AppFlagsCopyWithImpl<$Res>
    implements $AppFlagsCopyWith<$Res> {
  _$AppFlagsCopyWithImpl(this._self, this._then);

  final AppFlags _self;
  final $Res Function(AppFlags) _then;

/// Create a copy of AppFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? monetizationEnabled = null,Object? quoteCap = null,Object? priorityWindowMinutes = null,Object? earlyPartnerFreeUntil = freezed,Object? maxRequestsPerDay = null,Object? webPurchaseLinksAllowed = null,Object? paywallDefaultPeriod = null,Object? whatsappNotifications = null,Object? termsVersion = null,Object? privacyVersion = null,}) {
  return _then(AppFlags(
monetizationEnabled: null == monetizationEnabled ? _self.monetizationEnabled : monetizationEnabled // ignore: cast_nullable_to_non_nullable
as bool,quoteCap: null == quoteCap ? _self.quoteCap : quoteCap // ignore: cast_nullable_to_non_nullable
as int,priorityWindowMinutes: null == priorityWindowMinutes ? _self.priorityWindowMinutes : priorityWindowMinutes // ignore: cast_nullable_to_non_nullable
as int,earlyPartnerFreeUntil: freezed == earlyPartnerFreeUntil ? _self.earlyPartnerFreeUntil : earlyPartnerFreeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,maxRequestsPerDay: null == maxRequestsPerDay ? _self.maxRequestsPerDay : maxRequestsPerDay // ignore: cast_nullable_to_non_nullable
as int,webPurchaseLinksAllowed: null == webPurchaseLinksAllowed ? _self.webPurchaseLinksAllowed : webPurchaseLinksAllowed // ignore: cast_nullable_to_non_nullable
as bool,paywallDefaultPeriod: null == paywallDefaultPeriod ? _self.paywallDefaultPeriod : paywallDefaultPeriod // ignore: cast_nullable_to_non_nullable
as String,whatsappNotifications: null == whatsappNotifications ? _self.whatsappNotifications : whatsappNotifications // ignore: cast_nullable_to_non_nullable
as bool,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppFlags].
extension AppFlagsPatterns on AppFlags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppFlags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppFlags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppFlags value)  $default,){
final _that = this;
switch (_that) {
case _AppFlags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppFlags value)?  $default,){
final _that = this;
switch (_that) {
case _AppFlags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool monetizationEnabled,  int quoteCap,  int priorityWindowMinutes,  DateTime? earlyPartnerFreeUntil,  int maxRequestsPerDay,  bool webPurchaseLinksAllowed,  String paywallDefaultPeriod,  bool whatsappNotifications,  String termsVersion,  String privacyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppFlags() when $default != null:
return $default(_that.monetizationEnabled,_that.quoteCap,_that.priorityWindowMinutes,_that.earlyPartnerFreeUntil,_that.maxRequestsPerDay,_that.webPurchaseLinksAllowed,_that.paywallDefaultPeriod,_that.whatsappNotifications,_that.termsVersion,_that.privacyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool monetizationEnabled,  int quoteCap,  int priorityWindowMinutes,  DateTime? earlyPartnerFreeUntil,  int maxRequestsPerDay,  bool webPurchaseLinksAllowed,  String paywallDefaultPeriod,  bool whatsappNotifications,  String termsVersion,  String privacyVersion)  $default,) {final _that = this;
switch (_that) {
case _AppFlags():
return $default(_that.monetizationEnabled,_that.quoteCap,_that.priorityWindowMinutes,_that.earlyPartnerFreeUntil,_that.maxRequestsPerDay,_that.webPurchaseLinksAllowed,_that.paywallDefaultPeriod,_that.whatsappNotifications,_that.termsVersion,_that.privacyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool monetizationEnabled,  int quoteCap,  int priorityWindowMinutes,  DateTime? earlyPartnerFreeUntil,  int maxRequestsPerDay,  bool webPurchaseLinksAllowed,  String paywallDefaultPeriod,  bool whatsappNotifications,  String termsVersion,  String privacyVersion)?  $default,) {final _that = this;
switch (_that) {
case _AppFlags() when $default != null:
return $default(_that.monetizationEnabled,_that.quoteCap,_that.priorityWindowMinutes,_that.earlyPartnerFreeUntil,_that.maxRequestsPerDay,_that.webPurchaseLinksAllowed,_that.paywallDefaultPeriod,_that.whatsappNotifications,_that.termsVersion,_that.privacyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _AppFlags implements AppFlags {
  const _AppFlags({this.monetizationEnabled = false, this.quoteCap = 10, this.priorityWindowMinutes = 15, this.earlyPartnerFreeUntil, this.maxRequestsPerDay = 10, this.webPurchaseLinksAllowed = false, this.paywallDefaultPeriod = 'monthly', this.whatsappNotifications = false, this.termsVersion = '1.0', this.privacyVersion = '1.0'});
  

@override@JsonKey() final  bool monetizationEnabled;
@override@JsonKey() final  int quoteCap;
@override@JsonKey() final  int priorityWindowMinutes;
@override final  DateTime? earlyPartnerFreeUntil;
@override@JsonKey() final  int maxRequestsPerDay;
@override@JsonKey() final  bool webPurchaseLinksAllowed;
@override@JsonKey() final  String paywallDefaultPeriod;
@override@JsonKey() final  bool whatsappNotifications;
@override@JsonKey() final  String termsVersion;
@override@JsonKey() final  String privacyVersion;

/// Create a copy of AppFlags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppFlagsCopyWith<_AppFlags> get copyWith => __$AppFlagsCopyWithImpl<_AppFlags>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppFlags&&(identical(other.monetizationEnabled, monetizationEnabled) || other.monetizationEnabled == monetizationEnabled)&&(identical(other.quoteCap, quoteCap) || other.quoteCap == quoteCap)&&(identical(other.priorityWindowMinutes, priorityWindowMinutes) || other.priorityWindowMinutes == priorityWindowMinutes)&&(identical(other.earlyPartnerFreeUntil, earlyPartnerFreeUntil) || other.earlyPartnerFreeUntil == earlyPartnerFreeUntil)&&(identical(other.maxRequestsPerDay, maxRequestsPerDay) || other.maxRequestsPerDay == maxRequestsPerDay)&&(identical(other.webPurchaseLinksAllowed, webPurchaseLinksAllowed) || other.webPurchaseLinksAllowed == webPurchaseLinksAllowed)&&(identical(other.paywallDefaultPeriod, paywallDefaultPeriod) || other.paywallDefaultPeriod == paywallDefaultPeriod)&&(identical(other.whatsappNotifications, whatsappNotifications) || other.whatsappNotifications == whatsappNotifications)&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.privacyVersion, privacyVersion) || other.privacyVersion == privacyVersion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,monetizationEnabled,quoteCap,priorityWindowMinutes,earlyPartnerFreeUntil,maxRequestsPerDay,webPurchaseLinksAllowed,paywallDefaultPeriod,whatsappNotifications,termsVersion,privacyVersion);
}

@override
String toString() {
    return 'AppFlags(monetizationEnabled: $monetizationEnabled, quoteCap: $quoteCap, priorityWindowMinutes: $priorityWindowMinutes, earlyPartnerFreeUntil: $earlyPartnerFreeUntil, maxRequestsPerDay: $maxRequestsPerDay, webPurchaseLinksAllowed: $webPurchaseLinksAllowed, paywallDefaultPeriod: $paywallDefaultPeriod, whatsappNotifications: $whatsappNotifications, termsVersion: $termsVersion, privacyVersion: $privacyVersion)';
}


}

/// @nodoc
abstract mixin class _$AppFlagsCopyWith<$Res> implements $AppFlagsCopyWith<$Res> {
  factory _$AppFlagsCopyWith(_AppFlags value, $Res Function(_AppFlags) _then) = __$AppFlagsCopyWithImpl;
@override @useResult
$Res call({
 bool monetizationEnabled, int quoteCap, int priorityWindowMinutes, DateTime? earlyPartnerFreeUntil, int maxRequestsPerDay, bool webPurchaseLinksAllowed, String paywallDefaultPeriod, bool whatsappNotifications, String termsVersion, String privacyVersion
});




}
/// @nodoc
class __$AppFlagsCopyWithImpl<$Res>
    implements _$AppFlagsCopyWith<$Res> {
  __$AppFlagsCopyWithImpl(this._self, this._then);

  final _AppFlags _self;
  final $Res Function(_AppFlags) _then;

/// Create a copy of AppFlags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? monetizationEnabled = null,Object? quoteCap = null,Object? priorityWindowMinutes = null,Object? earlyPartnerFreeUntil = freezed,Object? maxRequestsPerDay = null,Object? webPurchaseLinksAllowed = null,Object? paywallDefaultPeriod = null,Object? whatsappNotifications = null,Object? termsVersion = null,Object? privacyVersion = null,}) {
  return _then(_AppFlags(
monetizationEnabled: null == monetizationEnabled ? _self.monetizationEnabled : monetizationEnabled // ignore: cast_nullable_to_non_nullable
as bool,quoteCap: null == quoteCap ? _self.quoteCap : quoteCap // ignore: cast_nullable_to_non_nullable
as int,priorityWindowMinutes: null == priorityWindowMinutes ? _self.priorityWindowMinutes : priorityWindowMinutes // ignore: cast_nullable_to_non_nullable
as int,earlyPartnerFreeUntil: freezed == earlyPartnerFreeUntil ? _self.earlyPartnerFreeUntil : earlyPartnerFreeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,maxRequestsPerDay: null == maxRequestsPerDay ? _self.maxRequestsPerDay : maxRequestsPerDay // ignore: cast_nullable_to_non_nullable
as int,webPurchaseLinksAllowed: null == webPurchaseLinksAllowed ? _self.webPurchaseLinksAllowed : webPurchaseLinksAllowed // ignore: cast_nullable_to_non_nullable
as bool,paywallDefaultPeriod: null == paywallDefaultPeriod ? _self.paywallDefaultPeriod : paywallDefaultPeriod // ignore: cast_nullable_to_non_nullable
as String,whatsappNotifications: null == whatsappNotifications ? _self.whatsappNotifications : whatsappNotifications // ignore: cast_nullable_to_non_nullable
as bool,termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
