import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';

final AuthService authService = AuthService();

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
  })  : _firebaseAuth = firebaseAuth,
        _functions = functions;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFunctions? _functions;

  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFunctions get functions => _functions ?? FirebaseFunctions.instance;

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
      final cred = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Instead of sending a link, we request a code via Cloud Functions
      await sendVerificationCode();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> assertSignupEligible({
    required String email,
  }) async {
    try {
      await functions.httpsCallable('assertSignupEligible').call({
        'email': email.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
    }
  }

  Future<void> updateUsername({required String username}) async {
    try {
      await currentUser!.updateDisplayName(username);
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
      await functions.httpsCallable('sendVerificationCode').call();
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    }
  }

  Future<void> verifyCode(String code) async {
    try {
      await functions.httpsCallable('verifyCode').call({'code': code});
      // Reload user to update emailVerified status
      await currentUser?.reload();
      // Force refresh the token to ensure all claims are updated
      await currentUser?.getIdToken(true);
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    }
  }

  // --- Login with Code Methods ---

  Future<void> sendLoginCode(String email) async {
    try {
      await functions.httpsCallable('sendLoginCode').call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
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
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        FirebaseAuthException(code: e.code, message: e.message),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e);
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
