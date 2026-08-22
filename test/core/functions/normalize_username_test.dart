import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';

void main() {
  group('username length validation', () {
    test('uses the shared six-character minimum', () {
      expect(AppLimits.minUsernameLength, 6);
      expect(hasValidUsernameLength('abcde'), isFalse);
      expect(hasValidUsernameLength('abcdef'), isTrue);
    });

    test('validates the normalized value', () {
      expect(hasValidUsernameLength('  abcde  '), isFalse);
      expect(hasValidUsernameLength('  abcdef  '), isTrue);
    });
  });
}
