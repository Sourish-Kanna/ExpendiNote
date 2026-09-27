import 'package:expend_note/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants Tests', () {
    test(
      'appVersion returns pubspec fallback version when package info is not initialized',
      () {
        expect(AppConstants.appVersion, equals('2.0.1+1-dev'));
      },
    );

    test(
      'getAppVersion returns a non-empty version string asynchronously',
      () async {
        final version = await AppConstants.getAppVersion();
        expect(version, isNotEmpty);
        expect(AppConstants.appVersion, equals(version));
      },
    );
  });
}
