import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/app/pages/main/groups/group_invite_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/group_picture_service.dart';
import 'package:stimmapp/app/widgets/group_avatar.dart';
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
  Map<String, Object?>? lastUpdatePayload;
  final List<PollGroup> createdGroups = [];
  int createCalls = 0;
  String? savedPicture;
  bool pictureSaved = false;

  @override
  Future<void> setProfilePicture(String groupId, String? url) async {
    pictureSaved = true;
    savedPicture = url;
  }

  @override
  Future<List<PollGroupAllowedMember>> getAllowedMembers(String groupId) async {
    return const [];
  }

  @override
  Future<List<PollGroupAllowedDomain>> getAllowedDomains(String groupId) async {
    return const [];
  }

  @override
  Future<int> updateGroup({
    required PollGroup group,
    List<PollGroupAllowedMember> allowedMembers = const [],
    List<PollGroupAllowedDomain> allowedDomains = const [],
    List<String> inviteEmails = const [],
  }) async {
    lastUpdatePayload = {
      'group': group,
      'allowedMembers': allowedMembers,
      'allowedDomains': allowedDomains,
      'inviteEmails': inviteEmails,
    };
    return inviteEmails.length;
  }

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
    createCalls++;
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

class _FakeGroupPictures extends GroupPictureService {
  bool failUpload = false;
  int uploads = 0;
  final deleted = <String>[];
  @override
  Future<Uint8List?> pickPicture() async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aT9sAAAAASUVORK5CYII=',
  );
  @override
  Future<String> upload(
    String groupId,
    Uint8List bytes, {
    required void Function(double) onProgress,
  }) async {
    uploads++;
    onProgress(0.5);
    if (failUpload) throw StateError('upload_failed');
    onProgress(1);
    return 'https://example.test/new-group.png';
  }

  @override
  Future<void> delete(String groupId, String url) async => deleted.add(url);
}

void main() {
  late _FakeUser user;
  late _RecordingPollGroupRepository repository;

  setUp(() {
    initializeTestDependencies();
    user = _FakeUser();
    repository = _RecordingPollGroupRepository();
  });

  final existingGroup = PollGroup(
    id: 'group-1',
    name: 'Ops Team',
    createdBy: 'user-1',
    createdAt: DateTime(2024, 1, 1),
    joinCode: 'OPS-1',
    nicknameMode: PollGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['user-1'],
    importedMemberCount: 0,
    accessMode: PollGroupAccessMode.protected,
    inviteLinkEnabled: true,
  );

  group('Group editor and invitation pages', () {
    testWidgets(
      'picture upload retries use the created group instead of creating twice',
      (tester) async {
        final pictures = _FakeGroupPictures()..failUpload = true;
        await tester.pumpWidget(
          createTestWidget(
            GroupEditorPage(
              repository: repository,
              auth: _FakeAuthService(user),
              pictureService: pictures,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pick_group_picture')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<GroupAvatar>(find.byType(GroupAvatar)).bytes,
          isNotNull,
        );
        await tester.enterText(find.byType(TextField).first, 'Photo group');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('save_group_button')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        tester
            .widget<FilledButton>(find.byKey(const Key('save_group_button')))
            .onPressed!();
        await tester.pumpAndSettle();
        expect(repository.createCalls, 1);
        expect(repository.pictureSaved, isFalse);
        expect(find.text('Edit group'), findsOneWidget);
        pictures.failUpload = false;
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('save_group_button')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        tester
            .widget<FilledButton>(find.byKey(const Key('save_group_button')))
            .onPressed!();
        await tester.pumpAndSettle();
        expect(repository.createCalls, 1);
        expect(repository.savedPicture, 'https://example.test/new-group.png');
        expect(pictures.uploads, 2);
      },
    );

    testWidgets(
      'removing a picture saves null and cleans up the previous image',
      (tester) async {
        final pictures = _FakeGroupPictures();
        await tester.pumpWidget(
          createTestWidget(
            GroupEditorPage(
              initialGroup: existingGroup.copyWith(
                profilePictureUrl: 'https://example.test/old.png',
              ),
              repository: repository,
              auth: _FakeAuthService(user),
              pictureService: pictures,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('remove_group_picture')));
        await tester.pumpAndSettle();
        expect(repository.pictureSaved, isFalse);
        expect(
          tester.widget<GroupAvatar>(find.byType(GroupAvatar)).url,
          isNull,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('save_group_button')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        tester
            .widget<FilledButton>(find.byKey(const Key('save_group_button')))
            .onPressed!();
        await tester.pumpAndSettle();
        expect(repository.pictureSaved, isTrue);
        expect(repository.savedPicture, isNull);
        expect(pictures.deleted, ['https://example.test/old.png']);
      },
    );

    testWidgets('accessibility help toggles inline explanations', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupEditorPage(repository: repository, auth: _FakeAuthService(user)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('access_mode_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('access_mode_description')), findsNothing);
      await tester.tap(find.byKey(const Key('group_editor_help')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('access_mode_description')), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('group_editor_help')))
            .isSelected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('group_editor_help')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('access_mode_description')), findsNothing);
    });

    testWidgets('invitation page imports CSV rows and reports malformed ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupInvitePage(
            group: existingGroup,
            repository: repository,
            auth: _FakeAuthService(user),
            csvImporter: const _FakeCsvImporter(
              'E-Mail;Spitzname;Rolle\n'
              'anna@example.com;Anna;Benutzer\n'
              'broken-row\n'
              'lead@example.com;Lead;Manager',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('<email>,<nickname>,<role>'), findsOneWidget);

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

    testWidgets('invitation page imports TSV rows', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupInvitePage(
            group: existingGroup,
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

    testWidgets('creates groups with domain rules but no invitation drafts', (
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
        find.byKey(const Key('add_domain_row')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final addDomainButton = tester.widget<IconButton>(
        find.byKey(const Key('add_domain_row')),
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

      expect(allowedMembers, isEmpty);

      expect(allowedDomains, hasLength(1));
      expect(allowedDomains.single.domain, 'example.com');
    });

    testWidgets('sends invitation drafts once and clears the page', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupInvitePage(
            group: existingGroup,
            repository: repository,
            auth: _FakeAuthService(user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email or username *'), findsOneWidget);
      expect(find.text('Nickname'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('member_email_0')),
        'anna@example.com',
      );
      await tester.tap(find.byKey(const Key('send_group_invitations')));
      await tester.pumpAndSettle();

      final allowedMembers =
          repository.lastUpdatePayload?['allowedMembers']
              as List<PollGroupAllowedMember>;
      expect(allowedMembers, hasLength(1));
      expect(allowedMembers.single.email, 'anna@example.com');
      expect(repository.lastUpdatePayload?['inviteEmails'], const [
        'anna@example.com',
      ]);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('member_email_0')))
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('resolves an invitation username to its account email', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final userRepository = UserRepository(DatabaseService(firestore));
      await userRepository.upsertWithUniqueUsername(
        const UserProfile(
          uid: 'anna-id',
          displayName: 'Anna Original',
          email: 'anna@example.com',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          GroupInvitePage(
            group: existingGroup,
            repository: repository,
            userRepository: userRepository,
            auth: _FakeAuthService(user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('member_email_0')),
        'ANNA ORIGINAL',
      );
      await tester.tap(find.byKey(const Key('send_group_invitations')));
      await tester.pumpAndSettle();

      final allowedMembers =
          repository.lastUpdatePayload?['allowedMembers']
              as List<PollGroupAllowedMember>;
      expect(allowedMembers.single.email, 'anna@example.com');
      expect(repository.lastUpdatePayload?['inviteEmails'], const [
        'anna@example.com',
      ]);
    });
  });
}
