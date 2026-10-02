// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FieldDef {

 String get key; FieldType get type; Map<String, String> get labels; List<FieldOption> get options; bool get required; String? get unit; bool? get quoteField;
/// Create a copy of FieldDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldDefCopyWith<FieldDef> get copyWith => _$FieldDefCopyWithImpl<FieldDef>(this as FieldDef, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FieldDef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldDef&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.labels, _this.labels)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.required, _this.required) || other.required == _this.required)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.quoteField, _this.quoteField) || other.quoteField == _this.quoteField));
}


@override
int get hashCode {
  final _this = this as FieldDef;
  return Object.hash(runtimeType,_this.key,_this.type,const DeepCollectionEquality().hash(_this.labels),const DeepCollectionEquality().hash(_this.options),_this.required,_this.unit,_this.quoteField);
}

@override
String toString() {
  final _this = this as FieldDef;
  return 'FieldDef(key: ${_this.key}, type: ${_this.type}, labels: ${_this.labels}, options: ${_this.options}, required: ${_this.required}, unit: ${_this.unit}, quoteField: ${_this.quoteField})';
}


}

/// @nodoc
abstract mixin class $FieldDefCopyWith<$Res>  {
  factory $FieldDefCopyWith(FieldDef value, $Res Function(FieldDef) _then) = _$FieldDefCopyWithImpl;
@useResult
$Res call({
 String key, FieldType type, Map<String, String> labels, List<FieldOption> options, bool required, String? unit, bool? quoteField
});




}
/// @nodoc
class _$FieldDefCopyWithImpl<$Res>
    implements $FieldDefCopyWith<$Res> {
  _$FieldDefCopyWithImpl(this._self, this._then);

  final FieldDef _self;
  final $Res Function(FieldDef) _then;

/// Create a copy of FieldDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? type = null,Object? labels = null,Object? options = null,Object? required = null,Object? unit = freezed,Object? quoteField = freezed,}) {
  return _then(FieldDef(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FieldType,labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<FieldOption>,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quoteField: freezed == quoteField ? _self.quoteField : quoteField // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldDef].
extension FieldDefPatterns on FieldDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldDef value)  $default,){
final _that = this;
switch (_that) {
case _FieldDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldDef value)?  $default,){
final _that = this;
switch (_that) {
case _FieldDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  FieldType type,  Map<String, String> labels,  List<FieldOption> options,  bool required,  String? unit,  bool? quoteField)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldDef() when $default != null:
return $default(_that.key,_that.type,_that.labels,_that.options,_that.required,_that.unit,_that.quoteField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  FieldType type,  Map<String, String> labels,  List<FieldOption> options,  bool required,  String? unit,  bool? quoteField)  $default,) {final _that = this;
switch (_that) {
case _FieldDef():
return $default(_that.key,_that.type,_that.labels,_that.options,_that.required,_that.unit,_that.quoteField);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  FieldType type,  Map<String, String> labels,  List<FieldOption> options,  bool required,  String? unit,  bool? quoteField)?  $default,) {final _that = this;
switch (_that) {
case _FieldDef() when $default != null:
return $default(_that.key,_that.type,_that.labels,_that.options,_that.required,_that.unit,_that.quoteField);case _:
  return null;

}
}

}

/// @nodoc


class _FieldDef extends FieldDef {
  const _FieldDef({required this.key, required this.type, required  Map<String, String> labels,  List<FieldOption> options = const [], this.required = false, this.unit, this.quoteField}): _labels = labels,_options = options,super._();
  

@override final  String key;
@override final  FieldType type;
 final  Map<String, String> _labels;
@override Map<String, String> get labels {
  if (_labels is EqualUnmodifiableMapView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_labels);
}

 final  List<FieldOption> _options;
@override@JsonKey() List<FieldOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  bool required;
@override final  String? unit;
@override final  bool? quoteField;

/// Create a copy of FieldDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldDefCopyWith<_FieldDef> get copyWith => __$FieldDefCopyWithImpl<_FieldDef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldDef&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.labels, _labels)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.required, required) || other.required == required)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quoteField, quoteField) || other.quoteField == quoteField));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,type,const DeepCollectionEquality().hash(_labels),const DeepCollectionEquality().hash(_options),required,unit,quoteField);
}

@override
String toString() {
    return 'FieldDef(key: $key, type: $type, labels: $labels, options: $options, required: $required, unit: $unit, quoteField: $quoteField)';
}


}

/// @nodoc
abstract mixin class _$FieldDefCopyWith<$Res> implements $FieldDefCopyWith<$Res> {
  factory _$FieldDefCopyWith(_FieldDef value, $Res Function(_FieldDef) _then) = __$FieldDefCopyWithImpl;
@override @useResult
$Res call({
 String key, FieldType type, Map<String, String> labels, List<FieldOption> options, bool required, String? unit, bool? quoteField
});




}
/// @nodoc
class __$FieldDefCopyWithImpl<$Res>
    implements _$FieldDefCopyWith<$Res> {
  __$FieldDefCopyWithImpl(this._self, this._then);

  final _FieldDef _self;
  final $Res Function(_FieldDef) _then;

/// Create a copy of FieldDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? type = null,Object? labels = null,Object? options = null,Object? required = null,Object? unit = freezed,Object? quoteField = freezed,}) {
  return _then(_FieldDef(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FieldType,labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<FieldOption>,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quoteField: freezed == quoteField ? _self.quoteField : quoteField // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$FieldOption {

 String get value; Map<String, String> get labels;
/// Create a copy of FieldOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldOptionCopyWith<FieldOption> get copyWith => _$FieldOptionCopyWithImpl<FieldOption>(this as FieldOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FieldOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldOption&&(identical(other.value, _this.value) || other.value == _this.value)&&const DeepCollectionEquality().equals(other.labels, _this.labels));
}


@override
int get hashCode {
  final _this = this as FieldOption;
  return Object.hash(runtimeType,_this.value,const DeepCollectionEquality().hash(_this.labels));
}

@override
String toString() {
  final _this = this as FieldOption;
  return 'FieldOption(value: ${_this.value}, labels: ${_this.labels})';
}


}

/// @nodoc
abstract mixin class $FieldOptionCopyWith<$Res>  {
  factory $FieldOptionCopyWith(FieldOption value, $Res Function(FieldOption) _then) = _$FieldOptionCopyWithImpl;
@useResult
$Res call({
 String value, Map<String, String> labels
});




}
/// @nodoc
class _$FieldOptionCopyWithImpl<$Res>
    implements $FieldOptionCopyWith<$Res> {
  _$FieldOptionCopyWithImpl(this._self, this._then);

  final FieldOption _self;
  final $Res Function(FieldOption) _then;

/// Create a copy of FieldOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? labels = null,}) {
  return _then(FieldOption(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldOption].
extension FieldOptionPatterns on FieldOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldOption value)  $default,){
final _that = this;
switch (_that) {
case _FieldOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldOption value)?  $default,){
final _that = this;
switch (_that) {
case _FieldOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  Map<String, String> labels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldOption() when $default != null:
return $default(_that.value,_that.labels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  Map<String, String> labels)  $default,) {final _that = this;
switch (_that) {
case _FieldOption():
return $default(_that.value,_that.labels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  Map<String, String> labels)?  $default,) {final _that = this;
switch (_that) {
case _FieldOption() when $default != null:
return $default(_that.value,_that.labels);case _:
  return null;

}
}

}

/// @nodoc


class _FieldOption extends FieldOption {
  const _FieldOption({required this.value, required  Map<String, String> labels}): _labels = labels,super._();
  

@override final  String value;
 final  Map<String, String> _labels;
@override Map<String, String> get labels {
  if (_labels is EqualUnmodifiableMapView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_labels);
}


/// Create a copy of FieldOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldOptionCopyWith<_FieldOption> get copyWith => __$FieldOptionCopyWithImpl<_FieldOption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldOption&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.labels, _labels));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value,const DeepCollectionEquality().hash(_labels));
}

@override
String toString() {
    return 'FieldOption(value: $value, labels: $labels)';
}


}

/// @nodoc
abstract mixin class _$FieldOptionCopyWith<$Res> implements $FieldOptionCopyWith<$Res> {
  factory _$FieldOptionCopyWith(_FieldOption value, $Res Function(_FieldOption) _then) = __$FieldOptionCopyWithImpl;
@override @useResult
$Res call({
 String value, Map<String, String> labels
});




}
/// @nodoc
class __$FieldOptionCopyWithImpl<$Res>
    implements _$FieldOptionCopyWith<$Res> {
  __$FieldOptionCopyWithImpl(this._self, this._then);

  final _FieldOption _self;
  final $Res Function(_FieldOption) _then;

/// Create a copy of FieldOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? labels = null,}) {
  return _then(_FieldOption(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc
mixin _$Category {

 int get id; int? get parentId; Map<String, String> get names; CategoryPolicy get policy; String? get requiredLicenceType; Map<String, String> get disclaimer; List<FieldDef> get fields; List<String> get keywords; String? get icon; int get sort;
/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCopyWith<Category> get copyWith => _$CategoryCopyWithImpl<Category>(this as Category, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Category;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Category&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&const DeepCollectionEquality().equals(other.names, _this.names)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.requiredLicenceType, _this.requiredLicenceType) || other.requiredLicenceType == _this.requiredLicenceType)&&const DeepCollectionEquality().equals(other.disclaimer, _this.disclaimer)&&const DeepCollectionEquality().equals(other.fields, _this.fields)&&const DeepCollectionEquality().equals(other.keywords, _this.keywords)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.sort, _this.sort) || other.sort == _this.sort));
}


@override
int get hashCode {
  final _this = this as Category;
  return Object.hash(runtimeType,_this.id,_this.parentId,const DeepCollectionEquality().hash(_this.names),_this.policy,_this.requiredLicenceType,const DeepCollectionEquality().hash(_this.disclaimer),const DeepCollectionEquality().hash(_this.fields),const DeepCollectionEquality().hash(_this.keywords),_this.icon,_this.sort);
}

@override
String toString() {
  final _this = this as Category;
  return 'Category(id: ${_this.id}, parentId: ${_this.parentId}, names: ${_this.names}, policy: ${_this.policy}, requiredLicenceType: ${_this.requiredLicenceType}, disclaimer: ${_this.disclaimer}, fields: ${_this.fields}, keywords: ${_this.keywords}, icon: ${_this.icon}, sort: ${_this.sort})';
}


}

/// @nodoc
abstract mixin class $CategoryCopyWith<$Res>  {
  factory $CategoryCopyWith(Category value, $Res Function(Category) _then) = _$CategoryCopyWithImpl;
@useResult
$Res call({
 int id, int? parentId, Map<String, String> names, CategoryPolicy policy, String? requiredLicenceType, Map<String, String> disclaimer, List<FieldDef> fields, List<String> keywords, String? icon, int sort
});




}
/// @nodoc
class _$CategoryCopyWithImpl<$Res>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._self, this._then);

  final Category _self;
  final $Res Function(Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = freezed,Object? names = null,Object? policy = null,Object? requiredLicenceType = freezed,Object? disclaimer = null,Object? fields = null,Object? keywords = null,Object? icon = freezed,Object? sort = null,}) {
  return _then(Category(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as Map<String, String>,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as CategoryPolicy,requiredLicenceType: freezed == requiredLicenceType ? _self.requiredLicenceType : requiredLicenceType // ignore: cast_nullable_to_non_nullable
as String?,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as Map<String, String>,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldDef>,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Category].
extension CategoryPatterns on Category {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Category value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Category value)  $default,){
final _that = this;
switch (_that) {
case _Category():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Category value)?  $default,){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? parentId,  Map<String, String> names,  CategoryPolicy policy,  String? requiredLicenceType,  Map<String, String> disclaimer,  List<FieldDef> fields,  List<String> keywords,  String? icon,  int sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.parentId,_that.names,_that.policy,_that.requiredLicenceType,_that.disclaimer,_that.fields,_that.keywords,_that.icon,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? parentId,  Map<String, String> names,  CategoryPolicy policy,  String? requiredLicenceType,  Map<String, String> disclaimer,  List<FieldDef> fields,  List<String> keywords,  String? icon,  int sort)  $default,) {final _that = this;
switch (_that) {
case _Category():
return $default(_that.id,_that.parentId,_that.names,_that.policy,_that.requiredLicenceType,_that.disclaimer,_that.fields,_that.keywords,_that.icon,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? parentId,  Map<String, String> names,  CategoryPolicy policy,  String? requiredLicenceType,  Map<String, String> disclaimer,  List<FieldDef> fields,  List<String> keywords,  String? icon,  int sort)?  $default,) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.parentId,_that.names,_that.policy,_that.requiredLicenceType,_that.disclaimer,_that.fields,_that.keywords,_that.icon,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _Category extends Category {
  const _Category({required this.id, this.parentId, required  Map<String, String> names, this.policy = CategoryPolicy.allowed, this.requiredLicenceType,  Map<String, String> disclaimer = const {},  List<FieldDef> fields = const [],  List<String> keywords = const [], this.icon, this.sort = 0}): _names = names,_disclaimer = disclaimer,_fields = fields,_keywords = keywords,super._();
  

@override final  int id;
@override final  int? parentId;
 final  Map<String, String> _names;
@override Map<String, String> get names {
  if (_names is EqualUnmodifiableMapView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_names);
}

@override@JsonKey() final  CategoryPolicy policy;
@override final  String? requiredLicenceType;
 final  Map<String, String> _disclaimer;
@override@JsonKey() Map<String, String> get disclaimer {
  if (_disclaimer is EqualUnmodifiableMapView) return _disclaimer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_disclaimer);
}

 final  List<FieldDef> _fields;
@override@JsonKey() List<FieldDef> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

@override final  String? icon;
@override@JsonKey() final  int sort;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCopyWith<_Category> get copyWith => __$CategoryCopyWithImpl<_Category>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Category&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&const DeepCollectionEquality().equals(other.names, _names)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.requiredLicenceType, requiredLicenceType) || other.requiredLicenceType == requiredLicenceType)&&const DeepCollectionEquality().equals(other.disclaimer, _disclaimer)&&const DeepCollectionEquality().equals(other.fields, _fields)&&const DeepCollectionEquality().equals(other.keywords, _keywords)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,parentId,const DeepCollectionEquality().hash(_names),policy,requiredLicenceType,const DeepCollectionEquality().hash(_disclaimer),const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_keywords),icon,sort);
}

@override
String toString() {
    return 'Category(id: $id, parentId: $parentId, names: $names, policy: $policy, requiredLicenceType: $requiredLicenceType, disclaimer: $disclaimer, fields: $fields, keywords: $keywords, icon: $icon, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$CategoryCopyWith<$Res> implements $CategoryCopyWith<$Res> {
  factory _$CategoryCopyWith(_Category value, $Res Function(_Category) _then) = __$CategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, int? parentId, Map<String, String> names, CategoryPolicy policy, String? requiredLicenceType, Map<String, String> disclaimer, List<FieldDef> fields, List<String> keywords, String? icon, int sort
});




}
/// @nodoc
class __$CategoryCopyWithImpl<$Res>
    implements _$CategoryCopyWith<$Res> {
  __$CategoryCopyWithImpl(this._self, this._then);

  final _Category _self;
  final $Res Function(_Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = freezed,Object? names = null,Object? policy = null,Object? requiredLicenceType = freezed,Object? disclaimer = null,Object? fields = null,Object? keywords = null,Object? icon = freezed,Object? sort = null,}) {
  return _then(_Category(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as Map<String, String>,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as CategoryPolicy,requiredLicenceType: freezed == requiredLicenceType ? _self.requiredLicenceType : requiredLicenceType // ignore: cast_nullable_to_non_nullable
as String?,disclaimer: null == disclaimer ? _self._disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as Map<String, String>,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FieldDef>,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
