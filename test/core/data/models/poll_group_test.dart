import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';

void main() {
  group('PollGroup', () {
    final timestamp = Timestamp.fromDate(DateTime(2024, 1, 2));
    final group = PollGroup(
      id: 'group-1',
      name: 'Team Pulse',
      createdBy: 'owner',
      createdAt: timestamp.toDate(),
      joinCode: 'GRP-123456',
      nicknameMode: PollGroupNicknameMode.selfNamed,
      managersCanInvite: true,
      memberIds: const ['owner'],
      importedMemberCount: 2,
      isActive: true,
      accessMode: PollGroupAccessMode.protected,
      inviteLinkEnabled: true,
      inviteLinkToken: 'invite-token',
    );

    test('serializes invite and privacy fields', () {
      final result = PollGroup.toFirestore(group, null);

      expect(result['accessMode'], 'protected');
      expect(result['inviteLinkEnabled'], isTrue);
      expect(result['inviteLinkToken'], 'invite-token');
      expect(result['importedMemberCount'], 2);
    });

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
        'inviteLinkToken': 'invite-token',
      });

      final result = PollGroup.fromFirestore(await ref.get(), null);

      expect(result.accessMode, PollGroupAccessMode.protected);
      expect(result.inviteLinkEnabled, isTrue);
      expect(result.inviteLinkToken, 'invite-token');
      expect(result.importedMemberCount, 2);
    });
  });

  group('PollGroupAllowedDomain', () {
    test('serializes and deserializes domain rules', () async {
      final firestore = FakeFirebaseFirestore();
      final ref = firestore
          .collection('pollGroups')
          .doc('group-1')
          .collection('allowedDomains')
          .doc('company.com');
      final domain = PollGroupAllowedDomain(
        domain: 'company.com',
        role: PollGroupRole.manager,
        createdAt: DateTime(2024, 1, 2),
        createdBy: 'owner',
      );

      await ref.set(PollGroupAllowedDomain.toFirestore(domain, null));
      final result = PollGroupAllowedDomain.fromFirestore(
        await ref.get(),
        null,
      );

      expect(result.domain, 'company.com');
      expect(result.role, PollGroupRole.manager);
      expect(result.createdBy, 'owner');
    });
  });
}
