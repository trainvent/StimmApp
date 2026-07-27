import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthIdentity {
  const GoogleAuthIdentity({required this.email, required this.idToken});

  final String email;
  final String? idToken;
}

abstract interface class GoogleAuthClient {
  Future<GoogleAuthIdentity> authenticate();

  Future<void> signOut();
}

class GoogleSignInClient implements GoogleAuthClient {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize();
  }

  @override
  Future<GoogleAuthIdentity> authenticate() async {
    await _initialize();
    try {
      final account = await _googleSignIn.authenticate();
      return GoogleAuthIdentity(
        email: account.email,
        idToken: account.authentication.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleAuthCancelledException();
      }
      throw GoogleAuthClientException(
        code: e.code.name,
        message: e.description,
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (e) {
      throw GoogleAuthClientException(
        code: e.code.name,
        message: e.description,
      );
    }
  }
}

class GoogleAuthCancelledException implements Exception {
  const GoogleAuthCancelledException();
}

class GoogleAuthClientException implements Exception {
  const GoogleAuthClientException({required this.code, this.message});

  final String code;
  final String? message;
}
