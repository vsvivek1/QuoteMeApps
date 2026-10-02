/// allowed | restricted (licensed sellers only) | blocked (Section 3.1).
enum CategoryPolicy { allowed, restricted, blocked }

class AdminCategory {
  const AdminCategory({
    required this.id,
    this.parentId,
    required this.slug,
    required this.names,
    required this.policy,
    this.requiredLicenceType,
    this.disclaimer = const {},
    this.policyReason = const {},
    this.active = true,
    this.sort = 0,
  });

  final int id;
  final int? parentId;
  final String slug;

  /// {en, hi, es, ...}
  final Map<String, String> names;
  final CategoryPolicy policy;
  final String? requiredLicenceType;
  final Map<String, String> disclaimer;
  final Map<String, String> policyReason;
  final bool active;
  final int sort;

  String name([String lang = 'en']) => names[lang] ?? names['en'] ?? slug;

  AdminCategory copyWith({
    CategoryPolicy? policy,
    String? requiredLicenceType,
    Map<String, String>? disclaimer,
    Map<String, String>? policyReason,
    Map<String, String>? names,
    bool? active,
  }) =>
      AdminCategory(
        id: id,
        parentId: parentId,
        slug: slug,
        names: names ?? this.names,
        policy: policy ?? this.policy,
        requiredLicenceType: requiredLicenceType ?? this.requiredLicenceType,
        disclaimer: disclaimer ?? this.disclaimer,
        policyReason: policyReason ?? this.policyReason,
        active: active ?? this.active,
        sort: sort,
      );
}

abstract interface class CategoryAdminRepository {
  Future<List<AdminCategory>> list();

  /// `admin_set_category_policy`. Restricted requires a licence type.
  Future<AdminCategory> setPolicy(
    int categoryId,
    CategoryPolicy policy, {
    String? requiredLicenceType,
    Map<String, String>? disclaimer,
    Map<String, String>? policyReason,
  });

  /// `admin_upsert_category` (names, active flag).
  Future<AdminCategory> update(int categoryId, {Map<String, String>? names, bool? active});
}
