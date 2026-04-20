import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';

final AuthService authService = AuthService();

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFunctions? functions})
    : _firebaseAuth = firebaseAuth,
      _functions = functions;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFunctions? _functions;

  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFunctions get functions => _functions ?? FirebaseFunctions.instance;

  void _logFirebaseAuthError(
    String action,
    FirebaseAuthException error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      'AuthService.$action FirebaseAuthException '
      '(code: ${error.code}, message: ${error.message}, email: ${error.email}, '
      'credential: ${error.credential != null})',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  void _logFirebaseFunctionsError(
    String action,
    FirebaseFunctionsException error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      'AuthService.$action FirebaseFunctionsException '
      '(code: ${error.code}, message: ${error.message}, details: ${error.details})',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  void _logUnexpectedError(String action, Object error, StackTrace stackTrace) {
    debugPrint('AuthService.$action unexpected error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Widget tests often exercise UI without Firebase initialization.
  // In that case we degrade to an anonymous state instead of crashing.
  User? get currentUser {
    try {
      return firebaseAuth.currentUser;
    } on Exception {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return firebaseAuth.authStateChanges();
    } on Exception {
      return Stream<User?>.value(null);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      await assertSignupEligible(email: email);
      return await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> assertSignupEligible({required String email}) async {
    try {
      await functions.httpsCallable('assertSignupEligible').call({
        'email': email.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      // The ban check should only block signup when the backend explicitly
      // denies the email. Missing/unavailable/internal callable failures should
      // not prevent account creation.
      if (e.code == 'permission-denied') {
        throw AuthException(
          FirebaseAuthException(code: e.code, message: e.message),
        );
      }
      debugPrint(
        'assertSignupEligible skipped due to backend error '
        '(code: ${e.code}, message: ${e.message})',
      );
      return;
    } catch (e) {
      debugPrint('assertSignupEligible skipped due to unexpected error: $e');
      return;
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('resetPassword', e, st);
      throw AuthException(e);
    } catch (e, st) {
      _logUnexpectedError('resetPassword', e, st);
      rethrow;
    }
  }

  Future<void> updateUsername({required String username}) async {
    final normalized = username.trim();
    final clamped = normalized.length > AppLimits.maxDisplayNameLength
        ? normalized.substring(0, AppLimits.maxDisplayNameLength)
        : normalized;
    try {
      await currentUser!.updateDisplayName(clamped);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final uid = currentUser?.uid;
      await currentUser!.reauthenticateWithCredential(credential);
      if (uid != null) {
        await UserRepository.create().delete(uid);
      }
      await currentUser!.delete();
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> resetPasswordfromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> setSettings({
    bool appVerificationDisabledForTesting = false,
  }) async {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: appVerificationDisabledForTesting,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  // --- New Code Verification Methods ---

  Future<void> sendVerificationCode() async {
    try {
      final locale = PlatformDispatcher.instance.locale;
      await functions.httpsCallable('sendVerificationCode').call({
        'locale': locale.languageCode,
        'countryCode': locale.countryCode,
      });
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('sendVerificationCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } catch (e, st) {
      _logUnexpectedError('sendVerificationCode', e, st);
      rethrow;
    }
  }

  Future<void> verifyCode(String code) async {
    try {
      await functions.httpsCallable('verifyCode').call({'code': code});
      // Reload user to update emailVerified status
      await currentUser?.reload();
      // Force refresh the token to ensure all claims are updated
      await currentUser?.getIdToken(true);
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('verifyCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } catch (e, st) {
      _logUnexpectedError('verifyCode', e, st);
      rethrow;
    }
  }

  // --- Login with Code Methods ---

  Future<void> sendLoginCode(String email) async {
    try {
      final locale = PlatformDispatcher.instance.locale;
      await functions.httpsCallable('sendLoginCode').call({
        'email': email,
        'locale': locale.languageCode,
        'countryCode': locale.countryCode,
      });
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('sendLoginCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } catch (e, st) {
      _logUnexpectedError('sendLoginCode', e, st);
      rethrow;
    }
  }

  Future<UserCredential> signInWithCode(String email, String code) async {
    try {
      final result = await functions.httpsCallable('verifyLoginCode').call({
        'email': email,
        'code': code,
      });
      final token = result.data['token'] as String;
      return await firebaseAuth.signInWithCustomToken(token);
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('signInWithCode.verifyLoginCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('signInWithCode.signInWithCustomToken', e, st);
      throw AuthException(e);
    } catch (e, st) {
      _logUnexpectedError('signInWithCode', e, st);
      rethrow;
    }
  }
}

class AuthException implements Exception {
  final FirebaseAuthException firebaseAuthException;

  AuthException(this.firebaseAuthException);

  String? get message => firebaseAuthException.message;
  String get code => firebaseAuthException.code;

  @override
  String toString() {
    return 'AuthException (code: $code): $message';
  }
}
