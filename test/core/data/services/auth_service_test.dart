import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

void main() {
  group('AuthService without Firebase initialization', () {
    test('currentUser returns null instead of throwing', () {
      expect(() => authService.currentUser, returnsNormally);
      expect(authService.currentUser, isNull);
    });

    test('authStateChanges returns a safe stream', () async {
      expect(() => authService.authStateChanges, returnsNormally);
      await expectLater(authService.authStateChanges, emits(null));
    });
  });
}
