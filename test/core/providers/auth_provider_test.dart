import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

class _TestUser extends Mock implements User {
  _TestUser({required this.verified, required this.providers});

  final bool verified;
  final List<UserInfo> providers;

  @override
  bool get emailVerified => verified;

  @override
  List<UserInfo> get providerData => providers;
}

class _TestUserInfo extends Mock implements UserInfo {
  _TestUserInfo(this.id);

  final String id;

  @override
  String get providerId => id;
}

void main() {
  group('requiresEmailVerification', () {
    test('requires verification for an unverified password account', () {
      final user = _TestUser(
        verified: false,
        providers: [_TestUserInfo(EmailAuthProvider.PROVIDER_ID)],
      );

      expect(requiresEmailVerification(user), isTrue);
    });

    test('does not require verification for a verified account', () {
      final user = _TestUser(
        verified: true,
        providers: [_TestUserInfo(EmailAuthProvider.PROVIDER_ID)],
      );

      expect(requiresEmailVerification(user), isFalse);
    });

    test('does not require custom verification for a Google account', () {
      final user = _TestUser(
        verified: false,
        providers: [_TestUserInfo(GoogleAuthProvider.PROVIDER_ID)],
      );

      expect(requiresEmailVerification(user), isFalse);
    });

    test('does not require custom verification for an Apple account', () {
      final user = _TestUser(
        verified: false,
        providers: [_TestUserInfo(AppleAuthProvider.PROVIDER_ID)],
      );

      expect(requiresEmailVerification(user), isFalse);
    });
  });
}
