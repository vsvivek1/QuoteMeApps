import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

enum CategoryPolicy { allowed, restricted, blocked }

enum FieldType { text, number, select, multiselect, boolean, date }

/// One structured field from a leaf category's `field_schema`.
@freezed
abstract class FieldDef with _$FieldDef {
  const factory FieldDef({
    required String key,
    required FieldType type,
    required Map<String, String> labels,
    @Default([]) List<FieldOption> options,
    @Default(false) bool required,
    String? unit,
    bool? quoteField,
  }) = _FieldDef;

  const FieldDef._();

  String label(String lang) => labels[lang] ?? labels['en'] ?? key;

  static FieldDef fromJson(Map<String, dynamic> j) => FieldDef(
    key: j['key'] as String,
    type: FieldType.values.firstWhere((t) => t.name == j['type'], orElse: () => FieldType.text),
    labels: _strMap(j['labels'] ?? j['label']),
    options: [
      for (final o in (j['options'] as List? ?? const []))
        o is String
            ? FieldOption(value: o, labels: {'en': o})
            : FieldOption(value: (o as Map)['value'].toString(), labels: _strMap(o['labels'] ?? o['label'])),
    ],
    required: j['required'] == true,
    unit: j['unit'] as String?,
    quoteField: j['quote_field'] as bool?,
  );
}

@freezed
abstract class FieldOption with _$FieldOption {
  const factory FieldOption({required String value, required Map<String, String> labels}) = _FieldOption;

  const FieldOption._();

  String label(String lang) => labels[lang] ?? labels['en'] ?? value;
}

Map<String, String> _strMap(Object? v) {
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val.toString()));
  if (v is String) return {'en': v};
  return const {};
}

Map<String, String> parseLocalizedMap(Object? v) => _strMap(v);

/// Row in `categories`. Two levels: parentId == null for top level.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    int? parentId,
    required Map<String, String> names,
    @Default(CategoryPolicy.allowed) CategoryPolicy policy,
    String? requiredLicenceType,
    @Default({}) Map<String, String> disclaimer,
    @Default([]) List<FieldDef> fields,
    @Default([]) List<String> keywords,
    String? icon,
    @Default(0) int sort,
  }) = _Category;

  const Category._();

  String name(String lang) => names[lang] ?? names['en'] ?? '';
  String? disclaimerText(String lang) => disclaimer[lang] ?? disclaimer['en'];
  bool get isLeaf => parentId != null;
  bool get isBlocked => policy == CategoryPolicy.blocked;
  bool get isRestricted => policy == CategoryPolicy.restricted;
}
