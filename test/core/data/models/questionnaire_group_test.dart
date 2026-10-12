import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';

void main() {
  group('QuestionnaireGroup', () {
    final timestamp = Timestamp.fromDate(DateTime(2024, 1, 2));
    final group = QuestionnaireGroup(
      id: 'group-1',
      name: 'Team Pulse',
      createdBy: 'owner',
      createdAt: timestamp.toDate(),
      joinCode: 'GRP-123456',
      nicknameMode: QuestionnaireGroupNicknameMode.selfNamed,
      managersCanInvite: true,
      memberIds: const ['owner'],
      importedMemberCount: 2,
      isActive: true,
      accessMode: QuestionnaireGroupAccessMode.protected,
      inviteLinkEnabled: true,
    );

    test('serializes invite and privacy fields', () {
      final result = QuestionnaireGroup.toFirestore(group, null);

      expect(result['accessMode'], 'protected');
      expect(result['inviteLinkEnabled'], isTrue);
      expect(result['importedMemberCount'], 2);
    });

    test(
      'picture URL round trips, remains optional, and can be removed',
      () async {
        const url = 'https://example.test/group.png';
        final withPicture = group.copyWith(profilePictureUrl: url);
        final firestore = FakeFirebaseFirestore();
        final ref = firestore.collection('pollGroups').doc(group.id);
        await ref.set(QuestionnaireGroup.toFirestore(withPicture, null));
        final loaded = QuestionnaireGroup.fromFirestore(await ref.get(), null);
        expect(loaded.profilePictureUrl, url);
        expect(loaded.copyWith(name: 'Renamed').profilePictureUrl, url);
        expect(
          loaded.copyWith(profilePictureUrl: null).profilePictureUrl,
          isNull,
        );
        expect(group.profilePictureUrl, isNull);
      },
    );

    test('deserializes invite and privacy fields', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = await firestore.collection('pollGroups').add({
        'name': 'Team Pulse',
        'createdBy': 'owner',
        'createdAt': timestamp,
        'joinCode': 'GRP-123456',
        'nicknameMode': 'self_named',
        'managersCanInvite': true,
        'memberIds': ['owner'],
        'importedMemberCount': 2,
        'isActive': true,
        'accessMode': 'protected',
        'inviteLinkEnabled': true,
      });

      final result = QuestionnaireGroup.fromFirestore(await ref.get(), null);

      expect(result.accessMode, QuestionnaireGroupAccessMode.protected);
      expect(result.inviteLinkEnabled, isTrue);
      expect(result.importedMemberCount, 2);
    });
  });

  group('QuestionnaireGroupAllowedDomain', () {
    test('serializes and deserializes domain rules', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore
          .collection('pollGroups')
          .doc('group-1')
          .collection('allowedDomains')
          .doc('company.com');
      final domain = QuestionnaireGroupAllowedDomain(
        domain: 'company.com',
        role: QuestionnaireGroupRole.manager,
        createdAt: DateTime(2024, 1, 2),
        createdBy: 'owner',
      );

      await ref.set(QuestionnaireGroupAllowedDomain.toFirestore(domain, null));
      final result = QuestionnaireGroupAllowedDomain.fromFirestore(
        await ref.get(),
        null,
      );

      expect(result.domain, 'company.com');
      expect(result.role, QuestionnaireGroupRole.manager);
      expect(result.createdBy, 'owner');
    });
  });
}
