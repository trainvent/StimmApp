import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser =>
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
}
