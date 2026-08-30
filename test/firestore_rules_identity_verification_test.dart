import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore rules protect server-issued PID verification evidence', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('hasSafeVerificationOnCreate()'));
    expect(rules, contains('hasValidOwnerVerificationUpdate()'));
    expect(rules, contains("'identityVerificationValidUntil'"));
    expect(rules, contains("'identityVerificationPolicyVersion'"));
    expect(rules, contains("'verifiedIdentityRevision'"));
    expect(
      rules,
      contains(
        'request.resource.data.identityRevision == '
        'currentIdentityRevision() + 1',
      ),
    );
    expect(rules, contains('request.resource.data.isVerified == false'));
  });
}
