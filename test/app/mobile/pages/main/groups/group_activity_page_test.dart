import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/group_activity_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/poll_group_activity.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
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

class _FakeRepository extends PollGroupRepository {
  _FakeRepository(this.activities)
    : super(DatabaseService(FakeFirebaseFirestore()));

  final List<PollGroupActivity> activities;

  @override
  Stream<List<PollGroupActivity>> watchActivities(String groupId) =>
      Stream.value(activities);
}

void main() {
  final group = PollGroup(
    id: 'group-1',
    name: 'Ops Team',
    createdBy: 'owner',
    createdAt: DateTime(2026, 1, 1),
    joinCode: 'OPS-1',
    nicknameMode: PollGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['owner'],
    importedMemberCount: 0,
  );

  testWidgets('shows localized group activity newest first', (tester) async {
    final activities = [
      PollGroupActivity(
        id: 'published',
        type: PollGroupActivityType.publicationPublished,
        actorUid: 'owner',
        actorDisplayName: 'Alex',
        targetTitle: 'Quarterly priorities',
        createdAt: DateTime(2026, 8, 9, 12),
      ),
      PollGroupActivity(
        id: 'joined',
        type: PollGroupActivityType.memberJoined,
        actorUid: 'member',
        actorDisplayName: 'Sam',
        createdAt: DateTime(2026, 8, 8, 12),
      ),
    ];

    await tester.pumpWidget(
      createTestWidget(
        GroupActivityPage(
          group: group,
          repository: _FakeRepository(activities),
          auth: _FakeAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group activity'), findsOneWidget);
    expect(find.text('Alex published “Quarterly priorities”.'), findsOneWidget);
    expect(find.text('Sam joined the group.'), findsOneWidget);
  });

  testWidgets('shows a friendly empty state', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        GroupActivityPage(
          group: group,
          repository: _FakeRepository(const []),
          auth: _FakeAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No group activity has been recorded yet.'),
      findsOneWidget,
    );
  });
}
