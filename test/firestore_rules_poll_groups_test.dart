import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firestore.rules pollGroups coverage', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('covers allowedDomains writes', () {
      expect(rules, contains('match /allowedDomains/{allowedDomainId}'));
      expect(
        rules,
        contains(
          'allow create: if isAdmin() || isPollGroupCreatorAfter(groupId);',
        ),
      );
    });

    test('requires explicit private and invite flags on group create', () {
      expect(rules, contains('function isValidPollGroupCreate()'));
      expect(rules, contains("request.resource.data.accessMode is string"));
      expect(
        rules,
        contains("request.resource.data.inviteLinkEnabled is bool"),
      );
    });
  });
}
