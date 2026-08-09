import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stimmapp/app/pages/main/groups/group_dashboard_page.dart';
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

  testWidgets('group content opens with a title and back navigation', (
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

    await tester.tap(find.text('Polls and surveys'));
    await tester.pumpAndSettle();

    final appBarFinder = find.widgetWithText(AppBar, 'Polls and surveys');
    expect(appBarFinder, findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    final appBar = tester.widget<AppBar>(appBarFinder);
    final tabBarBackground =
        (appBar.bottom! as PreferredSize).child as Material;
    expect(
      tabBarBackground.color,
      Theme.of(tester.element(appBarFinder)).scaffoldBackgroundColor,
    );
  });

  testWidgets('invite card offers QR display and clipboard copy actions', (
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

    final qrButtonFinder = find.byKey(const Key('display_group_invite_qr'));
    final copyButtonFinder = find.byKey(const Key('copy_group_invite_link'));
    expect(qrButtonFinder, findsOneWidget);
    expect(copyButtonFinder, findsOneWidget);
    expect(
      (tester.widget<IconButton>(qrButtonFinder).icon as Icon).icon,
      Icons.qr_code_2,
    );
    expect(
      (tester.widget<IconButton>(copyButtonFinder).icon as Icon).icon,
      Icons.copy_outlined,
    );

    await tester.tap(qrButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Copy link'), findsOneWidget);
  });
}
