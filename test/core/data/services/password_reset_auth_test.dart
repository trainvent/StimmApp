import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class _PrimaryAuth extends Mock implements FirebaseAuth {}

class _Result<T> extends Mock implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _VerifyCode extends Mock implements HttpsCallable {
  dynamic parameters;
  FirebaseFunctionsException? error;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    this.parameters = parameters;
    if (error != null) throw error!;
    return _Result<T>({'token': 'recovery-token'} as T);
  }
}

class _Functions extends Mock implements FirebaseFunctions {
  final verify = _VerifyCode();

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    expect(name, 'verifyLoginCode');
    return verify;
  }
}

void main() {
  test(
    'reset verification returns a token without touching primary auth',
    () async {
      final primary = _PrimaryAuth();
      final functions = _Functions();
      final service = AuthService(firebaseAuth: primary, functions: functions);

      expect(
        await service.verifyPasswordResetCode('test@example.com', '123456'),
        'recovery-token',
      );
      expect(functions.verify.parameters, {
        'email': 'test@example.com',
        'code': '123456',
      });
      verifyZeroInteractions(primary);
    },
  );

  test('rejected reset codes never sign in the primary instance', () async {
    final primary = _PrimaryAuth();
    final functions = _Functions();
    functions.verify.error = FirebaseFunctionsException(
      code: 'invalid-argument',
      message: 'Invalid code',
    );
    final service = AuthService(firebaseAuth: primary, functions: functions);

    await expectLater(
      service.verifyPasswordResetCode('test@example.com', '000000'),
      throwsA(isA<AuthException>()),
    );
    verifyZeroInteractions(primary);
  });
}
