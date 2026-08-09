import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('group activities are append-only and actor-bound', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('match /activities/{activityId}'));
    expect(
      rules,
      contains('request.resource.data.actorUid == request.auth.uid'),
    );
    expect(rules, contains("'publication_published'"));
    expect(rules, contains('allow update: if false'));
    expect(
      rules,
      contains(
        '!existsAfter(/databases/\$(database)/documents/pollGroups/\$(groupId))',
      ),
    );
  });
}
