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

  test('Firestore rules require current PID verification for petitions', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('hasCurrentPidVerification()'));
    expect(
      rules,
      contains("identityVerificationPolicyVersion == 'pid-profile-v1'"),
    );
    expect(rules, contains('identityVerificationValidUntil > request.time'));
    expect(
      rules,
      contains(
        'allow create, update: if isAdmin() ||\n'
        '                              (isOwner(userId) && '
        'hasCurrentPidVerification());',
      ),
    );
    expect(
      rules,
      contains(
        'allow create: if isAdmin() ||\n'
        '                    (hasCurrentPidVerification() &&',
      ),
    );
    expect(
      rules,
      contains('request.resource.data.createdBy == request.auth.uid'),
    );
    expect(rules, contains('match /signatures/{signerId}'));
    expect(
      rules,
      contains(
        r'!exists(/databases/$(database)/documents/petitions/'
        r'$(petitionId)/signatures/$(request.auth.uid))',
      ),
    );
    expect(
      rules,
      contains(
        r'existsAfter(/databases/$(database)/documents/petitions/'
        r'$(petitionId)/signatures/$(request.auth.uid))',
      ),
    );
    expect(rules, contains("!(subcollection in ["));
    expect(rules, contains("'signedPetitions',"));
  });
}
