import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PollGroupRepository repository;
  late PollGroup group;
  late PollGroupMember member;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = PollGroupRepository(DatabaseService(firestore));
    group = PollGroup(
      id: 'group-1',
      name: 'Operations',
      createdBy: 'owner',
      createdAt: DateTime(2026, 1, 1),
      joinCode: 'OPS-1',
      nicknameMode: PollGroupNicknameMode.adminAssigned,
      managersCanInvite: true,
      memberIds: const ['owner', 'member'],
      importedMemberCount: 1,
    );
    member = PollGroupMember(
      uid: 'member',
      role: PollGroupRole.user,
      nickname: 'Old name',
      joinedAt: DateTime(2026, 1, 2),
      joinedBy: 'owner',
    );
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .set(PollGroup.toFirestore(group, null));
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('members')
        .doc(member.uid)
        .set(PollGroupMember.toFirestore(member, null));
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('allowedMembers')
        .doc('member@example.com')
        .set({
          'email': 'member@example.com',
          'nickname': 'Old name',
          'role': 'user',
          'createdAt': DateTime(2026, 1, 1),
          'createdBy': 'owner',
        });
  });

  test(
    'updates a member nickname and role including prepared access',
    () async {
      await repository.updateMember(
        group: group,
        member: member,
        nickname: '  Team Lead  ',
        role: PollGroupRole.manager,
        email: 'MEMBER@example.com',
      );

      final updatedMember = await firestore
          .collection('pollGroups')
          .doc(group.id)
          .collection('members')
          .doc(member.uid)
          .get();
      final updatedAllowedMember = await firestore
          .collection('pollGroups')
          .doc(group.id)
          .collection('allowedMembers')
          .doc('member@example.com')
          .get();

      expect(updatedMember.data()?['nickname'], 'Team Lead');
      expect(updatedMember.data()?['role'], 'manager');
      expect(updatedAllowedMember.data()?['nickname'], 'Team Lead');
      expect(updatedAllowedMember.data()?['role'], 'manager');
    },
  );

  test('does not allow the creator to be demoted', () async {
    final creator = PollGroupMember(
      uid: 'owner',
      role: PollGroupRole.admin,
      joinedAt: DateTime(2026, 1, 1),
      joinedBy: 'owner',
    );

    expect(
      () => repository.updateMember(
        group: group,
        member: creator,
        role: PollGroupRole.manager,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'group_creator_must_remain_admin',
        ),
      ),
    );
  });
}
