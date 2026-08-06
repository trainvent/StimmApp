import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {
  _MockFirebaseAuth([this.user]);

  final User? user;

  @override
  User? get currentUser =>
      user ??
      super.noSuchMethod(Invocation.getter(#currentUser), returnValue: null)
          as User?;

  @override
  Future<void> signOut() =>
      super.noSuchMethod(
            Invocation.method(#signOut, []),
            returnValue: Future<void>.value(),
          )
          as Future<void>;
}

class _MockUser extends Mock implements User {
  @override
  Future<void> delete() =>
      super.noSuchMethod(
            Invocation.method(#delete, []),
            returnValue: Future<void>.value(),
          )
          as Future<void>;
}

class _GoogleUserInfo extends Mock implements UserInfo {
  _GoogleUserInfo({required this.googleId, required this.googleEmail});

  final String googleId;
  final String googleEmail;

  @override
  String get providerId => GoogleAuthProvider.PROVIDER_ID;

  @override
  String? get uid => googleId;

  @override
  String? get email => googleEmail;
}

class _GoogleUser extends Mock implements User {
  _GoogleUser({this.primaryEmail, required this.googleProvider});

  final String? primaryEmail;
  final UserInfo googleProvider;

  @override
  String? get email => primaryEmail;

  @override
  List<UserInfo> get providerData => [googleProvider];
}

class _GoogleReauthUser extends _GoogleUser {
  _GoogleReauthUser({
    required super.primaryEmail,
    required super.googleProvider,
    required this.error,
  });

  final FirebaseAuthException error;
  AuthProvider? receivedProvider;

  @override
  String get uid => 'firebase-user-id';

  @override
  Future<UserCredential> reauthenticateWithProvider(
    AuthProvider provider,
  ) async {
    receivedProvider = provider;
    throw error;
  }
}

class _MockUserCredential extends Mock implements UserCredential {
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}

class _GoogleFirebaseAuth extends Mock implements FirebaseAuth {
  _GoogleFirebaseAuth(this.result, {this.error});

  final UserCredential result;
  final FirebaseAuthException? error;
  AuthCredential? receivedCredential;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    receivedCredential = credential;
    if (error case final error?) throw error;
    return result;
  }
}

class _AppleFirebaseAuth extends Mock implements FirebaseAuth {
  _AppleFirebaseAuth({required this.result, this.error});

  final UserCredential result;
  final FirebaseAuthException? error;
  AuthProvider? receivedProvider;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    receivedProvider = provider;
    if (error case final error?) throw error;
    return result;
  }
}

class _FakeGoogleAuthClient implements GoogleAuthClient {
  _FakeGoogleAuthClient({this.error});

  final Object? error;
  GoogleAccountReference? receivedAccount;

  @override
  Future<GoogleAuthIdentity> authenticate() async {
    if (error case final error?) throw error;
    return const GoogleAuthIdentity(
      email: 'person@example.com',
      idToken: 'google-id-token',
    );
  }

  @override
  Future<GoogleProfileData> importProfileData({
    bool promptIfNecessary = true,
    GoogleAccountReference? account,
  }) async {
    receivedAccount = account;
    return const GoogleProfileData();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  test('updateUsername rejects fewer than four characters before Firebase', () {
    final service = AuthService(firebaseAuth: _MockFirebaseAuth());

    expect(
      () => service.updateUsername(username: 'abc'),
      throwsA(isA<StateError>()),
    );
  });

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

  group('deleteCurrentUser', () {
    test('deletes the authenticated user and signs out', () async {
      final firebaseAuth = _MockFirebaseAuth();
      final user = _MockUser();
      final service = AuthService(firebaseAuth: firebaseAuth);

      when(firebaseAuth.currentUser).thenReturn(user);
      when(user.delete()).thenAnswer((_) async {});
      when(firebaseAuth.signOut()).thenAnswer((_) async {});

      await service.deleteCurrentUser();

      verify(user.delete()).called(1);
      verify(firebaseAuth.signOut()).called(1);
    });

    test('throws an AuthException when no user is authenticated', () async {
      final firebaseAuth = _MockFirebaseAuth();
      final service = AuthService(firebaseAuth: firebaseAuth);

      when(firebaseAuth.currentUser).thenReturn(null);

      await expectLater(
        service.deleteCurrentUser(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });
  });

  group('signInWithGoogle', () {
    test('exchanges the Google ID token for a Firebase credential', () async {
      final expectedResult = _MockUserCredential();
      final firebaseAuth = _GoogleFirebaseAuth(expectedResult);
      final service = AuthService(
        firebaseAuth: firebaseAuth,
        googleAuthClient: _FakeGoogleAuthClient(),
      );

      final result = await service.signInWithGoogle();

      expect(result, same(expectedResult));
      expect(firebaseAuth.receivedCredential, isA<OAuthCredential>());
    });

    test('maps user cancellation to a non-fatal auth code', () async {
      final service = AuthService(
        firebaseAuth: _GoogleFirebaseAuth(_MockUserCredential()),
        googleAuthClient: _FakeGoogleAuthClient(
          error: const GoogleAuthCancelledException(),
        ),
      );

      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'google-sign-in-cancelled',
          ),
        ),
      );
    });

    test('maps a closed Firebase popup to the cancellation code', () async {
      final service = AuthService(
        firebaseAuth: _GoogleFirebaseAuth(
          _MockUserCredential(),
          error: FirebaseAuthException(code: 'popup-closed-by-user'),
        ),
        googleAuthClient: _FakeGoogleAuthClient(),
      );

      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'google-sign-in-cancelled',
          ),
        ),
      );
    });
  });

  group('linked Google account', () {
    test('uses provider data to bind profile imports after restart', () async {
      final googleClient = _FakeGoogleAuthClient();
      final provider = _GoogleUserInfo(
        googleId: 'google-user-id',
        googleEmail: 'person@example.com',
      );
      final service = AuthService(
        firebaseAuth: _MockFirebaseAuth(
          _GoogleUser(primaryEmail: null, googleProvider: provider),
        ),
        googleAuthClient: googleClient,
      );

      await service.importGoogleProfileData(promptIfNecessary: false);

      expect(googleClient.receivedAccount?.id, 'google-user-id');
      expect(googleClient.receivedAccount?.email, 'person@example.com');
    });

    test('falls back to the Google provider email', () {
      final provider = _GoogleUserInfo(
        googleId: 'google-user-id',
        googleEmail: 'person@example.com',
      );
      final service = AuthService(
        firebaseAuth: _MockFirebaseAuth(
          _GoogleUser(primaryEmail: null, googleProvider: provider),
        ),
      );

      expect(service.authenticatedEmail, 'person@example.com');
    });

    test(
      'uses the linked email as the deletion reauthentication hint',
      () async {
        final providerInfo = _GoogleUserInfo(
          googleId: 'google-user-id',
          googleEmail: 'person@example.com',
        );
        final user = _GoogleReauthUser(
          primaryEmail: 'person@example.com',
          googleProvider: providerInfo,
          error: FirebaseAuthException(code: 'canceled'),
        );
        final service = AuthService(firebaseAuth: _MockFirebaseAuth(user));

        await expectLater(
          service.deleteAccountWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (error) => error.code,
              'code',
              'google-sign-in-cancelled',
            ),
          ),
        );

        final provider = user.receivedProvider as GoogleAuthProvider;
        expect(provider.parameters['login_hint'], 'person@example.com');
      },
    );
  });

  group('signInWithApple', () {
    test('uses the native Apple provider with email and name scopes', () async {
      final expectedResult = _MockUserCredential();
      final firebaseAuth = _AppleFirebaseAuth(result: expectedResult);
      final service = AuthService(firebaseAuth: firebaseAuth);

      final result = await service.signInWithApple();

      expect(result, same(expectedResult));
      final provider = firebaseAuth.receivedProvider;
      expect(provider, isA<AppleAuthProvider>());
      expect(
        (provider! as AppleAuthProvider).scopes,
        containsAll(['email', 'name']),
      );
    });

    test('maps user cancellation to a non-fatal auth code', () async {
      final service = AuthService(
        firebaseAuth: _AppleFirebaseAuth(
          result: _MockUserCredential(),
          error: FirebaseAuthException(code: 'canceled'),
        ),
      );

      await expectLater(
        service.signInWithApple(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'apple-sign-in-cancelled',
          ),
        ),
      );
    });
  });
}
