import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firestore.rules questionnaireGroups coverage', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('covers allowedDomains writes', () {
      expect(rules, contains('match /allowedDomains/{allowedDomainId}'));
      expect(
        rules,
        contains(
          'allow create: if isAdmin() || isQuestionnaireGroupCreatorAfter(groupId) || isQuestionnaireGroupAdmin(groupId);',
        ),
      );
    });

    test('blocks direct group creation outside admins', () {
      expect(rules, contains('match /pollGroups/{groupId} {'));
      expect(rules, contains('allow create: if isAdmin();'));
    });

    test('allows owner and admin group picture updates', () {
      expect(rules, contains('function hasValidGroupPictureUpdate(groupId)'));
      expect(rules, contains("hasOnly(['profilePictureUrl'])"));
      expect(rules, contains('hasValidGroupPictureUpdate(groupId)'));
    });
  });
}
