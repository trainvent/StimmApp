import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/group_members_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

import '../../../../../test_helper.dart';

class _FakeUser implements User {
  @override
  String get uid => 'owner';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  @override
  User? get currentUser => _FakeUser();
}

void main() {
  testWidgets('edits a member nickname and rank', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final database = DatabaseService(firestore);
    final repository = PollGroupRepository(database);
    final userRepository = UserRepository(database);
    final group = PollGroup(
      id: 'group-1',
      name: 'Operations',
      createdBy: 'owner',
      createdAt: DateTime(2026, 1, 1),
      joinCode: 'OPS-1',
      nicknameMode: PollGroupNicknameMode.adminAssigned,
      managersCanInvite: true,
      memberIds: const ['owner', 'member', 'member-2', 'member-3'],
      importedMemberCount: 0,
    );
    final member = PollGroupMember(
      uid: 'member',
      role: PollGroupRole.user,
      joinedAt: DateTime(2026, 1, 2),
      joinedBy: 'owner',
    );
    final member2 = PollGroupMember(
      uid: 'member-2',
      role: PollGroupRole.user,
      joinedAt: DateTime(2026, 1, 3),
      joinedBy: 'owner',
    );
    final member3 = PollGroupMember(
      uid: 'member-3',
      role: PollGroupRole.manager,
      joinedAt: DateTime(2026, 1, 4),
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
        .collection('members')
        .doc(member2.uid)
        .set(PollGroupMember.toFirestore(member2, null));
    await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('members')
        .doc(member3.uid)
        .set(PollGroupMember.toFirestore(member3, null));
    await userRepository.upsert(
      const UserProfile(
        uid: 'member',
        displayName: 'Account name',
        email: 'member@example.com',
      ),
    );
    await userRepository.upsert(
      const UserProfile(
        uid: 'member-2',
        displayName: 'Second member',
        email: 'second@example.com',
      ),
    );
    await userRepository.upsert(
      const UserProfile(
        uid: 'member-3',
        displayName: 'Third member',
        email: 'third@example.com',
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        GroupMembersPage(
          group: group,
          repository: repository,
          userRepository: userRepository,
          auth: _FakeAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tap a member to edit them. Long-press to select one or more members to remove.',
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('group_members_info')));
    await tester.pumpAndSettle();
    expect(find.text('Manage members'), findsNWidgets(2));
    expect(
      find.text(
        'Tap a member to edit them. Long-press to select one or more members to remove.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group_member_member')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('group_member_nickname_field')),
      'Team Lead',
    );
    await tester.tap(find.byKey(const Key('group_member_role_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manager').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_group_member')));
    await tester.pumpAndSettle();

    final updated = await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('members')
        .doc(member.uid)
        .get();
    expect(updated.data()?['nickname'], 'Team Lead');
    expect(updated.data()?['role'], 'manager');
    expect(find.text('Team Lead'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group_member_member')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.longPress(find.byKey(const Key('group_member_member')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group_member_member-2')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove_selected_group_members')));
    await tester.pumpAndSettle();
    expect(find.text('Remove selected members?'), findsOneWidget);
    expect(
      find.text('Remove all 2 selected members from this group?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm_remove_selected_members')));
    await tester.pumpAndSettle();

    for (final uid in [member.uid, member2.uid]) {
      final removed = await firestore
          .collection('pollGroups')
          .doc(group.id)
          .collection('members')
          .doc(uid)
          .get();
      expect(removed.exists, isFalse);
    }
    final untouched = await firestore
        .collection('pollGroups')
        .doc(group.id)
        .collection('members')
        .doc(member3.uid)
        .get();
    expect(untouched.exists, isTrue);
    expect(tester.takeException(), isNull);
  });
}
