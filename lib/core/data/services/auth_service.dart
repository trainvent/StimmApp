import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';

final AuthService authService = AuthService();

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
    GoogleAuthClient? googleAuthClient,
  }) : _firebaseAuth = firebaseAuth,
       _functions = functions,
       _googleAuthClient = googleAuthClient ?? GoogleSignInClient();

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFunctions? _functions;
  final GoogleAuthClient _googleAuthClient;
  GoogleAuthClient get googleAuthClient => _googleAuthClient;

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

  bool get hasPasswordProvider {
    return currentUser?.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        ) ??
        false;
  }

  bool get hasGoogleProvider {
    return currentUser?.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        ) ??
        false;
  }

  bool get hasAppleProvider {
    return currentUser?.providerData.any(
          (provider) => provider.providerId == AppleAuthProvider.PROVIDER_ID,
        ) ??
        false;
  }

  AppleAuthProvider _appleProvider() {
    return AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
  }

  bool _isAppleCancellation(String code) {
    return const {
      'canceled',
      'cancelled',
      'popup-closed-by-user',
      'web-context-cancelled',
    }.contains(code);
  }

  AuthException _appleAuthException(FirebaseAuthException error) {
    if (_isAppleCancellation(error.code)) {
      return AuthException(
        FirebaseAuthException(
          code: 'apple-sign-in-cancelled',
          message: 'Apple sign-in was cancelled.',
        ),
      );
    }
    return AuthException(error);
  }

  Future<void> _assertFederatedSignupEligible(UserCredential result) async {
    if (!(result.additionalUserInfo?.isNewUser ?? false)) return;

    try {
      await assertSignupEligible(email: result.user?.email ?? '');
    } on AuthException {
      await result.user?.delete();
      await firebaseAuth.signOut();
      rethrow;
    }
  }

  Future<GoogleProfileData> importGoogleProfileData({
    bool promptIfNecessary = true,
  }) {
    return googleAuthClient.importProfileData(
      promptIfNecessary: promptIfNecessary,
    );
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

  Future<UserCredential> signInWithGoogle() async {
    try {
      late final UserCredential result;

      if (kIsWeb) {
        result = await firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleIdentity = await googleAuthClient.authenticate();
        final idToken = googleIdentity.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Google did not return a valid identity token.',
          );
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        result = await firebaseAuth.signInWithCredential(credential);
      }

      await _assertFederatedSignupEligible(result);
      return result;
    } on GoogleAuthCancelledException {
      throw AuthException(
        FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        ),
      );
    } on GoogleAuthClientException catch (e) {
      throw AuthException(
        FirebaseAuthException(
          code: 'google-sign-in-${e.code}',
          message: e.message ?? 'Google sign-in failed.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final provider = _appleProvider();
      final result = kIsWeb
          ? await firebaseAuth.signInWithPopup(provider)
          : await firebaseAuth.signInWithProvider(provider);
      await _assertFederatedSignupEligible(result);
      return result;
    } on FirebaseAuthException catch (e) {
      throw _appleAuthException(e);
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
      if (!kIsWeb) {
        await googleAuthClient.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } on GoogleAuthClientException catch (e) {
      debugPrint('Google session sign-out failed: ${e.code}: ${e.message}');
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

  Future<void> deleteAccountWithGoogle() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user was found.',
        ),
      );
    }

    try {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(GoogleAuthProvider());
      } else {
        final googleIdentity = await googleAuthClient.authenticate();
        final idToken = googleIdentity.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Google did not return a valid identity token.',
          );
        }
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      await UserRepository.create().delete(user.uid);
      await user.delete();
      await firebaseAuth.signOut();
      if (!kIsWeb) {
        await googleAuthClient.signOut();
      }
    } on GoogleAuthCancelledException {
      throw AuthException(
        FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        ),
      );
    } on GoogleAuthClientException catch (e) {
      throw AuthException(
        FirebaseAuthException(
          code: 'google-sign-in-${e.code}',
          message: e.message ?? 'Google sign-in failed.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> deleteAccountWithApple() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user was found.',
        ),
      );
    }

    try {
      final provider = _appleProvider();
      final credential = kIsWeb
          ? await user.reauthenticateWithPopup(provider)
          : await user.reauthenticateWithProvider(provider);

      if (!kIsWeb) {
        final authorizationCode =
            credential.additionalUserInfo?.authorizationCode;
        if (authorizationCode == null || authorizationCode.isEmpty) {
          throw FirebaseAuthException(
            code: 'missing-apple-authorization-code',
            message:
                'Apple did not return the authorization code required to '
                'revoke access.',
          );
        }
        await firebaseAuth.revokeTokenWithAuthorizationCode(authorizationCode);
      }

      await UserRepository.create().delete(user.uid);
      await user.delete();
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _appleAuthException(e);
    }
  }

  Future<void> deleteAccountWithFederatedProvider() async {
    if (hasAppleProvider) {
      return deleteAccountWithApple();
    }
    if (hasGoogleProvider) {
      return deleteAccountWithGoogle();
    }
    throw AuthException(
      FirebaseAuthException(
        code: 'unsupported-auth-provider',
        message: 'No supported sign-in provider was found for this account.',
      ),
    );
  }

  /// Deletes an account while its authentication session is still recent.
  ///
  /// This is used when a newly verified user cancels profile setup, before
  /// there is a completed profile that requires the normal reauthentication
  /// flow.
  Future<void> deleteCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user was found.',
        ),
      );
    }

    try {
      await user.delete();
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

  Future<void> sendEmailChangeCode({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      final currentEmail = currentUser?.email;
      if (currentEmail == null) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'Current user does not have an email address.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      final locale = PlatformDispatcher.instance.locale;
      await functions.httpsCallable('sendEmailChangeCode').call({
        'newEmail': newEmail.trim(),
        'locale': locale.languageCode,
        'countryCode': locale.countryCode,
      });
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('sendEmailChangeCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('sendEmailChangeCode', e, st);
      throw AuthException(e);
    } catch (e, st) {
      _logUnexpectedError('sendEmailChangeCode', e, st);
      rethrow;
    }
  }

  Future<void> verifyEmailChangeCode({
    required String newEmail,
    required String code,
    required String currentPassword,
  }) async {
    try {
      final result = await functions
          .httpsCallable('verifyEmailChangeCode')
          .call({'newEmail': newEmail.trim(), 'code': code});
      final token = result.data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await firebaseAuth.signInWithCustomToken(token);
      } else {
        await firebaseAuth.signInWithEmailAndPassword(
          email: newEmail.trim(),
          password: currentPassword,
        );
      }
      await currentUser?.reload();
      await currentUser?.getIdToken(true);
    } on FirebaseFunctionsException catch (e, st) {
      _logFirebaseFunctionsError('verifyEmailChangeCode', e, st);
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('verifyEmailChangeCode', e, st);
      throw AuthException(e);
    } catch (e, st) {
      _logUnexpectedError('verifyEmailChangeCode', e, st);
      rethrow;
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
