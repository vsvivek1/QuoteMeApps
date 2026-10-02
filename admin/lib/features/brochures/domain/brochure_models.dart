/// A generated brochure stored in the public `brochures` bucket.
class BrochureRecord {
  const BrochureRecord({
    required this.id,
    required this.cityName,
    this.state,
    this.categoryId,
    required this.language,
    required this.format,
    required this.storagePath,
    this.publicUrl,
    this.signupUrl,
    this.version = 1,
    required this.createdAt,
  });
  final String id;
  final String cityName;
  final String? state;
  final int? categoryId;
  final String language;

  /// pdf | image | onepager
  final String format;
  final String storagePath;
  final String? publicUrl;
  final String? signupUrl;
  final int version;
  final DateTime createdAt;
}

abstract interface class BrochureRepository {
  Future<List<BrochureRecord>> list();

  /// Uploads to Storage and records the row. Returns the stored record.
  Future<BrochureRecord> save({
    required String cityName,
    String? state,
    int? categoryId,
    required String categorySlug,
    required String language,
    required String format,
    required List<int> bytes,
    required String signupUrl,
    required Map<String, String> utm,
  });
}
