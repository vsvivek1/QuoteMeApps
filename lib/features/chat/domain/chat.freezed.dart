// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Chat {

 String get id; String get requestId; String get buyerId; String get sellerId; String get requestTitle; String get counterpartName; String? get counterpartPhotoUrl; String? get lastMessage; DateTime? get lastMessageAt; int get unread; bool get quoteAccepted;
/// Create a copy of Chat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatCopyWith<Chat> get copyWith => _$ChatCopyWithImpl<Chat>(this as Chat, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Chat;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chat&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.buyerId, _this.buyerId) || other.buyerId == _this.buyerId)&&(identical(other.sellerId, _this.sellerId) || other.sellerId == _this.sellerId)&&(identical(other.requestTitle, _this.requestTitle) || other.requestTitle == _this.requestTitle)&&(identical(other.counterpartName, _this.counterpartName) || other.counterpartName == _this.counterpartName)&&(identical(other.counterpartPhotoUrl, _this.counterpartPhotoUrl) || other.counterpartPhotoUrl == _this.counterpartPhotoUrl)&&(identical(other.lastMessage, _this.lastMessage) || other.lastMessage == _this.lastMessage)&&(identical(other.lastMessageAt, _this.lastMessageAt) || other.lastMessageAt == _this.lastMessageAt)&&(identical(other.unread, _this.unread) || other.unread == _this.unread)&&(identical(other.quoteAccepted, _this.quoteAccepted) || other.quoteAccepted == _this.quoteAccepted));
}


@override
int get hashCode {
  final _this = this as Chat;
  return Object.hash(runtimeType,_this.id,_this.requestId,_this.buyerId,_this.sellerId,_this.requestTitle,_this.counterpartName,_this.counterpartPhotoUrl,_this.lastMessage,_this.lastMessageAt,_this.unread,_this.quoteAccepted);
}

@override
String toString() {
  final _this = this as Chat;
  return 'Chat(id: ${_this.id}, requestId: ${_this.requestId}, buyerId: ${_this.buyerId}, sellerId: ${_this.sellerId}, requestTitle: ${_this.requestTitle}, counterpartName: ${_this.counterpartName}, counterpartPhotoUrl: ${_this.counterpartPhotoUrl}, lastMessage: ${_this.lastMessage}, lastMessageAt: ${_this.lastMessageAt}, unread: ${_this.unread}, quoteAccepted: ${_this.quoteAccepted})';
}


}

/// @nodoc
abstract mixin class $ChatCopyWith<$Res>  {
  factory $ChatCopyWith(Chat value, $Res Function(Chat) _then) = _$ChatCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, String buyerId, String sellerId, String requestTitle, String counterpartName, String? counterpartPhotoUrl, String? lastMessage, DateTime? lastMessageAt, int unread, bool quoteAccepted
});




}
/// @nodoc
class _$ChatCopyWithImpl<$Res>
    implements $ChatCopyWith<$Res> {
  _$ChatCopyWithImpl(this._self, this._then);

  final Chat _self;
  final $Res Function(Chat) _then;

/// Create a copy of Chat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? buyerId = null,Object? sellerId = null,Object? requestTitle = null,Object? counterpartName = null,Object? counterpartPhotoUrl = freezed,Object? lastMessage = freezed,Object? lastMessageAt = freezed,Object? unread = null,Object? quoteAccepted = null,}) {
  return _then(Chat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,requestTitle: null == requestTitle ? _self.requestTitle : requestTitle // ignore: cast_nullable_to_non_nullable
as String,counterpartName: null == counterpartName ? _self.counterpartName : counterpartName // ignore: cast_nullable_to_non_nullable
as String,counterpartPhotoUrl: freezed == counterpartPhotoUrl ? _self.counterpartPhotoUrl : counterpartPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,quoteAccepted: null == quoteAccepted ? _self.quoteAccepted : quoteAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Chat].
extension ChatPatterns on Chat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Chat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Chat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Chat value)  $default,){
final _that = this;
switch (_that) {
case _Chat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Chat value)?  $default,){
final _that = this;
switch (_that) {
case _Chat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requestId,  String buyerId,  String sellerId,  String requestTitle,  String counterpartName,  String? counterpartPhotoUrl,  String? lastMessage,  DateTime? lastMessageAt,  int unread,  bool quoteAccepted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Chat() when $default != null:
return $default(_that.id,_that.requestId,_that.buyerId,_that.sellerId,_that.requestTitle,_that.counterpartName,_that.counterpartPhotoUrl,_that.lastMessage,_that.lastMessageAt,_that.unread,_that.quoteAccepted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requestId,  String buyerId,  String sellerId,  String requestTitle,  String counterpartName,  String? counterpartPhotoUrl,  String? lastMessage,  DateTime? lastMessageAt,  int unread,  bool quoteAccepted)  $default,) {final _that = this;
switch (_that) {
case _Chat():
return $default(_that.id,_that.requestId,_that.buyerId,_that.sellerId,_that.requestTitle,_that.counterpartName,_that.counterpartPhotoUrl,_that.lastMessage,_that.lastMessageAt,_that.unread,_that.quoteAccepted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requestId,  String buyerId,  String sellerId,  String requestTitle,  String counterpartName,  String? counterpartPhotoUrl,  String? lastMessage,  DateTime? lastMessageAt,  int unread,  bool quoteAccepted)?  $default,) {final _that = this;
switch (_that) {
case _Chat() when $default != null:
return $default(_that.id,_that.requestId,_that.buyerId,_that.sellerId,_that.requestTitle,_that.counterpartName,_that.counterpartPhotoUrl,_that.lastMessage,_that.lastMessageAt,_that.unread,_that.quoteAccepted);case _:
  return null;

}
}

}

/// @nodoc


class _Chat implements Chat {
  const _Chat({required this.id, required this.requestId, required this.buyerId, required this.sellerId, required this.requestTitle, required this.counterpartName, this.counterpartPhotoUrl, this.lastMessage, this.lastMessageAt, this.unread = 0, this.quoteAccepted = false});
  

@override final  String id;
@override final  String requestId;
@override final  String buyerId;
@override final  String sellerId;
@override final  String requestTitle;
@override final  String counterpartName;
@override final  String? counterpartPhotoUrl;
@override final  String? lastMessage;
@override final  DateTime? lastMessageAt;
@override@JsonKey() final  int unread;
@override@JsonKey() final  bool quoteAccepted;

/// Create a copy of Chat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatCopyWith<_Chat> get copyWith => __$ChatCopyWithImpl<_Chat>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Chat&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.requestTitle, requestTitle) || other.requestTitle == requestTitle)&&(identical(other.counterpartName, counterpartName) || other.counterpartName == counterpartName)&&(identical(other.counterpartPhotoUrl, counterpartPhotoUrl) || other.counterpartPhotoUrl == counterpartPhotoUrl)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.unread, unread) || other.unread == unread)&&(identical(other.quoteAccepted, quoteAccepted) || other.quoteAccepted == quoteAccepted));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,requestId,buyerId,sellerId,requestTitle,counterpartName,counterpartPhotoUrl,lastMessage,lastMessageAt,unread,quoteAccepted);
}

@override
String toString() {
    return 'Chat(id: $id, requestId: $requestId, buyerId: $buyerId, sellerId: $sellerId, requestTitle: $requestTitle, counterpartName: $counterpartName, counterpartPhotoUrl: $counterpartPhotoUrl, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, unread: $unread, quoteAccepted: $quoteAccepted)';
}


}

/// @nodoc
abstract mixin class _$ChatCopyWith<$Res> implements $ChatCopyWith<$Res> {
  factory _$ChatCopyWith(_Chat value, $Res Function(_Chat) _then) = __$ChatCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, String buyerId, String sellerId, String requestTitle, String counterpartName, String? counterpartPhotoUrl, String? lastMessage, DateTime? lastMessageAt, int unread, bool quoteAccepted
});




}
/// @nodoc
class __$ChatCopyWithImpl<$Res>
    implements _$ChatCopyWith<$Res> {
  __$ChatCopyWithImpl(this._self, this._then);

  final _Chat _self;
  final $Res Function(_Chat) _then;

/// Create a copy of Chat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? buyerId = null,Object? sellerId = null,Object? requestTitle = null,Object? counterpartName = null,Object? counterpartPhotoUrl = freezed,Object? lastMessage = freezed,Object? lastMessageAt = freezed,Object? unread = null,Object? quoteAccepted = null,}) {
  return _then(_Chat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,requestTitle: null == requestTitle ? _self.requestTitle : requestTitle // ignore: cast_nullable_to_non_nullable
as String,counterpartName: null == counterpartName ? _self.counterpartName : counterpartName // ignore: cast_nullable_to_non_nullable
as String,counterpartPhotoUrl: freezed == counterpartPhotoUrl ? _self.counterpartPhotoUrl : counterpartPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,quoteAccepted: null == quoteAccepted ? _self.quoteAccepted : quoteAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ChatMessage {

 String get id; String get chatId; String get senderId; MessageType get type; String get body; String? get attachmentPath; String? get attachmentUrl; DateTime get createdAt; DateTime? get readAt; SendState get sendState; String? get clientId;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.chatId, _this.chatId) || other.chatId == _this.chatId)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.attachmentPath, _this.attachmentPath) || other.attachmentPath == _this.attachmentPath)&&(identical(other.attachmentUrl, _this.attachmentUrl) || other.attachmentUrl == _this.attachmentUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.sendState, _this.sendState) || other.sendState == _this.sendState)&&(identical(other.clientId, _this.clientId) || other.clientId == _this.clientId));
}


@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.id,_this.chatId,_this.senderId,_this.type,_this.body,_this.attachmentPath,_this.attachmentUrl,_this.createdAt,_this.readAt,_this.sendState,_this.clientId);
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(id: ${_this.id}, chatId: ${_this.chatId}, senderId: ${_this.senderId}, type: ${_this.type}, body: ${_this.body}, attachmentPath: ${_this.attachmentPath}, attachmentUrl: ${_this.attachmentUrl}, createdAt: ${_this.createdAt}, readAt: ${_this.readAt}, sendState: ${_this.sendState}, clientId: ${_this.clientId})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String chatId, String senderId, MessageType type, String body, String? attachmentPath, String? attachmentUrl, DateTime createdAt, DateTime? readAt, SendState sendState, String? clientId
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? chatId = null,Object? senderId = null,Object? type = null,Object? body = null,Object? attachmentPath = freezed,Object? attachmentUrl = freezed,Object? createdAt = null,Object? readAt = freezed,Object? sendState = null,Object? clientId = freezed,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sendState: null == sendState ? _self.sendState : sendState // ignore: cast_nullable_to_non_nullable
as SendState,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String chatId,  String senderId,  MessageType type,  String body,  String? attachmentPath,  String? attachmentUrl,  DateTime createdAt,  DateTime? readAt,  SendState sendState,  String? clientId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.chatId,_that.senderId,_that.type,_that.body,_that.attachmentPath,_that.attachmentUrl,_that.createdAt,_that.readAt,_that.sendState,_that.clientId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String chatId,  String senderId,  MessageType type,  String body,  String? attachmentPath,  String? attachmentUrl,  DateTime createdAt,  DateTime? readAt,  SendState sendState,  String? clientId)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.chatId,_that.senderId,_that.type,_that.body,_that.attachmentPath,_that.attachmentUrl,_that.createdAt,_that.readAt,_that.sendState,_that.clientId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String chatId,  String senderId,  MessageType type,  String body,  String? attachmentPath,  String? attachmentUrl,  DateTime createdAt,  DateTime? readAt,  SendState sendState,  String? clientId)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.chatId,_that.senderId,_that.type,_that.body,_that.attachmentPath,_that.attachmentUrl,_that.createdAt,_that.readAt,_that.sendState,_that.clientId);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.chatId, required this.senderId, this.type = MessageType.text, this.body = '', this.attachmentPath, this.attachmentUrl, required this.createdAt, this.readAt, this.sendState = SendState.sent, this.clientId});
  

@override final  String id;
@override final  String chatId;
@override final  String senderId;
@override@JsonKey() final  MessageType type;
@override@JsonKey() final  String body;
@override final  String? attachmentPath;
@override final  String? attachmentUrl;
@override final  DateTime createdAt;
@override final  DateTime? readAt;
@override@JsonKey() final  SendState sendState;
@override final  String? clientId;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.chatId, chatId) || other.chatId == chatId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.body, body) || other.body == body)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sendState, sendState) || other.sendState == sendState)&&(identical(other.clientId, clientId) || other.clientId == clientId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,chatId,senderId,type,body,attachmentPath,attachmentUrl,createdAt,readAt,sendState,clientId);
}

@override
String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, type: $type, body: $body, attachmentPath: $attachmentPath, attachmentUrl: $attachmentUrl, createdAt: $createdAt, readAt: $readAt, sendState: $sendState, clientId: $clientId)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String chatId, String senderId, MessageType type, String body, String? attachmentPath, String? attachmentUrl, DateTime createdAt, DateTime? readAt, SendState sendState, String? clientId
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? chatId = null,Object? senderId = null,Object? type = null,Object? body = null,Object? attachmentPath = freezed,Object? attachmentUrl = freezed,Object? createdAt = null,Object? readAt = freezed,Object? sendState = null,Object? clientId = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatId: null == chatId ? _self.chatId : chatId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sendState: null == sendState ? _self.sendState : sendState // ignore: cast_nullable_to_non_nullable
as SendState,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
