// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outreach_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OutreachLead {

 String get id; String get businessKey; String get businessName; List<String> get categoriesSource; List<int> get matchedCategoryIds; String? get email; String? get emailDomain; EmailStatus get emailStatus; String? get addressSource; String? get phone; String? get website; String? get websiteDomain; String? get placeId; String? get osmId; String? get address; String? get city; String? get state; String? get postalCode; String? get timezone; double? get rating; int? get ratingCount; LeadSource get source; String? get sourceRef; LawfulBasis get lawfulBasis; String? get chosenReason; LeadStage get stage; String? get ownerId; String? get nextAction; DateTime? get nextActionDue; String? get notes; int? get priority; String? get campaignId; SequenceStatus get sequenceStatus; int get touchesSent; DateTime? get contactedAt; DateTime? get lastContactedAt; DateTime? get remindAfter; DateTime? get whatsappOptInAt; String? get whatsappOptInChannel; String? get whatsappOptInProof; DateTime? get whatsappLastMarketingAt; String? get signupToken; String? get unsubscribeToken; String? get sellerId; DateTime? get createdAt;
/// Create a copy of OutreachLead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutreachLeadCopyWith<OutreachLead> get copyWith => _$OutreachLeadCopyWithImpl<OutreachLead>(this as OutreachLead, _$identity);

  /// Serializes this OutreachLead to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutreachLead;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutreachLead&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.businessKey, _this.businessKey) || other.businessKey == _this.businessKey)&&(identical(other.businessName, _this.businessName) || other.businessName == _this.businessName)&&const DeepCollectionEquality().equals(other.categoriesSource, _this.categoriesSource)&&const DeepCollectionEquality().equals(other.matchedCategoryIds, _this.matchedCategoryIds)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.emailDomain, _this.emailDomain) || other.emailDomain == _this.emailDomain)&&(identical(other.emailStatus, _this.emailStatus) || other.emailStatus == _this.emailStatus)&&(identical(other.addressSource, _this.addressSource) || other.addressSource == _this.addressSource)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.website, _this.website) || other.website == _this.website)&&(identical(other.websiteDomain, _this.websiteDomain) || other.websiteDomain == _this.websiteDomain)&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.osmId, _this.osmId) || other.osmId == _this.osmId)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.postalCode, _this.postalCode) || other.postalCode == _this.postalCode)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.sourceRef, _this.sourceRef) || other.sourceRef == _this.sourceRef)&&(identical(other.lawfulBasis, _this.lawfulBasis) || other.lawfulBasis == _this.lawfulBasis)&&(identical(other.chosenReason, _this.chosenReason) || other.chosenReason == _this.chosenReason)&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.nextAction, _this.nextAction) || other.nextAction == _this.nextAction)&&(identical(other.nextActionDue, _this.nextActionDue) || other.nextActionDue == _this.nextActionDue)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.campaignId, _this.campaignId) || other.campaignId == _this.campaignId)&&(identical(other.sequenceStatus, _this.sequenceStatus) || other.sequenceStatus == _this.sequenceStatus)&&(identical(other.touchesSent, _this.touchesSent) || other.touchesSent == _this.touchesSent)&&(identical(other.contactedAt, _this.contactedAt) || other.contactedAt == _this.contactedAt)&&(identical(other.lastContactedAt, _this.lastContactedAt) || other.lastContactedAt == _this.lastContactedAt)&&(identical(other.remindAfter, _this.remindAfter) || other.remindAfter == _this.remindAfter)&&(identical(other.whatsappOptInAt, _this.whatsappOptInAt) || other.whatsappOptInAt == _this.whatsappOptInAt)&&(identical(other.whatsappOptInChannel, _this.whatsappOptInChannel) || other.whatsappOptInChannel == _this.whatsappOptInChannel)&&(identical(other.whatsappOptInProof, _this.whatsappOptInProof) || other.whatsappOptInProof == _this.whatsappOptInProof)&&(identical(other.whatsappLastMarketingAt, _this.whatsappLastMarketingAt) || other.whatsappLastMarketingAt == _this.whatsappLastMarketingAt)&&(identical(other.signupToken, _this.signupToken) || other.signupToken == _this.signupToken)&&(identical(other.unsubscribeToken, _this.unsubscribeToken) || other.unsubscribeToken == _this.unsubscribeToken)&&(identical(other.sellerId, _this.sellerId) || other.sellerId == _this.sellerId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutreachLead;
  return Object.hashAll([runtimeType,_this.id,_this.businessKey,_this.businessName,const DeepCollectionEquality().hash(_this.categoriesSource),const DeepCollectionEquality().hash(_this.matchedCategoryIds),_this.email,_this.emailDomain,_this.emailStatus,_this.addressSource,_this.phone,_this.website,_this.websiteDomain,_this.placeId,_this.osmId,_this.address,_this.city,_this.state,_this.postalCode,_this.timezone,_this.rating,_this.ratingCount,_this.source,_this.sourceRef,_this.lawfulBasis,_this.chosenReason,_this.stage,_this.ownerId,_this.nextAction,_this.nextActionDue,_this.notes,_this.priority,_this.campaignId,_this.sequenceStatus,_this.touchesSent,_this.contactedAt,_this.lastContactedAt,_this.remindAfter,_this.whatsappOptInAt,_this.whatsappOptInChannel,_this.whatsappOptInProof,_this.whatsappLastMarketingAt,_this.signupToken,_this.unsubscribeToken,_this.sellerId,_this.createdAt]);
}

@override
String toString() {
  final _this = this as OutreachLead;
  return 'OutreachLead(id: ${_this.id}, businessKey: ${_this.businessKey}, businessName: ${_this.businessName}, categoriesSource: ${_this.categoriesSource}, matchedCategoryIds: ${_this.matchedCategoryIds}, email: ${_this.email}, emailDomain: ${_this.emailDomain}, emailStatus: ${_this.emailStatus}, addressSource: ${_this.addressSource}, phone: ${_this.phone}, website: ${_this.website}, websiteDomain: ${_this.websiteDomain}, placeId: ${_this.placeId}, osmId: ${_this.osmId}, address: ${_this.address}, city: ${_this.city}, state: ${_this.state}, postalCode: ${_this.postalCode}, timezone: ${_this.timezone}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, source: ${_this.source}, sourceRef: ${_this.sourceRef}, lawfulBasis: ${_this.lawfulBasis}, chosenReason: ${_this.chosenReason}, stage: ${_this.stage}, ownerId: ${_this.ownerId}, nextAction: ${_this.nextAction}, nextActionDue: ${_this.nextActionDue}, notes: ${_this.notes}, priority: ${_this.priority}, campaignId: ${_this.campaignId}, sequenceStatus: ${_this.sequenceStatus}, touchesSent: ${_this.touchesSent}, contactedAt: ${_this.contactedAt}, lastContactedAt: ${_this.lastContactedAt}, remindAfter: ${_this.remindAfter}, whatsappOptInAt: ${_this.whatsappOptInAt}, whatsappOptInChannel: ${_this.whatsappOptInChannel}, whatsappOptInProof: ${_this.whatsappOptInProof}, whatsappLastMarketingAt: ${_this.whatsappLastMarketingAt}, signupToken: ${_this.signupToken}, unsubscribeToken: ${_this.unsubscribeToken}, sellerId: ${_this.sellerId}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $OutreachLeadCopyWith<$Res>  {
  factory $OutreachLeadCopyWith(OutreachLead value, $Res Function(OutreachLead) _then) = _$OutreachLeadCopyWithImpl;
@useResult
$Res call({
 String id, String businessKey, String businessName, List<String> categoriesSource, List<int> matchedCategoryIds, String? email, String? emailDomain, EmailStatus emailStatus, String? addressSource, String? phone, String? website, String? websiteDomain, String? placeId, String? osmId, String? address, String? city, String? state, String? postalCode, String? timezone, double? rating, int? ratingCount, LeadSource source, String? sourceRef, LawfulBasis lawfulBasis, String? chosenReason, LeadStage stage, String? ownerId, String? nextAction, DateTime? nextActionDue, String? notes, int? priority, String? campaignId, SequenceStatus sequenceStatus, int touchesSent, DateTime? contactedAt, DateTime? lastContactedAt, DateTime? remindAfter, DateTime? whatsappOptInAt, String? whatsappOptInChannel, String? whatsappOptInProof, DateTime? whatsappLastMarketingAt, String? signupToken, String? unsubscribeToken, String? sellerId, DateTime? createdAt
});




}
/// @nodoc
class _$OutreachLeadCopyWithImpl<$Res>
    implements $OutreachLeadCopyWith<$Res> {
  _$OutreachLeadCopyWithImpl(this._self, this._then);

  final OutreachLead _self;
  final $Res Function(OutreachLead) _then;

/// Create a copy of OutreachLead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? businessKey = null,Object? businessName = null,Object? categoriesSource = null,Object? matchedCategoryIds = null,Object? email = freezed,Object? emailDomain = freezed,Object? emailStatus = null,Object? addressSource = freezed,Object? phone = freezed,Object? website = freezed,Object? websiteDomain = freezed,Object? placeId = freezed,Object? osmId = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? postalCode = freezed,Object? timezone = freezed,Object? rating = freezed,Object? ratingCount = freezed,Object? source = null,Object? sourceRef = freezed,Object? lawfulBasis = null,Object? chosenReason = freezed,Object? stage = null,Object? ownerId = freezed,Object? nextAction = freezed,Object? nextActionDue = freezed,Object? notes = freezed,Object? priority = freezed,Object? campaignId = freezed,Object? sequenceStatus = null,Object? touchesSent = null,Object? contactedAt = freezed,Object? lastContactedAt = freezed,Object? remindAfter = freezed,Object? whatsappOptInAt = freezed,Object? whatsappOptInChannel = freezed,Object? whatsappOptInProof = freezed,Object? whatsappLastMarketingAt = freezed,Object? signupToken = freezed,Object? unsubscribeToken = freezed,Object? sellerId = freezed,Object? createdAt = freezed,}) {
  return _then(OutreachLead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessKey: null == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,categoriesSource: null == categoriesSource ? _self.categoriesSource : categoriesSource // ignore: cast_nullable_to_non_nullable
as List<String>,matchedCategoryIds: null == matchedCategoryIds ? _self.matchedCategoryIds : matchedCategoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailDomain: freezed == emailDomain ? _self.emailDomain : emailDomain // ignore: cast_nullable_to_non_nullable
as String?,emailStatus: null == emailStatus ? _self.emailStatus : emailStatus // ignore: cast_nullable_to_non_nullable
as EmailStatus,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,websiteDomain: freezed == websiteDomain ? _self.websiteDomain : websiteDomain // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,osmId: freezed == osmId ? _self.osmId : osmId // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: null == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as LawfulBasis,chosenReason: freezed == chosenReason ? _self.chosenReason : chosenReason // ignore: cast_nullable_to_non_nullable
as String?,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as LeadStage,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as String?,nextActionDue: freezed == nextActionDue ? _self.nextActionDue : nextActionDue // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,sequenceStatus: null == sequenceStatus ? _self.sequenceStatus : sequenceStatus // ignore: cast_nullable_to_non_nullable
as SequenceStatus,touchesSent: null == touchesSent ? _self.touchesSent : touchesSent // ignore: cast_nullable_to_non_nullable
as int,contactedAt: freezed == contactedAt ? _self.contactedAt : contactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastContactedAt: freezed == lastContactedAt ? _self.lastContactedAt : lastContactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,remindAfter: freezed == remindAfter ? _self.remindAfter : remindAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,whatsappOptInAt: freezed == whatsappOptInAt ? _self.whatsappOptInAt : whatsappOptInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,whatsappOptInChannel: freezed == whatsappOptInChannel ? _self.whatsappOptInChannel : whatsappOptInChannel // ignore: cast_nullable_to_non_nullable
as String?,whatsappOptInProof: freezed == whatsappOptInProof ? _self.whatsappOptInProof : whatsappOptInProof // ignore: cast_nullable_to_non_nullable
as String?,whatsappLastMarketingAt: freezed == whatsappLastMarketingAt ? _self.whatsappLastMarketingAt : whatsappLastMarketingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,signupToken: freezed == signupToken ? _self.signupToken : signupToken // ignore: cast_nullable_to_non_nullable
as String?,unsubscribeToken: freezed == unsubscribeToken ? _self.unsubscribeToken : unsubscribeToken // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutreachLead].
extension OutreachLeadPatterns on OutreachLead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutreachLead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutreachLead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutreachLead value)  $default,){
final _that = this;
switch (_that) {
case _OutreachLead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutreachLead value)?  $default,){
final _that = this;
switch (_that) {
case _OutreachLead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? emailDomain,  EmailStatus emailStatus,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  LeadStage stage,  String? ownerId,  String? nextAction,  DateTime? nextActionDue,  String? notes,  int? priority,  String? campaignId,  SequenceStatus sequenceStatus,  int touchesSent,  DateTime? contactedAt,  DateTime? lastContactedAt,  DateTime? remindAfter,  DateTime? whatsappOptInAt,  String? whatsappOptInChannel,  String? whatsappOptInProof,  DateTime? whatsappLastMarketingAt,  String? signupToken,  String? unsubscribeToken,  String? sellerId,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutreachLead() when $default != null:
return $default(_that.id,_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.emailDomain,_that.emailStatus,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.stage,_that.ownerId,_that.nextAction,_that.nextActionDue,_that.notes,_that.priority,_that.campaignId,_that.sequenceStatus,_that.touchesSent,_that.contactedAt,_that.lastContactedAt,_that.remindAfter,_that.whatsappOptInAt,_that.whatsappOptInChannel,_that.whatsappOptInProof,_that.whatsappLastMarketingAt,_that.signupToken,_that.unsubscribeToken,_that.sellerId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? emailDomain,  EmailStatus emailStatus,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  LeadStage stage,  String? ownerId,  String? nextAction,  DateTime? nextActionDue,  String? notes,  int? priority,  String? campaignId,  SequenceStatus sequenceStatus,  int touchesSent,  DateTime? contactedAt,  DateTime? lastContactedAt,  DateTime? remindAfter,  DateTime? whatsappOptInAt,  String? whatsappOptInChannel,  String? whatsappOptInProof,  DateTime? whatsappLastMarketingAt,  String? signupToken,  String? unsubscribeToken,  String? sellerId,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OutreachLead():
return $default(_that.id,_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.emailDomain,_that.emailStatus,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.stage,_that.ownerId,_that.nextAction,_that.nextActionDue,_that.notes,_that.priority,_that.campaignId,_that.sequenceStatus,_that.touchesSent,_that.contactedAt,_that.lastContactedAt,_that.remindAfter,_that.whatsappOptInAt,_that.whatsappOptInChannel,_that.whatsappOptInProof,_that.whatsappLastMarketingAt,_that.signupToken,_that.unsubscribeToken,_that.sellerId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? emailDomain,  EmailStatus emailStatus,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  LeadStage stage,  String? ownerId,  String? nextAction,  DateTime? nextActionDue,  String? notes,  int? priority,  String? campaignId,  SequenceStatus sequenceStatus,  int touchesSent,  DateTime? contactedAt,  DateTime? lastContactedAt,  DateTime? remindAfter,  DateTime? whatsappOptInAt,  String? whatsappOptInChannel,  String? whatsappOptInProof,  DateTime? whatsappLastMarketingAt,  String? signupToken,  String? unsubscribeToken,  String? sellerId,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OutreachLead() when $default != null:
return $default(_that.id,_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.emailDomain,_that.emailStatus,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.stage,_that.ownerId,_that.nextAction,_that.nextActionDue,_that.notes,_that.priority,_that.campaignId,_that.sequenceStatus,_that.touchesSent,_that.contactedAt,_that.lastContactedAt,_that.remindAfter,_that.whatsappOptInAt,_that.whatsappOptInChannel,_that.whatsappOptInProof,_that.whatsappLastMarketingAt,_that.signupToken,_that.unsubscribeToken,_that.sellerId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutreachLead extends OutreachLead {
  const _OutreachLead({required this.id, required this.businessKey, required this.businessName,  List<String> categoriesSource = const <String>[],  List<int> matchedCategoryIds = const <int>[], this.email, this.emailDomain, this.emailStatus = EmailStatus.unverified, this.addressSource, this.phone, this.website, this.websiteDomain, this.placeId, this.osmId, this.address, this.city, this.state, this.postalCode, this.timezone, this.rating, this.ratingCount, required this.source, this.sourceRef, required this.lawfulBasis, this.chosenReason, this.stage = LeadStage.sourced, this.ownerId, this.nextAction, this.nextActionDue, this.notes, this.priority, this.campaignId, this.sequenceStatus = SequenceStatus.none, this.touchesSent = 0, this.contactedAt, this.lastContactedAt, this.remindAfter, this.whatsappOptInAt, this.whatsappOptInChannel, this.whatsappOptInProof, this.whatsappLastMarketingAt, this.signupToken, this.unsubscribeToken, this.sellerId, this.createdAt}): _categoriesSource = categoriesSource,_matchedCategoryIds = matchedCategoryIds,super._();
  factory _OutreachLead.fromJson(Map<String, dynamic> json) => _$OutreachLeadFromJson(json);

@override final  String id;
@override final  String businessKey;
@override final  String businessName;
 final  List<String> _categoriesSource;
@override@JsonKey() List<String> get categoriesSource {
  if (_categoriesSource is EqualUnmodifiableListView) return _categoriesSource;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoriesSource);
}

 final  List<int> _matchedCategoryIds;
@override@JsonKey() List<int> get matchedCategoryIds {
  if (_matchedCategoryIds is EqualUnmodifiableListView) return _matchedCategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matchedCategoryIds);
}

@override final  String? email;
@override final  String? emailDomain;
@override@JsonKey() final  EmailStatus emailStatus;
@override final  String? addressSource;
@override final  String? phone;
@override final  String? website;
@override final  String? websiteDomain;
@override final  String? placeId;
@override final  String? osmId;
@override final  String? address;
@override final  String? city;
@override final  String? state;
@override final  String? postalCode;
@override final  String? timezone;
@override final  double? rating;
@override final  int? ratingCount;
@override final  LeadSource source;
@override final  String? sourceRef;
@override final  LawfulBasis lawfulBasis;
@override final  String? chosenReason;
@override@JsonKey() final  LeadStage stage;
@override final  String? ownerId;
@override final  String? nextAction;
@override final  DateTime? nextActionDue;
@override final  String? notes;
@override final  int? priority;
@override final  String? campaignId;
@override@JsonKey() final  SequenceStatus sequenceStatus;
@override@JsonKey() final  int touchesSent;
@override final  DateTime? contactedAt;
@override final  DateTime? lastContactedAt;
@override final  DateTime? remindAfter;
@override final  DateTime? whatsappOptInAt;
@override final  String? whatsappOptInChannel;
@override final  String? whatsappOptInProof;
@override final  DateTime? whatsappLastMarketingAt;
@override final  String? signupToken;
@override final  String? unsubscribeToken;
@override final  String? sellerId;
@override final  DateTime? createdAt;

/// Create a copy of OutreachLead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutreachLeadCopyWith<_OutreachLead> get copyWith => __$OutreachLeadCopyWithImpl<_OutreachLead>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutreachLeadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutreachLead&&(identical(other.id, id) || other.id == id)&&(identical(other.businessKey, businessKey) || other.businessKey == businessKey)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&const DeepCollectionEquality().equals(other.categoriesSource, _categoriesSource)&&const DeepCollectionEquality().equals(other.matchedCategoryIds, _matchedCategoryIds)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailDomain, emailDomain) || other.emailDomain == emailDomain)&&(identical(other.emailStatus, emailStatus) || other.emailStatus == emailStatus)&&(identical(other.addressSource, addressSource) || other.addressSource == addressSource)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&(identical(other.websiteDomain, websiteDomain) || other.websiteDomain == websiteDomain)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.osmId, osmId) || other.osmId == osmId)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceRef, sourceRef) || other.sourceRef == sourceRef)&&(identical(other.lawfulBasis, lawfulBasis) || other.lawfulBasis == lawfulBasis)&&(identical(other.chosenReason, chosenReason) || other.chosenReason == chosenReason)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.nextActionDue, nextActionDue) || other.nextActionDue == nextActionDue)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.sequenceStatus, sequenceStatus) || other.sequenceStatus == sequenceStatus)&&(identical(other.touchesSent, touchesSent) || other.touchesSent == touchesSent)&&(identical(other.contactedAt, contactedAt) || other.contactedAt == contactedAt)&&(identical(other.lastContactedAt, lastContactedAt) || other.lastContactedAt == lastContactedAt)&&(identical(other.remindAfter, remindAfter) || other.remindAfter == remindAfter)&&(identical(other.whatsappOptInAt, whatsappOptInAt) || other.whatsappOptInAt == whatsappOptInAt)&&(identical(other.whatsappOptInChannel, whatsappOptInChannel) || other.whatsappOptInChannel == whatsappOptInChannel)&&(identical(other.whatsappOptInProof, whatsappOptInProof) || other.whatsappOptInProof == whatsappOptInProof)&&(identical(other.whatsappLastMarketingAt, whatsappLastMarketingAt) || other.whatsappLastMarketingAt == whatsappLastMarketingAt)&&(identical(other.signupToken, signupToken) || other.signupToken == signupToken)&&(identical(other.unsubscribeToken, unsubscribeToken) || other.unsubscribeToken == unsubscribeToken)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,businessKey,businessName,const DeepCollectionEquality().hash(_categoriesSource),const DeepCollectionEquality().hash(_matchedCategoryIds),email,emailDomain,emailStatus,addressSource,phone,website,websiteDomain,placeId,osmId,address,city,state,postalCode,timezone,rating,ratingCount,source,sourceRef,lawfulBasis,chosenReason,stage,ownerId,nextAction,nextActionDue,notes,priority,campaignId,sequenceStatus,touchesSent,contactedAt,lastContactedAt,remindAfter,whatsappOptInAt,whatsappOptInChannel,whatsappOptInProof,whatsappLastMarketingAt,signupToken,unsubscribeToken,sellerId,createdAt]);
}

@override
String toString() {
    return 'OutreachLead(id: $id, businessKey: $businessKey, businessName: $businessName, categoriesSource: $categoriesSource, matchedCategoryIds: $matchedCategoryIds, email: $email, emailDomain: $emailDomain, emailStatus: $emailStatus, addressSource: $addressSource, phone: $phone, website: $website, websiteDomain: $websiteDomain, placeId: $placeId, osmId: $osmId, address: $address, city: $city, state: $state, postalCode: $postalCode, timezone: $timezone, rating: $rating, ratingCount: $ratingCount, source: $source, sourceRef: $sourceRef, lawfulBasis: $lawfulBasis, chosenReason: $chosenReason, stage: $stage, ownerId: $ownerId, nextAction: $nextAction, nextActionDue: $nextActionDue, notes: $notes, priority: $priority, campaignId: $campaignId, sequenceStatus: $sequenceStatus, touchesSent: $touchesSent, contactedAt: $contactedAt, lastContactedAt: $lastContactedAt, remindAfter: $remindAfter, whatsappOptInAt: $whatsappOptInAt, whatsappOptInChannel: $whatsappOptInChannel, whatsappOptInProof: $whatsappOptInProof, whatsappLastMarketingAt: $whatsappLastMarketingAt, signupToken: $signupToken, unsubscribeToken: $unsubscribeToken, sellerId: $sellerId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OutreachLeadCopyWith<$Res> implements $OutreachLeadCopyWith<$Res> {
  factory _$OutreachLeadCopyWith(_OutreachLead value, $Res Function(_OutreachLead) _then) = __$OutreachLeadCopyWithImpl;
@override @useResult
$Res call({
 String id, String businessKey, String businessName, List<String> categoriesSource, List<int> matchedCategoryIds, String? email, String? emailDomain, EmailStatus emailStatus, String? addressSource, String? phone, String? website, String? websiteDomain, String? placeId, String? osmId, String? address, String? city, String? state, String? postalCode, String? timezone, double? rating, int? ratingCount, LeadSource source, String? sourceRef, LawfulBasis lawfulBasis, String? chosenReason, LeadStage stage, String? ownerId, String? nextAction, DateTime? nextActionDue, String? notes, int? priority, String? campaignId, SequenceStatus sequenceStatus, int touchesSent, DateTime? contactedAt, DateTime? lastContactedAt, DateTime? remindAfter, DateTime? whatsappOptInAt, String? whatsappOptInChannel, String? whatsappOptInProof, DateTime? whatsappLastMarketingAt, String? signupToken, String? unsubscribeToken, String? sellerId, DateTime? createdAt
});




}
/// @nodoc
class __$OutreachLeadCopyWithImpl<$Res>
    implements _$OutreachLeadCopyWith<$Res> {
  __$OutreachLeadCopyWithImpl(this._self, this._then);

  final _OutreachLead _self;
  final $Res Function(_OutreachLead) _then;

/// Create a copy of OutreachLead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? businessKey = null,Object? businessName = null,Object? categoriesSource = null,Object? matchedCategoryIds = null,Object? email = freezed,Object? emailDomain = freezed,Object? emailStatus = null,Object? addressSource = freezed,Object? phone = freezed,Object? website = freezed,Object? websiteDomain = freezed,Object? placeId = freezed,Object? osmId = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? postalCode = freezed,Object? timezone = freezed,Object? rating = freezed,Object? ratingCount = freezed,Object? source = null,Object? sourceRef = freezed,Object? lawfulBasis = null,Object? chosenReason = freezed,Object? stage = null,Object? ownerId = freezed,Object? nextAction = freezed,Object? nextActionDue = freezed,Object? notes = freezed,Object? priority = freezed,Object? campaignId = freezed,Object? sequenceStatus = null,Object? touchesSent = null,Object? contactedAt = freezed,Object? lastContactedAt = freezed,Object? remindAfter = freezed,Object? whatsappOptInAt = freezed,Object? whatsappOptInChannel = freezed,Object? whatsappOptInProof = freezed,Object? whatsappLastMarketingAt = freezed,Object? signupToken = freezed,Object? unsubscribeToken = freezed,Object? sellerId = freezed,Object? createdAt = freezed,}) {
  return _then(_OutreachLead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,businessKey: null == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,categoriesSource: null == categoriesSource ? _self._categoriesSource : categoriesSource // ignore: cast_nullable_to_non_nullable
as List<String>,matchedCategoryIds: null == matchedCategoryIds ? _self._matchedCategoryIds : matchedCategoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailDomain: freezed == emailDomain ? _self.emailDomain : emailDomain // ignore: cast_nullable_to_non_nullable
as String?,emailStatus: null == emailStatus ? _self.emailStatus : emailStatus // ignore: cast_nullable_to_non_nullable
as EmailStatus,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,websiteDomain: freezed == websiteDomain ? _self.websiteDomain : websiteDomain // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,osmId: freezed == osmId ? _self.osmId : osmId // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: null == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as LawfulBasis,chosenReason: freezed == chosenReason ? _self.chosenReason : chosenReason // ignore: cast_nullable_to_non_nullable
as String?,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as LeadStage,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as String?,nextActionDue: freezed == nextActionDue ? _self.nextActionDue : nextActionDue // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,sequenceStatus: null == sequenceStatus ? _self.sequenceStatus : sequenceStatus // ignore: cast_nullable_to_non_nullable
as SequenceStatus,touchesSent: null == touchesSent ? _self.touchesSent : touchesSent // ignore: cast_nullable_to_non_nullable
as int,contactedAt: freezed == contactedAt ? _self.contactedAt : contactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastContactedAt: freezed == lastContactedAt ? _self.lastContactedAt : lastContactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,remindAfter: freezed == remindAfter ? _self.remindAfter : remindAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,whatsappOptInAt: freezed == whatsappOptInAt ? _self.whatsappOptInAt : whatsappOptInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,whatsappOptInChannel: freezed == whatsappOptInChannel ? _self.whatsappOptInChannel : whatsappOptInChannel // ignore: cast_nullable_to_non_nullable
as String?,whatsappOptInProof: freezed == whatsappOptInProof ? _self.whatsappOptInProof : whatsappOptInProof // ignore: cast_nullable_to_non_nullable
as String?,whatsappLastMarketingAt: freezed == whatsappLastMarketingAt ? _self.whatsappLastMarketingAt : whatsappLastMarketingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,signupToken: freezed == signupToken ? _self.signupToken : signupToken // ignore: cast_nullable_to_non_nullable
as String?,unsubscribeToken: freezed == unsubscribeToken ? _self.unsubscribeToken : unsubscribeToken // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OutreachEvent {

 String get id; String get leadId; String? get campaignId; String? get inboxId; String get channel; String get eventType; int? get sequenceStep; int? get templateVariant; String? get subject; String? get bodyPreview; String? get recipient; String? get reasonChosen; String? get addressSource; String? get lawfulBasis; Map<String, dynamic> get meta; String? get createdBy; DateTime get createdAt;
/// Create a copy of OutreachEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutreachEventCopyWith<OutreachEvent> get copyWith => _$OutreachEventCopyWithImpl<OutreachEvent>(this as OutreachEvent, _$identity);

  /// Serializes this OutreachEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutreachEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutreachEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.leadId, _this.leadId) || other.leadId == _this.leadId)&&(identical(other.campaignId, _this.campaignId) || other.campaignId == _this.campaignId)&&(identical(other.inboxId, _this.inboxId) || other.inboxId == _this.inboxId)&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&(identical(other.eventType, _this.eventType) || other.eventType == _this.eventType)&&(identical(other.sequenceStep, _this.sequenceStep) || other.sequenceStep == _this.sequenceStep)&&(identical(other.templateVariant, _this.templateVariant) || other.templateVariant == _this.templateVariant)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.bodyPreview, _this.bodyPreview) || other.bodyPreview == _this.bodyPreview)&&(identical(other.recipient, _this.recipient) || other.recipient == _this.recipient)&&(identical(other.reasonChosen, _this.reasonChosen) || other.reasonChosen == _this.reasonChosen)&&(identical(other.addressSource, _this.addressSource) || other.addressSource == _this.addressSource)&&(identical(other.lawfulBasis, _this.lawfulBasis) || other.lawfulBasis == _this.lawfulBasis)&&const DeepCollectionEquality().equals(other.meta, _this.meta)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutreachEvent;
  return Object.hash(runtimeType,_this.id,_this.leadId,_this.campaignId,_this.inboxId,_this.channel,_this.eventType,_this.sequenceStep,_this.templateVariant,_this.subject,_this.bodyPreview,_this.recipient,_this.reasonChosen,_this.addressSource,_this.lawfulBasis,const DeepCollectionEquality().hash(_this.meta),_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as OutreachEvent;
  return 'OutreachEvent(id: ${_this.id}, leadId: ${_this.leadId}, campaignId: ${_this.campaignId}, inboxId: ${_this.inboxId}, channel: ${_this.channel}, eventType: ${_this.eventType}, sequenceStep: ${_this.sequenceStep}, templateVariant: ${_this.templateVariant}, subject: ${_this.subject}, bodyPreview: ${_this.bodyPreview}, recipient: ${_this.recipient}, reasonChosen: ${_this.reasonChosen}, addressSource: ${_this.addressSource}, lawfulBasis: ${_this.lawfulBasis}, meta: ${_this.meta}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $OutreachEventCopyWith<$Res>  {
  factory $OutreachEventCopyWith(OutreachEvent value, $Res Function(OutreachEvent) _then) = _$OutreachEventCopyWithImpl;
@useResult
$Res call({
 String id, String leadId, String? campaignId, String? inboxId, String channel, String eventType, int? sequenceStep, int? templateVariant, String? subject, String? bodyPreview, String? recipient, String? reasonChosen, String? addressSource, String? lawfulBasis, Map<String, dynamic> meta, String? createdBy, DateTime createdAt
});




}
/// @nodoc
class _$OutreachEventCopyWithImpl<$Res>
    implements $OutreachEventCopyWith<$Res> {
  _$OutreachEventCopyWithImpl(this._self, this._then);

  final OutreachEvent _self;
  final $Res Function(OutreachEvent) _then;

/// Create a copy of OutreachEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? leadId = null,Object? campaignId = freezed,Object? inboxId = freezed,Object? channel = null,Object? eventType = null,Object? sequenceStep = freezed,Object? templateVariant = freezed,Object? subject = freezed,Object? bodyPreview = freezed,Object? recipient = freezed,Object? reasonChosen = freezed,Object? addressSource = freezed,Object? lawfulBasis = freezed,Object? meta = null,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(OutreachEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leadId: null == leadId ? _self.leadId : leadId // ignore: cast_nullable_to_non_nullable
as String,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,inboxId: freezed == inboxId ? _self.inboxId : inboxId // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,sequenceStep: freezed == sequenceStep ? _self.sequenceStep : sequenceStep // ignore: cast_nullable_to_non_nullable
as int?,templateVariant: freezed == templateVariant ? _self.templateVariant : templateVariant // ignore: cast_nullable_to_non_nullable
as int?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,bodyPreview: freezed == bodyPreview ? _self.bodyPreview : bodyPreview // ignore: cast_nullable_to_non_nullable
as String?,recipient: freezed == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as String?,reasonChosen: freezed == reasonChosen ? _self.reasonChosen : reasonChosen // ignore: cast_nullable_to_non_nullable
as String?,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: freezed == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as String?,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OutreachEvent].
extension OutreachEventPatterns on OutreachEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutreachEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutreachEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutreachEvent value)  $default,){
final _that = this;
switch (_that) {
case _OutreachEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutreachEvent value)?  $default,){
final _that = this;
switch (_that) {
case _OutreachEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String leadId,  String? campaignId,  String? inboxId,  String channel,  String eventType,  int? sequenceStep,  int? templateVariant,  String? subject,  String? bodyPreview,  String? recipient,  String? reasonChosen,  String? addressSource,  String? lawfulBasis,  Map<String, dynamic> meta,  String? createdBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutreachEvent() when $default != null:
return $default(_that.id,_that.leadId,_that.campaignId,_that.inboxId,_that.channel,_that.eventType,_that.sequenceStep,_that.templateVariant,_that.subject,_that.bodyPreview,_that.recipient,_that.reasonChosen,_that.addressSource,_that.lawfulBasis,_that.meta,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String leadId,  String? campaignId,  String? inboxId,  String channel,  String eventType,  int? sequenceStep,  int? templateVariant,  String? subject,  String? bodyPreview,  String? recipient,  String? reasonChosen,  String? addressSource,  String? lawfulBasis,  Map<String, dynamic> meta,  String? createdBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _OutreachEvent():
return $default(_that.id,_that.leadId,_that.campaignId,_that.inboxId,_that.channel,_that.eventType,_that.sequenceStep,_that.templateVariant,_that.subject,_that.bodyPreview,_that.recipient,_that.reasonChosen,_that.addressSource,_that.lawfulBasis,_that.meta,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String leadId,  String? campaignId,  String? inboxId,  String channel,  String eventType,  int? sequenceStep,  int? templateVariant,  String? subject,  String? bodyPreview,  String? recipient,  String? reasonChosen,  String? addressSource,  String? lawfulBasis,  Map<String, dynamic> meta,  String? createdBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OutreachEvent() when $default != null:
return $default(_that.id,_that.leadId,_that.campaignId,_that.inboxId,_that.channel,_that.eventType,_that.sequenceStep,_that.templateVariant,_that.subject,_that.bodyPreview,_that.recipient,_that.reasonChosen,_that.addressSource,_that.lawfulBasis,_that.meta,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutreachEvent implements OutreachEvent {
  const _OutreachEvent({required this.id, required this.leadId, this.campaignId, this.inboxId, required this.channel, required this.eventType, this.sequenceStep, this.templateVariant, this.subject, this.bodyPreview, this.recipient, this.reasonChosen, this.addressSource, this.lawfulBasis,  Map<String, dynamic> meta = const <String, dynamic>{}, this.createdBy, required this.createdAt}): _meta = meta;
  factory _OutreachEvent.fromJson(Map<String, dynamic> json) => _$OutreachEventFromJson(json);

@override final  String id;
@override final  String leadId;
@override final  String? campaignId;
@override final  String? inboxId;
@override final  String channel;
@override final  String eventType;
@override final  int? sequenceStep;
@override final  int? templateVariant;
@override final  String? subject;
@override final  String? bodyPreview;
@override final  String? recipient;
@override final  String? reasonChosen;
@override final  String? addressSource;
@override final  String? lawfulBasis;
 final  Map<String, dynamic> _meta;
@override@JsonKey() Map<String, dynamic> get meta {
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_meta);
}

@override final  String? createdBy;
@override final  DateTime createdAt;

/// Create a copy of OutreachEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutreachEventCopyWith<_OutreachEvent> get copyWith => __$OutreachEventCopyWithImpl<_OutreachEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutreachEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutreachEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.leadId, leadId) || other.leadId == leadId)&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.inboxId, inboxId) || other.inboxId == inboxId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.sequenceStep, sequenceStep) || other.sequenceStep == sequenceStep)&&(identical(other.templateVariant, templateVariant) || other.templateVariant == templateVariant)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.bodyPreview, bodyPreview) || other.bodyPreview == bodyPreview)&&(identical(other.recipient, recipient) || other.recipient == recipient)&&(identical(other.reasonChosen, reasonChosen) || other.reasonChosen == reasonChosen)&&(identical(other.addressSource, addressSource) || other.addressSource == addressSource)&&(identical(other.lawfulBasis, lawfulBasis) || other.lawfulBasis == lawfulBasis)&&const DeepCollectionEquality().equals(other.meta, _meta)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,leadId,campaignId,inboxId,channel,eventType,sequenceStep,templateVariant,subject,bodyPreview,recipient,reasonChosen,addressSource,lawfulBasis,const DeepCollectionEquality().hash(_meta),createdBy,createdAt);
}

@override
String toString() {
    return 'OutreachEvent(id: $id, leadId: $leadId, campaignId: $campaignId, inboxId: $inboxId, channel: $channel, eventType: $eventType, sequenceStep: $sequenceStep, templateVariant: $templateVariant, subject: $subject, bodyPreview: $bodyPreview, recipient: $recipient, reasonChosen: $reasonChosen, addressSource: $addressSource, lawfulBasis: $lawfulBasis, meta: $meta, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OutreachEventCopyWith<$Res> implements $OutreachEventCopyWith<$Res> {
  factory _$OutreachEventCopyWith(_OutreachEvent value, $Res Function(_OutreachEvent) _then) = __$OutreachEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String leadId, String? campaignId, String? inboxId, String channel, String eventType, int? sequenceStep, int? templateVariant, String? subject, String? bodyPreview, String? recipient, String? reasonChosen, String? addressSource, String? lawfulBasis, Map<String, dynamic> meta, String? createdBy, DateTime createdAt
});




}
/// @nodoc
class __$OutreachEventCopyWithImpl<$Res>
    implements _$OutreachEventCopyWith<$Res> {
  __$OutreachEventCopyWithImpl(this._self, this._then);

  final _OutreachEvent _self;
  final $Res Function(_OutreachEvent) _then;

/// Create a copy of OutreachEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? leadId = null,Object? campaignId = freezed,Object? inboxId = freezed,Object? channel = null,Object? eventType = null,Object? sequenceStep = freezed,Object? templateVariant = freezed,Object? subject = freezed,Object? bodyPreview = freezed,Object? recipient = freezed,Object? reasonChosen = freezed,Object? addressSource = freezed,Object? lawfulBasis = freezed,Object? meta = null,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(_OutreachEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leadId: null == leadId ? _self.leadId : leadId // ignore: cast_nullable_to_non_nullable
as String,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,inboxId: freezed == inboxId ? _self.inboxId : inboxId // ignore: cast_nullable_to_non_nullable
as String?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,sequenceStep: freezed == sequenceStep ? _self.sequenceStep : sequenceStep // ignore: cast_nullable_to_non_nullable
as int?,templateVariant: freezed == templateVariant ? _self.templateVariant : templateVariant // ignore: cast_nullable_to_non_nullable
as int?,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,bodyPreview: freezed == bodyPreview ? _self.bodyPreview : bodyPreview // ignore: cast_nullable_to_non_nullable
as String?,recipient: freezed == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as String?,reasonChosen: freezed == reasonChosen ? _self.reasonChosen : reasonChosen // ignore: cast_nullable_to_non_nullable
as String?,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: freezed == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as String?,meta: null == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SuppressionEntry {

 String get id; String? get email; String? get emailDomain; String? get phone; String? get businessKey; String get reason; String? get source; String? get note; DateTime? get createdAt;
/// Create a copy of SuppressionEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuppressionEntryCopyWith<SuppressionEntry> get copyWith => _$SuppressionEntryCopyWithImpl<SuppressionEntry>(this as SuppressionEntry, _$identity);

  /// Serializes this SuppressionEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SuppressionEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuppressionEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.emailDomain, _this.emailDomain) || other.emailDomain == _this.emailDomain)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.businessKey, _this.businessKey) || other.businessKey == _this.businessKey)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SuppressionEntry;
  return Object.hash(runtimeType,_this.id,_this.email,_this.emailDomain,_this.phone,_this.businessKey,_this.reason,_this.source,_this.note,_this.createdAt);
}

@override
String toString() {
  final _this = this as SuppressionEntry;
  return 'SuppressionEntry(id: ${_this.id}, email: ${_this.email}, emailDomain: ${_this.emailDomain}, phone: ${_this.phone}, businessKey: ${_this.businessKey}, reason: ${_this.reason}, source: ${_this.source}, note: ${_this.note}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $SuppressionEntryCopyWith<$Res>  {
  factory $SuppressionEntryCopyWith(SuppressionEntry value, $Res Function(SuppressionEntry) _then) = _$SuppressionEntryCopyWithImpl;
@useResult
$Res call({
 String id, String? email, String? emailDomain, String? phone, String? businessKey, String reason, String? source, String? note, DateTime? createdAt
});




}
/// @nodoc
class _$SuppressionEntryCopyWithImpl<$Res>
    implements $SuppressionEntryCopyWith<$Res> {
  _$SuppressionEntryCopyWithImpl(this._self, this._then);

  final SuppressionEntry _self;
  final $Res Function(SuppressionEntry) _then;

/// Create a copy of SuppressionEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = freezed,Object? emailDomain = freezed,Object? phone = freezed,Object? businessKey = freezed,Object? reason = null,Object? source = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(SuppressionEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailDomain: freezed == emailDomain ? _self.emailDomain : emailDomain // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,businessKey: freezed == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SuppressionEntry].
extension SuppressionEntryPatterns on SuppressionEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuppressionEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuppressionEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuppressionEntry value)  $default,){
final _that = this;
switch (_that) {
case _SuppressionEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuppressionEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SuppressionEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? email,  String? emailDomain,  String? phone,  String? businessKey,  String reason,  String? source,  String? note,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuppressionEntry() when $default != null:
return $default(_that.id,_that.email,_that.emailDomain,_that.phone,_that.businessKey,_that.reason,_that.source,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? email,  String? emailDomain,  String? phone,  String? businessKey,  String reason,  String? source,  String? note,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SuppressionEntry():
return $default(_that.id,_that.email,_that.emailDomain,_that.phone,_that.businessKey,_that.reason,_that.source,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? email,  String? emailDomain,  String? phone,  String? businessKey,  String reason,  String? source,  String? note,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SuppressionEntry() when $default != null:
return $default(_that.id,_that.email,_that.emailDomain,_that.phone,_that.businessKey,_that.reason,_that.source,_that.note,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SuppressionEntry implements SuppressionEntry {
  const _SuppressionEntry({required this.id, this.email, this.emailDomain, this.phone, this.businessKey, required this.reason, this.source, this.note, this.createdAt});
  factory _SuppressionEntry.fromJson(Map<String, dynamic> json) => _$SuppressionEntryFromJson(json);

@override final  String id;
@override final  String? email;
@override final  String? emailDomain;
@override final  String? phone;
@override final  String? businessKey;
@override final  String reason;
@override final  String? source;
@override final  String? note;
@override final  DateTime? createdAt;

/// Create a copy of SuppressionEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuppressionEntryCopyWith<_SuppressionEntry> get copyWith => __$SuppressionEntryCopyWithImpl<_SuppressionEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuppressionEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuppressionEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailDomain, emailDomain) || other.emailDomain == emailDomain)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.businessKey, businessKey) || other.businessKey == businessKey)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.source, source) || other.source == source)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,email,emailDomain,phone,businessKey,reason,source,note,createdAt);
}

@override
String toString() {
    return 'SuppressionEntry(id: $id, email: $email, emailDomain: $emailDomain, phone: $phone, businessKey: $businessKey, reason: $reason, source: $source, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SuppressionEntryCopyWith<$Res> implements $SuppressionEntryCopyWith<$Res> {
  factory _$SuppressionEntryCopyWith(_SuppressionEntry value, $Res Function(_SuppressionEntry) _then) = __$SuppressionEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String? email, String? emailDomain, String? phone, String? businessKey, String reason, String? source, String? note, DateTime? createdAt
});




}
/// @nodoc
class __$SuppressionEntryCopyWithImpl<$Res>
    implements _$SuppressionEntryCopyWith<$Res> {
  __$SuppressionEntryCopyWithImpl(this._self, this._then);

  final _SuppressionEntry _self;
  final $Res Function(_SuppressionEntry) _then;

/// Create a copy of SuppressionEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = freezed,Object? emailDomain = freezed,Object? phone = freezed,Object? businessKey = freezed,Object? reason = null,Object? source = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(_SuppressionEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailDomain: freezed == emailDomain ? _self.emailDomain : emailDomain // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,businessKey: freezed == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String?,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$TemplateVariant {

 String get subject; String get body;
/// Create a copy of TemplateVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateVariantCopyWith<TemplateVariant> get copyWith => _$TemplateVariantCopyWithImpl<TemplateVariant>(this as TemplateVariant, _$identity);

  /// Serializes this TemplateVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TemplateVariant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateVariant&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.body, _this.body) || other.body == _this.body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TemplateVariant;
  return Object.hash(runtimeType,_this.subject,_this.body);
}

@override
String toString() {
  final _this = this as TemplateVariant;
  return 'TemplateVariant(subject: ${_this.subject}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $TemplateVariantCopyWith<$Res>  {
  factory $TemplateVariantCopyWith(TemplateVariant value, $Res Function(TemplateVariant) _then) = _$TemplateVariantCopyWithImpl;
@useResult
$Res call({
 String subject, String body
});




}
/// @nodoc
class _$TemplateVariantCopyWithImpl<$Res>
    implements $TemplateVariantCopyWith<$Res> {
  _$TemplateVariantCopyWithImpl(this._self, this._then);

  final TemplateVariant _self;
  final $Res Function(TemplateVariant) _then;

/// Create a copy of TemplateVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subject = null,Object? body = null,}) {
  return _then(TemplateVariant(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateVariant].
extension TemplateVariantPatterns on TemplateVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateVariant value)  $default,){
final _that = this;
switch (_that) {
case _TemplateVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateVariant value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subject,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateVariant() when $default != null:
return $default(_that.subject,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subject,  String body)  $default,) {final _that = this;
switch (_that) {
case _TemplateVariant():
return $default(_that.subject,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subject,  String body)?  $default,) {final _that = this;
switch (_that) {
case _TemplateVariant() when $default != null:
return $default(_that.subject,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateVariant implements TemplateVariant {
  const _TemplateVariant({this.subject = '', required this.body});
  factory _TemplateVariant.fromJson(Map<String, dynamic> json) => _$TemplateVariantFromJson(json);

@override@JsonKey() final  String subject;
@override final  String body;

/// Create a copy of TemplateVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateVariantCopyWith<_TemplateVariant> get copyWith => __$TemplateVariantCopyWithImpl<_TemplateVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateVariantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateVariant&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,subject,body);
}

@override
String toString() {
    return 'TemplateVariant(subject: $subject, body: $body)';
}


}

/// @nodoc
abstract mixin class _$TemplateVariantCopyWith<$Res> implements $TemplateVariantCopyWith<$Res> {
  factory _$TemplateVariantCopyWith(_TemplateVariant value, $Res Function(_TemplateVariant) _then) = __$TemplateVariantCopyWithImpl;
@override @useResult
$Res call({
 String subject, String body
});




}
/// @nodoc
class __$TemplateVariantCopyWithImpl<$Res>
    implements _$TemplateVariantCopyWith<$Res> {
  __$TemplateVariantCopyWithImpl(this._self, this._then);

  final _TemplateVariant _self;
  final $Res Function(_TemplateVariant) _then;

/// Create a copy of TemplateVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subject = null,Object? body = null,}) {
  return _then(_TemplateVariant(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SequenceStep {

 int get step; int get delayDays; bool get includeBrochure; List<TemplateVariant> get variants;
/// Create a copy of SequenceStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SequenceStepCopyWith<SequenceStep> get copyWith => _$SequenceStepCopyWithImpl<SequenceStep>(this as SequenceStep, _$identity);

  /// Serializes this SequenceStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SequenceStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SequenceStep&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.delayDays, _this.delayDays) || other.delayDays == _this.delayDays)&&(identical(other.includeBrochure, _this.includeBrochure) || other.includeBrochure == _this.includeBrochure)&&const DeepCollectionEquality().equals(other.variants, _this.variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SequenceStep;
  return Object.hash(runtimeType,_this.step,_this.delayDays,_this.includeBrochure,const DeepCollectionEquality().hash(_this.variants));
}

@override
String toString() {
  final _this = this as SequenceStep;
  return 'SequenceStep(step: ${_this.step}, delayDays: ${_this.delayDays}, includeBrochure: ${_this.includeBrochure}, variants: ${_this.variants})';
}


}

/// @nodoc
abstract mixin class $SequenceStepCopyWith<$Res>  {
  factory $SequenceStepCopyWith(SequenceStep value, $Res Function(SequenceStep) _then) = _$SequenceStepCopyWithImpl;
@useResult
$Res call({
 int step, int delayDays, bool includeBrochure, List<TemplateVariant> variants
});




}
/// @nodoc
class _$SequenceStepCopyWithImpl<$Res>
    implements $SequenceStepCopyWith<$Res> {
  _$SequenceStepCopyWithImpl(this._self, this._then);

  final SequenceStep _self;
  final $Res Function(SequenceStep) _then;

/// Create a copy of SequenceStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? delayDays = null,Object? includeBrochure = null,Object? variants = null,}) {
  return _then(SequenceStep(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,delayDays: null == delayDays ? _self.delayDays : delayDays // ignore: cast_nullable_to_non_nullable
as int,includeBrochure: null == includeBrochure ? _self.includeBrochure : includeBrochure // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<TemplateVariant>,
  ));
}

}


/// Adds pattern-matching-related methods to [SequenceStep].
extension SequenceStepPatterns on SequenceStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SequenceStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SequenceStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SequenceStep value)  $default,){
final _that = this;
switch (_that) {
case _SequenceStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SequenceStep value)?  $default,){
final _that = this;
switch (_that) {
case _SequenceStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  int delayDays,  bool includeBrochure,  List<TemplateVariant> variants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SequenceStep() when $default != null:
return $default(_that.step,_that.delayDays,_that.includeBrochure,_that.variants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  int delayDays,  bool includeBrochure,  List<TemplateVariant> variants)  $default,) {final _that = this;
switch (_that) {
case _SequenceStep():
return $default(_that.step,_that.delayDays,_that.includeBrochure,_that.variants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  int delayDays,  bool includeBrochure,  List<TemplateVariant> variants)?  $default,) {final _that = this;
switch (_that) {
case _SequenceStep() when $default != null:
return $default(_that.step,_that.delayDays,_that.includeBrochure,_that.variants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SequenceStep implements SequenceStep {
  const _SequenceStep({required this.step, this.delayDays = 0, this.includeBrochure = false,  List<TemplateVariant> variants = const <TemplateVariant>[]}): _variants = variants;
  factory _SequenceStep.fromJson(Map<String, dynamic> json) => _$SequenceStepFromJson(json);

@override final  int step;
@override@JsonKey() final  int delayDays;
@override@JsonKey() final  bool includeBrochure;
 final  List<TemplateVariant> _variants;
@override@JsonKey() List<TemplateVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}


/// Create a copy of SequenceStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SequenceStepCopyWith<_SequenceStep> get copyWith => __$SequenceStepCopyWithImpl<_SequenceStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SequenceStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SequenceStep&&(identical(other.step, step) || other.step == step)&&(identical(other.delayDays, delayDays) || other.delayDays == delayDays)&&(identical(other.includeBrochure, includeBrochure) || other.includeBrochure == includeBrochure)&&const DeepCollectionEquality().equals(other.variants, _variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,step,delayDays,includeBrochure,const DeepCollectionEquality().hash(_variants));
}

@override
String toString() {
    return 'SequenceStep(step: $step, delayDays: $delayDays, includeBrochure: $includeBrochure, variants: $variants)';
}


}

/// @nodoc
abstract mixin class _$SequenceStepCopyWith<$Res> implements $SequenceStepCopyWith<$Res> {
  factory _$SequenceStepCopyWith(_SequenceStep value, $Res Function(_SequenceStep) _then) = __$SequenceStepCopyWithImpl;
@override @useResult
$Res call({
 int step, int delayDays, bool includeBrochure, List<TemplateVariant> variants
});




}
/// @nodoc
class __$SequenceStepCopyWithImpl<$Res>
    implements _$SequenceStepCopyWith<$Res> {
  __$SequenceStepCopyWithImpl(this._self, this._then);

  final _SequenceStep _self;
  final $Res Function(_SequenceStep) _then;

/// Create a copy of SequenceStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? delayDays = null,Object? includeBrochure = null,Object? variants = null,}) {
  return _then(_SequenceStep(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,delayDays: null == delayDays ? _self.delayDays : delayDays // ignore: cast_nullable_to_non_nullable
as int,includeBrochure: null == includeBrochure ? _self.includeBrochure : includeBrochure // ignore: cast_nullable_to_non_nullable
as bool,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<TemplateVariant>,
  ));
}


}


/// @nodoc
mixin _$OutreachSequence {

 String get id; String get name; String get channel; String get language; List<SequenceStep> get steps;
/// Create a copy of OutreachSequence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutreachSequenceCopyWith<OutreachSequence> get copyWith => _$OutreachSequenceCopyWithImpl<OutreachSequence>(this as OutreachSequence, _$identity);

  /// Serializes this OutreachSequence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutreachSequence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutreachSequence&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&(identical(other.language, _this.language) || other.language == _this.language)&&const DeepCollectionEquality().equals(other.steps, _this.steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutreachSequence;
  return Object.hash(runtimeType,_this.id,_this.name,_this.channel,_this.language,const DeepCollectionEquality().hash(_this.steps));
}

@override
String toString() {
  final _this = this as OutreachSequence;
  return 'OutreachSequence(id: ${_this.id}, name: ${_this.name}, channel: ${_this.channel}, language: ${_this.language}, steps: ${_this.steps})';
}


}

/// @nodoc
abstract mixin class $OutreachSequenceCopyWith<$Res>  {
  factory $OutreachSequenceCopyWith(OutreachSequence value, $Res Function(OutreachSequence) _then) = _$OutreachSequenceCopyWithImpl;
@useResult
$Res call({
 String id, String name, String channel, String language, List<SequenceStep> steps
});




}
/// @nodoc
class _$OutreachSequenceCopyWithImpl<$Res>
    implements $OutreachSequenceCopyWith<$Res> {
  _$OutreachSequenceCopyWithImpl(this._self, this._then);

  final OutreachSequence _self;
  final $Res Function(OutreachSequence) _then;

/// Create a copy of OutreachSequence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? channel = null,Object? language = null,Object? steps = null,}) {
  return _then(OutreachSequence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<SequenceStep>,
  ));
}

}


/// Adds pattern-matching-related methods to [OutreachSequence].
extension OutreachSequencePatterns on OutreachSequence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutreachSequence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutreachSequence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutreachSequence value)  $default,){
final _that = this;
switch (_that) {
case _OutreachSequence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutreachSequence value)?  $default,){
final _that = this;
switch (_that) {
case _OutreachSequence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String channel,  String language,  List<SequenceStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutreachSequence() when $default != null:
return $default(_that.id,_that.name,_that.channel,_that.language,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String channel,  String language,  List<SequenceStep> steps)  $default,) {final _that = this;
switch (_that) {
case _OutreachSequence():
return $default(_that.id,_that.name,_that.channel,_that.language,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String channel,  String language,  List<SequenceStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _OutreachSequence() when $default != null:
return $default(_that.id,_that.name,_that.channel,_that.language,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutreachSequence implements OutreachSequence {
  const _OutreachSequence({required this.id, required this.name, this.channel = 'email', this.language = 'en',  List<SequenceStep> steps = const <SequenceStep>[]}): _steps = steps;
  factory _OutreachSequence.fromJson(Map<String, dynamic> json) => _$OutreachSequenceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String channel;
@override@JsonKey() final  String language;
 final  List<SequenceStep> _steps;
@override@JsonKey() List<SequenceStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of OutreachSequence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutreachSequenceCopyWith<_OutreachSequence> get copyWith => __$OutreachSequenceCopyWithImpl<_OutreachSequence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutreachSequenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutreachSequence&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,channel,language,const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'OutreachSequence(id: $id, name: $name, channel: $channel, language: $language, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$OutreachSequenceCopyWith<$Res> implements $OutreachSequenceCopyWith<$Res> {
  factory _$OutreachSequenceCopyWith(_OutreachSequence value, $Res Function(_OutreachSequence) _then) = __$OutreachSequenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String channel, String language, List<SequenceStep> steps
});




}
/// @nodoc
class __$OutreachSequenceCopyWithImpl<$Res>
    implements _$OutreachSequenceCopyWith<$Res> {
  __$OutreachSequenceCopyWithImpl(this._self, this._then);

  final _OutreachSequence _self;
  final $Res Function(_OutreachSequence) _then;

/// Create a copy of OutreachSequence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? channel = null,Object? language = null,Object? steps = null,}) {
  return _then(_OutreachSequence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<SequenceStep>,
  ));
}


}


/// @nodoc
mixin _$OutreachCampaign {

 String get id; String get name; String get sequenceId; String get status; List<int> get categoryIds; List<String> get states; List<String> get inboxIds; int get dailyCap; String? get pausedReason; DateTime? get pausedAt;
/// Create a copy of OutreachCampaign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutreachCampaignCopyWith<OutreachCampaign> get copyWith => _$OutreachCampaignCopyWithImpl<OutreachCampaign>(this as OutreachCampaign, _$identity);

  /// Serializes this OutreachCampaign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutreachCampaign;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutreachCampaign&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sequenceId, _this.sequenceId) || other.sequenceId == _this.sequenceId)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.categoryIds, _this.categoryIds)&&const DeepCollectionEquality().equals(other.states, _this.states)&&const DeepCollectionEquality().equals(other.inboxIds, _this.inboxIds)&&(identical(other.dailyCap, _this.dailyCap) || other.dailyCap == _this.dailyCap)&&(identical(other.pausedReason, _this.pausedReason) || other.pausedReason == _this.pausedReason)&&(identical(other.pausedAt, _this.pausedAt) || other.pausedAt == _this.pausedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutreachCampaign;
  return Object.hash(runtimeType,_this.id,_this.name,_this.sequenceId,_this.status,const DeepCollectionEquality().hash(_this.categoryIds),const DeepCollectionEquality().hash(_this.states),const DeepCollectionEquality().hash(_this.inboxIds),_this.dailyCap,_this.pausedReason,_this.pausedAt);
}

@override
String toString() {
  final _this = this as OutreachCampaign;
  return 'OutreachCampaign(id: ${_this.id}, name: ${_this.name}, sequenceId: ${_this.sequenceId}, status: ${_this.status}, categoryIds: ${_this.categoryIds}, states: ${_this.states}, inboxIds: ${_this.inboxIds}, dailyCap: ${_this.dailyCap}, pausedReason: ${_this.pausedReason}, pausedAt: ${_this.pausedAt})';
}


}

/// @nodoc
abstract mixin class $OutreachCampaignCopyWith<$Res>  {
  factory $OutreachCampaignCopyWith(OutreachCampaign value, $Res Function(OutreachCampaign) _then) = _$OutreachCampaignCopyWithImpl;
@useResult
$Res call({
 String id, String name, String sequenceId, String status, List<int> categoryIds, List<String> states, List<String> inboxIds, int dailyCap, String? pausedReason, DateTime? pausedAt
});




}
/// @nodoc
class _$OutreachCampaignCopyWithImpl<$Res>
    implements $OutreachCampaignCopyWith<$Res> {
  _$OutreachCampaignCopyWithImpl(this._self, this._then);

  final OutreachCampaign _self;
  final $Res Function(OutreachCampaign) _then;

/// Create a copy of OutreachCampaign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sequenceId = null,Object? status = null,Object? categoryIds = null,Object? states = null,Object? inboxIds = null,Object? dailyCap = null,Object? pausedReason = freezed,Object? pausedAt = freezed,}) {
  return _then(OutreachCampaign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sequenceId: null == sequenceId ? _self.sequenceId : sequenceId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as List<String>,inboxIds: null == inboxIds ? _self.inboxIds : inboxIds // ignore: cast_nullable_to_non_nullable
as List<String>,dailyCap: null == dailyCap ? _self.dailyCap : dailyCap // ignore: cast_nullable_to_non_nullable
as int,pausedReason: freezed == pausedReason ? _self.pausedReason : pausedReason // ignore: cast_nullable_to_non_nullable
as String?,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutreachCampaign].
extension OutreachCampaignPatterns on OutreachCampaign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutreachCampaign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutreachCampaign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutreachCampaign value)  $default,){
final _that = this;
switch (_that) {
case _OutreachCampaign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutreachCampaign value)?  $default,){
final _that = this;
switch (_that) {
case _OutreachCampaign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String sequenceId,  String status,  List<int> categoryIds,  List<String> states,  List<String> inboxIds,  int dailyCap,  String? pausedReason,  DateTime? pausedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutreachCampaign() when $default != null:
return $default(_that.id,_that.name,_that.sequenceId,_that.status,_that.categoryIds,_that.states,_that.inboxIds,_that.dailyCap,_that.pausedReason,_that.pausedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String sequenceId,  String status,  List<int> categoryIds,  List<String> states,  List<String> inboxIds,  int dailyCap,  String? pausedReason,  DateTime? pausedAt)  $default,) {final _that = this;
switch (_that) {
case _OutreachCampaign():
return $default(_that.id,_that.name,_that.sequenceId,_that.status,_that.categoryIds,_that.states,_that.inboxIds,_that.dailyCap,_that.pausedReason,_that.pausedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String sequenceId,  String status,  List<int> categoryIds,  List<String> states,  List<String> inboxIds,  int dailyCap,  String? pausedReason,  DateTime? pausedAt)?  $default,) {final _that = this;
switch (_that) {
case _OutreachCampaign() when $default != null:
return $default(_that.id,_that.name,_that.sequenceId,_that.status,_that.categoryIds,_that.states,_that.inboxIds,_that.dailyCap,_that.pausedReason,_that.pausedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutreachCampaign implements OutreachCampaign {
  const _OutreachCampaign({required this.id, required this.name, required this.sequenceId, this.status = 'draft',  List<int> categoryIds = const <int>[],  List<String> states = const <String>[],  List<String> inboxIds = const <String>[], this.dailyCap = 50, this.pausedReason, this.pausedAt}): _categoryIds = categoryIds,_states = states,_inboxIds = inboxIds;
  factory _OutreachCampaign.fromJson(Map<String, dynamic> json) => _$OutreachCampaignFromJson(json);

@override final  String id;
@override final  String name;
@override final  String sequenceId;
@override@JsonKey() final  String status;
 final  List<int> _categoryIds;
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

 final  List<String> _states;
@override@JsonKey() List<String> get states {
  if (_states is EqualUnmodifiableListView) return _states;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_states);
}

 final  List<String> _inboxIds;
@override@JsonKey() List<String> get inboxIds {
  if (_inboxIds is EqualUnmodifiableListView) return _inboxIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inboxIds);
}

@override@JsonKey() final  int dailyCap;
@override final  String? pausedReason;
@override final  DateTime? pausedAt;

/// Create a copy of OutreachCampaign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutreachCampaignCopyWith<_OutreachCampaign> get copyWith => __$OutreachCampaignCopyWithImpl<_OutreachCampaign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutreachCampaignToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutreachCampaign&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sequenceId, sequenceId) || other.sequenceId == sequenceId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.categoryIds, _categoryIds)&&const DeepCollectionEquality().equals(other.states, _states)&&const DeepCollectionEquality().equals(other.inboxIds, _inboxIds)&&(identical(other.dailyCap, dailyCap) || other.dailyCap == dailyCap)&&(identical(other.pausedReason, pausedReason) || other.pausedReason == pausedReason)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,sequenceId,status,const DeepCollectionEquality().hash(_categoryIds),const DeepCollectionEquality().hash(_states),const DeepCollectionEquality().hash(_inboxIds),dailyCap,pausedReason,pausedAt);
}

@override
String toString() {
    return 'OutreachCampaign(id: $id, name: $name, sequenceId: $sequenceId, status: $status, categoryIds: $categoryIds, states: $states, inboxIds: $inboxIds, dailyCap: $dailyCap, pausedReason: $pausedReason, pausedAt: $pausedAt)';
}


}

/// @nodoc
abstract mixin class _$OutreachCampaignCopyWith<$Res> implements $OutreachCampaignCopyWith<$Res> {
  factory _$OutreachCampaignCopyWith(_OutreachCampaign value, $Res Function(_OutreachCampaign) _then) = __$OutreachCampaignCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String sequenceId, String status, List<int> categoryIds, List<String> states, List<String> inboxIds, int dailyCap, String? pausedReason, DateTime? pausedAt
});




}
/// @nodoc
class __$OutreachCampaignCopyWithImpl<$Res>
    implements _$OutreachCampaignCopyWith<$Res> {
  __$OutreachCampaignCopyWithImpl(this._self, this._then);

  final _OutreachCampaign _self;
  final $Res Function(_OutreachCampaign) _then;

/// Create a copy of OutreachCampaign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sequenceId = null,Object? status = null,Object? categoryIds = null,Object? states = null,Object? inboxIds = null,Object? dailyCap = null,Object? pausedReason = freezed,Object? pausedAt = freezed,}) {
  return _then(_OutreachCampaign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sequenceId: null == sequenceId ? _self.sequenceId : sequenceId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,states: null == states ? _self._states : states // ignore: cast_nullable_to_non_nullable
as List<String>,inboxIds: null == inboxIds ? _self._inboxIds : inboxIds // ignore: cast_nullable_to_non_nullable
as List<String>,dailyCap: null == dailyCap ? _self.dailyCap : dailyCap // ignore: cast_nullable_to_non_nullable
as int,pausedReason: freezed == pausedReason ? _self.pausedReason : pausedReason // ignore: cast_nullable_to_non_nullable
as String?,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OutreachInbox {

 String get id; String get email; String get displayName; String get provider; int get dailyCapStart; int get dailyCapMax; int get rampPerWeek; DateTime get warmupStartedOn; bool get active;
/// Create a copy of OutreachInbox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutreachInboxCopyWith<OutreachInbox> get copyWith => _$OutreachInboxCopyWithImpl<OutreachInbox>(this as OutreachInbox, _$identity);

  /// Serializes this OutreachInbox to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OutreachInbox;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutreachInbox&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.dailyCapStart, _this.dailyCapStart) || other.dailyCapStart == _this.dailyCapStart)&&(identical(other.dailyCapMax, _this.dailyCapMax) || other.dailyCapMax == _this.dailyCapMax)&&(identical(other.rampPerWeek, _this.rampPerWeek) || other.rampPerWeek == _this.rampPerWeek)&&(identical(other.warmupStartedOn, _this.warmupStartedOn) || other.warmupStartedOn == _this.warmupStartedOn)&&(identical(other.active, _this.active) || other.active == _this.active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OutreachInbox;
  return Object.hash(runtimeType,_this.id,_this.email,_this.displayName,_this.provider,_this.dailyCapStart,_this.dailyCapMax,_this.rampPerWeek,_this.warmupStartedOn,_this.active);
}

@override
String toString() {
  final _this = this as OutreachInbox;
  return 'OutreachInbox(id: ${_this.id}, email: ${_this.email}, displayName: ${_this.displayName}, provider: ${_this.provider}, dailyCapStart: ${_this.dailyCapStart}, dailyCapMax: ${_this.dailyCapMax}, rampPerWeek: ${_this.rampPerWeek}, warmupStartedOn: ${_this.warmupStartedOn}, active: ${_this.active})';
}


}

/// @nodoc
abstract mixin class $OutreachInboxCopyWith<$Res>  {
  factory $OutreachInboxCopyWith(OutreachInbox value, $Res Function(OutreachInbox) _then) = _$OutreachInboxCopyWithImpl;
@useResult
$Res call({
 String id, String email, String displayName, String provider, int dailyCapStart, int dailyCapMax, int rampPerWeek, DateTime warmupStartedOn, bool active
});




}
/// @nodoc
class _$OutreachInboxCopyWithImpl<$Res>
    implements $OutreachInboxCopyWith<$Res> {
  _$OutreachInboxCopyWithImpl(this._self, this._then);

  final OutreachInbox _self;
  final $Res Function(OutreachInbox) _then;

/// Create a copy of OutreachInbox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? provider = null,Object? dailyCapStart = null,Object? dailyCapMax = null,Object? rampPerWeek = null,Object? warmupStartedOn = null,Object? active = null,}) {
  return _then(OutreachInbox(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,dailyCapStart: null == dailyCapStart ? _self.dailyCapStart : dailyCapStart // ignore: cast_nullable_to_non_nullable
as int,dailyCapMax: null == dailyCapMax ? _self.dailyCapMax : dailyCapMax // ignore: cast_nullable_to_non_nullable
as int,rampPerWeek: null == rampPerWeek ? _self.rampPerWeek : rampPerWeek // ignore: cast_nullable_to_non_nullable
as int,warmupStartedOn: null == warmupStartedOn ? _self.warmupStartedOn : warmupStartedOn // ignore: cast_nullable_to_non_nullable
as DateTime,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OutreachInbox].
extension OutreachInboxPatterns on OutreachInbox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutreachInbox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutreachInbox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutreachInbox value)  $default,){
final _that = this;
switch (_that) {
case _OutreachInbox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutreachInbox value)?  $default,){
final _that = this;
switch (_that) {
case _OutreachInbox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String provider,  int dailyCapStart,  int dailyCapMax,  int rampPerWeek,  DateTime warmupStartedOn,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutreachInbox() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.provider,_that.dailyCapStart,_that.dailyCapMax,_that.rampPerWeek,_that.warmupStartedOn,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String provider,  int dailyCapStart,  int dailyCapMax,  int rampPerWeek,  DateTime warmupStartedOn,  bool active)  $default,) {final _that = this;
switch (_that) {
case _OutreachInbox():
return $default(_that.id,_that.email,_that.displayName,_that.provider,_that.dailyCapStart,_that.dailyCapMax,_that.rampPerWeek,_that.warmupStartedOn,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String displayName,  String provider,  int dailyCapStart,  int dailyCapMax,  int rampPerWeek,  DateTime warmupStartedOn,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _OutreachInbox() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.provider,_that.dailyCapStart,_that.dailyCapMax,_that.rampPerWeek,_that.warmupStartedOn,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutreachInbox extends OutreachInbox {
  const _OutreachInbox({required this.id, required this.email, required this.displayName, required this.provider, this.dailyCapStart = 20, this.dailyCapMax = 150, this.rampPerWeek = 10, required this.warmupStartedOn, this.active = true}): super._();
  factory _OutreachInbox.fromJson(Map<String, dynamic> json) => _$OutreachInboxFromJson(json);

@override final  String id;
@override final  String email;
@override final  String displayName;
@override final  String provider;
@override@JsonKey() final  int dailyCapStart;
@override@JsonKey() final  int dailyCapMax;
@override@JsonKey() final  int rampPerWeek;
@override final  DateTime warmupStartedOn;
@override@JsonKey() final  bool active;

/// Create a copy of OutreachInbox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutreachInboxCopyWith<_OutreachInbox> get copyWith => __$OutreachInboxCopyWithImpl<_OutreachInbox>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutreachInboxToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutreachInbox&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.dailyCapStart, dailyCapStart) || other.dailyCapStart == dailyCapStart)&&(identical(other.dailyCapMax, dailyCapMax) || other.dailyCapMax == dailyCapMax)&&(identical(other.rampPerWeek, rampPerWeek) || other.rampPerWeek == rampPerWeek)&&(identical(other.warmupStartedOn, warmupStartedOn) || other.warmupStartedOn == warmupStartedOn)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,email,displayName,provider,dailyCapStart,dailyCapMax,rampPerWeek,warmupStartedOn,active);
}

@override
String toString() {
    return 'OutreachInbox(id: $id, email: $email, displayName: $displayName, provider: $provider, dailyCapStart: $dailyCapStart, dailyCapMax: $dailyCapMax, rampPerWeek: $rampPerWeek, warmupStartedOn: $warmupStartedOn, active: $active)';
}


}

/// @nodoc
abstract mixin class _$OutreachInboxCopyWith<$Res> implements $OutreachInboxCopyWith<$Res> {
  factory _$OutreachInboxCopyWith(_OutreachInbox value, $Res Function(_OutreachInbox) _then) = __$OutreachInboxCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String displayName, String provider, int dailyCapStart, int dailyCapMax, int rampPerWeek, DateTime warmupStartedOn, bool active
});




}
/// @nodoc
class __$OutreachInboxCopyWithImpl<$Res>
    implements _$OutreachInboxCopyWith<$Res> {
  __$OutreachInboxCopyWithImpl(this._self, this._then);

  final _OutreachInbox _self;
  final $Res Function(_OutreachInbox) _then;

/// Create a copy of OutreachInbox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? provider = null,Object? dailyCapStart = null,Object? dailyCapMax = null,Object? rampPerWeek = null,Object? warmupStartedOn = null,Object? active = null,}) {
  return _then(_OutreachInbox(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,dailyCapStart: null == dailyCapStart ? _self.dailyCapStart : dailyCapStart // ignore: cast_nullable_to_non_nullable
as int,dailyCapMax: null == dailyCapMax ? _self.dailyCapMax : dailyCapMax // ignore: cast_nullable_to_non_nullable
as int,rampPerWeek: null == rampPerWeek ? _self.rampPerWeek : rampPerWeek // ignore: cast_nullable_to_non_nullable
as int,warmupStartedOn: null == warmupStartedOn ? _self.warmupStartedOn : warmupStartedOn // ignore: cast_nullable_to_non_nullable
as DateTime,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$LeadFilter {

 String? get state; String? get city; int? get categoryId; LeadSource? get source; String? get query;
/// Create a copy of LeadFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadFilterCopyWith<LeadFilter> get copyWith => _$LeadFilterCopyWithImpl<LeadFilter>(this as LeadFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeadFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadFilter&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as LeadFilter;
  return Object.hash(runtimeType,_this.state,_this.city,_this.categoryId,_this.source,_this.query);
}

@override
String toString() {
  final _this = this as LeadFilter;
  return 'LeadFilter(state: ${_this.state}, city: ${_this.city}, categoryId: ${_this.categoryId}, source: ${_this.source}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $LeadFilterCopyWith<$Res>  {
  factory $LeadFilterCopyWith(LeadFilter value, $Res Function(LeadFilter) _then) = _$LeadFilterCopyWithImpl;
@useResult
$Res call({
 String? state, String? city, int? categoryId, LeadSource? source, String? query
});




}
/// @nodoc
class _$LeadFilterCopyWithImpl<$Res>
    implements $LeadFilterCopyWith<$Res> {
  _$LeadFilterCopyWithImpl(this._self, this._then);

  final LeadFilter _self;
  final $Res Function(LeadFilter) _then;

/// Create a copy of LeadFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = freezed,Object? city = freezed,Object? categoryId = freezed,Object? source = freezed,Object? query = freezed,}) {
  return _then(LeadFilter(
state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadFilter].
extension LeadFilterPatterns on LeadFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadFilter value)  $default,){
final _that = this;
switch (_that) {
case _LeadFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadFilter value)?  $default,){
final _that = this;
switch (_that) {
case _LeadFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? state,  String? city,  int? categoryId,  LeadSource? source,  String? query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadFilter() when $default != null:
return $default(_that.state,_that.city,_that.categoryId,_that.source,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? state,  String? city,  int? categoryId,  LeadSource? source,  String? query)  $default,) {final _that = this;
switch (_that) {
case _LeadFilter():
return $default(_that.state,_that.city,_that.categoryId,_that.source,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? state,  String? city,  int? categoryId,  LeadSource? source,  String? query)?  $default,) {final _that = this;
switch (_that) {
case _LeadFilter() when $default != null:
return $default(_that.state,_that.city,_that.categoryId,_that.source,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _LeadFilter implements LeadFilter {
  const _LeadFilter({this.state, this.city, this.categoryId, this.source, this.query});
  

@override final  String? state;
@override final  String? city;
@override final  int? categoryId;
@override final  LeadSource? source;
@override final  String? query;

/// Create a copy of LeadFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadFilterCopyWith<_LeadFilter> get copyWith => __$LeadFilterCopyWithImpl<_LeadFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadFilter&&(identical(other.state, state) || other.state == state)&&(identical(other.city, city) || other.city == city)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.source, source) || other.source == source)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,state,city,categoryId,source,query);
}

@override
String toString() {
    return 'LeadFilter(state: $state, city: $city, categoryId: $categoryId, source: $source, query: $query)';
}


}

/// @nodoc
abstract mixin class _$LeadFilterCopyWith<$Res> implements $LeadFilterCopyWith<$Res> {
  factory _$LeadFilterCopyWith(_LeadFilter value, $Res Function(_LeadFilter) _then) = __$LeadFilterCopyWithImpl;
@override @useResult
$Res call({
 String? state, String? city, int? categoryId, LeadSource? source, String? query
});




}
/// @nodoc
class __$LeadFilterCopyWithImpl<$Res>
    implements _$LeadFilterCopyWith<$Res> {
  __$LeadFilterCopyWithImpl(this._self, this._then);

  final _LeadFilter _self;
  final $Res Function(_LeadFilter) _then;

/// Create a copy of LeadFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = freezed,Object? city = freezed,Object? categoryId = freezed,Object? source = freezed,Object? query = freezed,}) {
  return _then(_LeadFilter(
state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$LeadDraft {

 String get businessKey; String get businessName; List<String> get categoriesSource; List<int> get matchedCategoryIds; String? get email; String? get addressSource; String? get phone; String? get website; String? get websiteDomain; String? get placeId; String? get osmId; String? get address; String? get city; String? get state; String? get postalCode; String? get timezone; double? get rating; int? get ratingCount; LeadSource get source; String? get sourceRef; LawfulBasis get lawfulBasis; String? get chosenReason; int? get priority;
/// Create a copy of LeadDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadDraftCopyWith<LeadDraft> get copyWith => _$LeadDraftCopyWithImpl<LeadDraft>(this as LeadDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeadDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadDraft&&(identical(other.businessKey, _this.businessKey) || other.businessKey == _this.businessKey)&&(identical(other.businessName, _this.businessName) || other.businessName == _this.businessName)&&const DeepCollectionEquality().equals(other.categoriesSource, _this.categoriesSource)&&const DeepCollectionEquality().equals(other.matchedCategoryIds, _this.matchedCategoryIds)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.addressSource, _this.addressSource) || other.addressSource == _this.addressSource)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.website, _this.website) || other.website == _this.website)&&(identical(other.websiteDomain, _this.websiteDomain) || other.websiteDomain == _this.websiteDomain)&&(identical(other.placeId, _this.placeId) || other.placeId == _this.placeId)&&(identical(other.osmId, _this.osmId) || other.osmId == _this.osmId)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.postalCode, _this.postalCode) || other.postalCode == _this.postalCode)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.sourceRef, _this.sourceRef) || other.sourceRef == _this.sourceRef)&&(identical(other.lawfulBasis, _this.lawfulBasis) || other.lawfulBasis == _this.lawfulBasis)&&(identical(other.chosenReason, _this.chosenReason) || other.chosenReason == _this.chosenReason)&&(identical(other.priority, _this.priority) || other.priority == _this.priority));
}


@override
int get hashCode {
  final _this = this as LeadDraft;
  return Object.hashAll([runtimeType,_this.businessKey,_this.businessName,const DeepCollectionEquality().hash(_this.categoriesSource),const DeepCollectionEquality().hash(_this.matchedCategoryIds),_this.email,_this.addressSource,_this.phone,_this.website,_this.websiteDomain,_this.placeId,_this.osmId,_this.address,_this.city,_this.state,_this.postalCode,_this.timezone,_this.rating,_this.ratingCount,_this.source,_this.sourceRef,_this.lawfulBasis,_this.chosenReason,_this.priority]);
}

@override
String toString() {
  final _this = this as LeadDraft;
  return 'LeadDraft(businessKey: ${_this.businessKey}, businessName: ${_this.businessName}, categoriesSource: ${_this.categoriesSource}, matchedCategoryIds: ${_this.matchedCategoryIds}, email: ${_this.email}, addressSource: ${_this.addressSource}, phone: ${_this.phone}, website: ${_this.website}, websiteDomain: ${_this.websiteDomain}, placeId: ${_this.placeId}, osmId: ${_this.osmId}, address: ${_this.address}, city: ${_this.city}, state: ${_this.state}, postalCode: ${_this.postalCode}, timezone: ${_this.timezone}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, source: ${_this.source}, sourceRef: ${_this.sourceRef}, lawfulBasis: ${_this.lawfulBasis}, chosenReason: ${_this.chosenReason}, priority: ${_this.priority})';
}


}

/// @nodoc
abstract mixin class $LeadDraftCopyWith<$Res>  {
  factory $LeadDraftCopyWith(LeadDraft value, $Res Function(LeadDraft) _then) = _$LeadDraftCopyWithImpl;
@useResult
$Res call({
 String businessKey, String businessName, List<String> categoriesSource, List<int> matchedCategoryIds, String? email, String? addressSource, String? phone, String? website, String? websiteDomain, String? placeId, String? osmId, String? address, String? city, String? state, String? postalCode, String? timezone, double? rating, int? ratingCount, LeadSource source, String? sourceRef, LawfulBasis lawfulBasis, String? chosenReason, int? priority
});




}
/// @nodoc
class _$LeadDraftCopyWithImpl<$Res>
    implements $LeadDraftCopyWith<$Res> {
  _$LeadDraftCopyWithImpl(this._self, this._then);

  final LeadDraft _self;
  final $Res Function(LeadDraft) _then;

/// Create a copy of LeadDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? businessKey = null,Object? businessName = null,Object? categoriesSource = null,Object? matchedCategoryIds = null,Object? email = freezed,Object? addressSource = freezed,Object? phone = freezed,Object? website = freezed,Object? websiteDomain = freezed,Object? placeId = freezed,Object? osmId = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? postalCode = freezed,Object? timezone = freezed,Object? rating = freezed,Object? ratingCount = freezed,Object? source = null,Object? sourceRef = freezed,Object? lawfulBasis = null,Object? chosenReason = freezed,Object? priority = freezed,}) {
  return _then(LeadDraft(
businessKey: null == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,categoriesSource: null == categoriesSource ? _self.categoriesSource : categoriesSource // ignore: cast_nullable_to_non_nullable
as List<String>,matchedCategoryIds: null == matchedCategoryIds ? _self.matchedCategoryIds : matchedCategoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,websiteDomain: freezed == websiteDomain ? _self.websiteDomain : websiteDomain // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,osmId: freezed == osmId ? _self.osmId : osmId // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: null == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as LawfulBasis,chosenReason: freezed == chosenReason ? _self.chosenReason : chosenReason // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadDraft].
extension LeadDraftPatterns on LeadDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadDraft value)  $default,){
final _that = this;
switch (_that) {
case _LeadDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadDraft value)?  $default,){
final _that = this;
switch (_that) {
case _LeadDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  int? priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadDraft() when $default != null:
return $default(_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  int? priority)  $default,) {final _that = this;
switch (_that) {
case _LeadDraft():
return $default(_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String businessKey,  String businessName,  List<String> categoriesSource,  List<int> matchedCategoryIds,  String? email,  String? addressSource,  String? phone,  String? website,  String? websiteDomain,  String? placeId,  String? osmId,  String? address,  String? city,  String? state,  String? postalCode,  String? timezone,  double? rating,  int? ratingCount,  LeadSource source,  String? sourceRef,  LawfulBasis lawfulBasis,  String? chosenReason,  int? priority)?  $default,) {final _that = this;
switch (_that) {
case _LeadDraft() when $default != null:
return $default(_that.businessKey,_that.businessName,_that.categoriesSource,_that.matchedCategoryIds,_that.email,_that.addressSource,_that.phone,_that.website,_that.websiteDomain,_that.placeId,_that.osmId,_that.address,_that.city,_that.state,_that.postalCode,_that.timezone,_that.rating,_that.ratingCount,_that.source,_that.sourceRef,_that.lawfulBasis,_that.chosenReason,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _LeadDraft extends LeadDraft {
  const _LeadDraft({required this.businessKey, required this.businessName,  List<String> categoriesSource = const <String>[],  List<int> matchedCategoryIds = const <int>[], this.email, this.addressSource, this.phone, this.website, this.websiteDomain, this.placeId, this.osmId, this.address, this.city, this.state, this.postalCode, this.timezone, this.rating, this.ratingCount, required this.source, this.sourceRef, required this.lawfulBasis, this.chosenReason, this.priority}): _categoriesSource = categoriesSource,_matchedCategoryIds = matchedCategoryIds,super._();
  

@override final  String businessKey;
@override final  String businessName;
 final  List<String> _categoriesSource;
@override@JsonKey() List<String> get categoriesSource {
  if (_categoriesSource is EqualUnmodifiableListView) return _categoriesSource;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoriesSource);
}

 final  List<int> _matchedCategoryIds;
@override@JsonKey() List<int> get matchedCategoryIds {
  if (_matchedCategoryIds is EqualUnmodifiableListView) return _matchedCategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matchedCategoryIds);
}

@override final  String? email;
@override final  String? addressSource;
@override final  String? phone;
@override final  String? website;
@override final  String? websiteDomain;
@override final  String? placeId;
@override final  String? osmId;
@override final  String? address;
@override final  String? city;
@override final  String? state;
@override final  String? postalCode;
@override final  String? timezone;
@override final  double? rating;
@override final  int? ratingCount;
@override final  LeadSource source;
@override final  String? sourceRef;
@override final  LawfulBasis lawfulBasis;
@override final  String? chosenReason;
@override final  int? priority;

/// Create a copy of LeadDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadDraftCopyWith<_LeadDraft> get copyWith => __$LeadDraftCopyWithImpl<_LeadDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadDraft&&(identical(other.businessKey, businessKey) || other.businessKey == businessKey)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&const DeepCollectionEquality().equals(other.categoriesSource, _categoriesSource)&&const DeepCollectionEquality().equals(other.matchedCategoryIds, _matchedCategoryIds)&&(identical(other.email, email) || other.email == email)&&(identical(other.addressSource, addressSource) || other.addressSource == addressSource)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.website, website) || other.website == website)&&(identical(other.websiteDomain, websiteDomain) || other.websiteDomain == websiteDomain)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.osmId, osmId) || other.osmId == osmId)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceRef, sourceRef) || other.sourceRef == sourceRef)&&(identical(other.lawfulBasis, lawfulBasis) || other.lawfulBasis == lawfulBasis)&&(identical(other.chosenReason, chosenReason) || other.chosenReason == chosenReason)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,businessKey,businessName,const DeepCollectionEquality().hash(_categoriesSource),const DeepCollectionEquality().hash(_matchedCategoryIds),email,addressSource,phone,website,websiteDomain,placeId,osmId,address,city,state,postalCode,timezone,rating,ratingCount,source,sourceRef,lawfulBasis,chosenReason,priority]);
}

@override
String toString() {
    return 'LeadDraft(businessKey: $businessKey, businessName: $businessName, categoriesSource: $categoriesSource, matchedCategoryIds: $matchedCategoryIds, email: $email, addressSource: $addressSource, phone: $phone, website: $website, websiteDomain: $websiteDomain, placeId: $placeId, osmId: $osmId, address: $address, city: $city, state: $state, postalCode: $postalCode, timezone: $timezone, rating: $rating, ratingCount: $ratingCount, source: $source, sourceRef: $sourceRef, lawfulBasis: $lawfulBasis, chosenReason: $chosenReason, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$LeadDraftCopyWith<$Res> implements $LeadDraftCopyWith<$Res> {
  factory _$LeadDraftCopyWith(_LeadDraft value, $Res Function(_LeadDraft) _then) = __$LeadDraftCopyWithImpl;
@override @useResult
$Res call({
 String businessKey, String businessName, List<String> categoriesSource, List<int> matchedCategoryIds, String? email, String? addressSource, String? phone, String? website, String? websiteDomain, String? placeId, String? osmId, String? address, String? city, String? state, String? postalCode, String? timezone, double? rating, int? ratingCount, LeadSource source, String? sourceRef, LawfulBasis lawfulBasis, String? chosenReason, int? priority
});




}
/// @nodoc
class __$LeadDraftCopyWithImpl<$Res>
    implements _$LeadDraftCopyWith<$Res> {
  __$LeadDraftCopyWithImpl(this._self, this._then);

  final _LeadDraft _self;
  final $Res Function(_LeadDraft) _then;

/// Create a copy of LeadDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? businessKey = null,Object? businessName = null,Object? categoriesSource = null,Object? matchedCategoryIds = null,Object? email = freezed,Object? addressSource = freezed,Object? phone = freezed,Object? website = freezed,Object? websiteDomain = freezed,Object? placeId = freezed,Object? osmId = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? postalCode = freezed,Object? timezone = freezed,Object? rating = freezed,Object? ratingCount = freezed,Object? source = null,Object? sourceRef = freezed,Object? lawfulBasis = null,Object? chosenReason = freezed,Object? priority = freezed,}) {
  return _then(_LeadDraft(
businessKey: null == businessKey ? _self.businessKey : businessKey // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,categoriesSource: null == categoriesSource ? _self._categoriesSource : categoriesSource // ignore: cast_nullable_to_non_nullable
as List<String>,matchedCategoryIds: null == matchedCategoryIds ? _self._matchedCategoryIds : matchedCategoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,addressSource: freezed == addressSource ? _self.addressSource : addressSource // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,websiteDomain: freezed == websiteDomain ? _self.websiteDomain : websiteDomain // ignore: cast_nullable_to_non_nullable
as String?,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,osmId: freezed == osmId ? _self.osmId : osmId // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,lawfulBasis: null == lawfulBasis ? _self.lawfulBasis : lawfulBasis // ignore: cast_nullable_to_non_nullable
as LawfulBasis,chosenReason: freezed == chosenReason ? _self.chosenReason : chosenReason // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
