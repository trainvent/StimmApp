import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_group_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late QuestionnaireGroupRepository repository;
  late QuestionnaireGroup group;
  late QuestionnaireGroupMember member;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = QuestionnaireGroupRepository(DatabaseService(firestore));
    group = QuestionnaireGroup(
      id: 'group-1',
      name: 'Operations',
      createdBy: 'owner',
      createdAt: DateTime(2026, 1, 1),
      joinCode: 'OPS-1',
      nicknameMode: QuestionnaireGroupNicknameMode.adminAssigned,
      managersCanInvite: true,
      memberIds: const ['owner', 'member'],
      importedMemberCount: 1,
    );
    member = QuestionnaireGroupMember(
      uid: 'member',
      role: QuestionnaireGroupRole.user,
      nickname: 'Old name',
      joinedAt: DateTime(2026, 1, 2),
      joinedBy: 'owner',
    );
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .set(QuestionnaireGroup.toFirestore(group, null));
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('members')
        .doc(member.uid)
        .set(QuestionnaireGroupMember.toFirestore(member, null));
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
        role: QuestionnaireGroupRole.manager,
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
    final creator = QuestionnaireGroupMember(
      uid: 'owner',
      role: QuestionnaireGroupRole.admin,
      joinedAt: DateTime(2026, 1, 1),
      joinedBy: 'owner',
    );

    expect(
      () => repository.updateMember(
        group: group,
        member: creator,
        role: QuestionnaireGroupRole.manager,
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
