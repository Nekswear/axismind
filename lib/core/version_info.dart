/// Информация о версии приложения.
///
/// Версия автоматически читается из pubspec.yaml во время сборки.
/// Не редактируйте этот файл вручную — версия управляется через pubspec.yaml
/// и автоматически увеличивается скриптом build_release.ps1.
class VersionInfo {
  VersionInfo._();

  /// Версия приложения (должна совпадать с pubspec.yaml).
  /// Формат: major.minor.patch
  static const String version = '2.0.0';

  /// Номер сборки.
  static const int buildNumber = 6;

  /// Полная строка версии для отображения.
  static String get displayVersion => 'v$version+$buildNumber';

  /// Название приложения с версией.
  static String get appNameWithVersion => 'ZenBalance $displayVersion';
}
