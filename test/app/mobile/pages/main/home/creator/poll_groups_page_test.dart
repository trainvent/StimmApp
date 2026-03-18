import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

import '../../../../../../test_helper.dart';

class _FakeUser implements User {
  @override
  String get uid => 'user-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

class _FakeCsvImporter extends PollGroupCsvImporter {
  const _FakeCsvImporter(this.content);

  final String? content;

  @override
  Future<String?> pickCsvText() async => content;
}

class _RecordingPollGroupRepository extends PollGroupRepository {
  _RecordingPollGroupRepository()
    : super(DatabaseService(FakeFirebaseFirestore()));

  Map<String, Object?>? lastCreatePayload;
  final List<PollGroup> createdGroups = [];

  @override
  Future<String> createGroup({
    required String creatorUid,
    required String name,
    required String joinCode,
    required PollGroupNicknameMode nicknameMode,
    required bool managersCanInvite,
    required PollGroupAccessMode accessMode,
    required bool inviteLinkEnabled,
    DateTime? expiresAt,
    List<PollGroupAllowedMember> allowedMembers = const [],
    List<PollGroupAllowedDomain> allowedDomains = const [],
  }) async {
    lastCreatePayload = {
      'creatorUid': creatorUid,
      'name': name,
      'nicknameMode': nicknameMode,
      'managersCanInvite': managersCanInvite,
      'accessMode': accessMode,
      'inviteLinkEnabled': inviteLinkEnabled,
      'allowedMembers': allowedMembers,
      'allowedDomains': allowedDomains,
    };
    final group = PollGroup(
      id: 'group-1',
      name: name,
      createdBy: creatorUid,
      createdAt: DateTime(2024, 1, 1),
      joinCode: joinCode,
      nicknameMode: nicknameMode,
      managersCanInvite: managersCanInvite,
      memberIds: [creatorUid],
      importedMemberCount: allowedMembers.length,
      accessMode: accessMode,
      inviteLinkEnabled: inviteLinkEnabled,
    );
    createdGroups
      ..clear()
      ..add(group);
    return group.id;
  }

  @override
  Stream<List<PollGroup>> watchGroupsForUser(String uid) {
    return Stream.value(List<PollGroup>.from(createdGroups));
  }
}

void main() {
  late _FakeUser user;
  late _RecordingPollGroupRepository repository;

  setUp(() {
    initializeTestDependencies();
    user = _FakeUser();
    repository = _RecordingPollGroupRepository();
  });

  group('GroupEditorPage', () {
    testWidgets('defaults to protected access and shows access description', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupEditorPage(repository: repository, auth: _FakeAuthService(user)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_mode_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('access_mode_description')), findsOneWidget);
    });

    testWidgets('imports CSV rows and reports malformed ones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupEditorPage(
            repository: repository,
            auth: _FakeAuthService(user),
            csvImporter: const _FakeCsvImporter(
              'email,nickname,role\n'
              'anna@example.com,Anna,user\n'
              'broken-row\n'
              'lead@example.com,Lead,manager',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('pick_csv_button')),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      final importButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('pick_csv_button')),
      );
      importButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('anna@example.com'), findsOneWidget);
      expect(find.text('lead@example.com'), findsOneWidget);
      expect(find.byKey(const Key('csv_import_summary')), findsOneWidget);
      expect(
        find.text('Last import: 2 valid rows, 1 malformed rows.'),
        findsOneWidget,
      );
    });

    testWidgets('imports TSV rows', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupEditorPage(
            repository: repository,
            auth: _FakeAuthService(user),
            csvImporter: const _FakeCsvImporter(
              'email\tnickname\trole\n'
              'anna@example.com\tAnna\tuser\n'
              'lead@example.com\tLead\tmanager',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('pick_csv_button')),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      final importButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('pick_csv_button')),
      );
      importButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('anna@example.com'), findsOneWidget);
      expect(find.text('lead@example.com'), findsOneWidget);
      expect(
        find.text('Last import: 2 valid rows, 0 malformed rows.'),
        findsOneWidget,
      );
    });

    testWidgets('creates groups with manual members and domain rules', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupEditorPage(repository: repository, auth: _FakeAuthService(user)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Ops Team');
      await tester.scrollUntilVisible(
        find.byKey(const Key('member_email_0')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('member_email_0')),
        'anna@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('member_nickname_0')),
        'Anna',
      );

      await tester.scrollUntilVisible(
        find.text('Add domain'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final addDomainButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Add domain'),
      );
      addDomainButton.onPressed!();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('domain_value_0')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('domain_value_0')),
        '@example.com',
      );

      final createButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_group_button')),
      );
      createButton.onPressed!();
      await tester.pumpAndSettle();

      expect(repository.lastCreatePayload?['name'], 'Ops Team');
      expect(
        repository.lastCreatePayload?['accessMode'],
        PollGroupAccessMode.protected,
      );
      expect(repository.lastCreatePayload?['inviteLinkEnabled'], isTrue);

      final allowedMembers =
          repository.lastCreatePayload?['allowedMembers']
              as List<PollGroupAllowedMember>;
      final allowedDomains =
          repository.lastCreatePayload?['allowedDomains']
              as List<PollGroupAllowedDomain>;

      expect(allowedMembers, hasLength(1));
      expect(allowedMembers.single.email, 'anna@example.com');
      expect(allowedMembers.single.nickname, 'Anna');

      expect(allowedDomains, hasLength(1));
      expect(allowedDomains.single.domain, 'example.com');
    });
  });
}
