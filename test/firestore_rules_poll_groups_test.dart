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
          'allow create: if isAdmin() || isPollGroupCreatorAfter(groupId) || isPollGroupAdmin(groupId);',
        ),
      );
    });

    test('blocks direct group creation outside admins', () {
      expect(rules, contains('match /pollGroups/{groupId} {'));
      expect(rules, contains('allow create: if isAdmin();'));
    });
  });
}
