import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static String _cachedVersion = '2.0.1+1-dev';
  static PackageInfo? _packageInfo;

  /// Returns the current app version string (including build number if available, e.g. '2.0.1+1-dev').
  static String get appVersion {
    if (_packageInfo != null) {
      final v = _packageInfo!.version;
      final b = _packageInfo!.buildNumber;
      if (b.isNotEmpty && !v.contains('+')) {
        return '$v+$b';
      }
      return v;
    }
    return _cachedVersion;
  }

  /// Returns the underlying [PackageInfo] instance if loaded.
  static PackageInfo? get packageInfo => _packageInfo;

  /// Asynchronously retrieves the latest app version using package_info_plus.
  static Future<String> getAppVersion() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      final v = _packageInfo!.version;
      final b = _packageInfo!.buildNumber;
      if (b.isNotEmpty && !v.contains('+')) {
        _cachedVersion = '$v+$b';
      } else {
        _cachedVersion = v;
      }
      return _cachedVersion;
    } catch (_) {
      return _cachedVersion;
    }
  }

  /// Initializes AppConstants asynchronously (e.g. during app startup).
  static Future<void> init() async {
    await getAppVersion();
  }
}

class ExportConstants {
  static const String backupFormatName = 'ExpendiNote Backup';
  static const int currentExportVersion = 1;
}
