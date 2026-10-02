/// A row of `app_settings`: remote flags and limits, per country project.
class AppSetting {
  const AppSetting({required this.key, required this.value, this.description, this.isPublic = false});
  final String key;

  /// Decoded JSON value (bool, num, String or null).
  final Object? value;
  final String? description;

  /// Public settings are readable by the apps (and mirrored to Remote Config).
  final bool isPublic;

  AppSetting withValue(Object? v) =>
      AppSetting(key: key, value: v, description: description, isPublic: isPublic);
}

abstract interface class SettingsRepository {
  Future<List<AppSetting>> list();

  /// `admin_set_setting(key, value)`; the server validates types and ranges.
  Future<AppSetting> set(String key, Object? value);
}
