import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_dashboard_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

import '../../../../../test_helper.dart';

class _FakeUser implements User {
  @override
  String get uid => 'owner-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  @override
  User? get currentUser => _FakeUser();
}

class _FakePollGroupRepository extends PollGroupRepository {
  _FakePollGroupRepository(this.group)
    : super(DatabaseService(FakeFirebaseFirestore()));

  final PollGroup group;

  @override
  Stream<PollGroup?> watchGroup(String groupId) => Stream.value(group);

  @override
  Stream<PollGroupMember?> watchMember(String groupId, String uid) =>
      Stream.value(null);
}

void main() {
  final group = PollGroup(
    id: 'group-1',
    name: 'Ops Team',
    createdBy: 'owner-1',
    createdAt: DateTime(2026, 1, 1),
    joinCode: 'OPS-1',
    nicknameMode: PollGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['owner-1'],
    importedMemberCount: 0,
    accessMode: PollGroupAccessMode.protected,
    inviteLinkEnabled: true,
  );

  testWidgets('canceling group deletion does not reuse disposed text state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestWidget(
        GroupDashboardPage(
          group: group,
          repository: _FakePollGroupRepository(group),
          auth: _FakeAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteAction = find.text('Delete group').last;
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });
}
