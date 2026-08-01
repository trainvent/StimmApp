import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../test_helper.dart';

class _TestHomeItem implements HomeItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String createdBy;
  @override
  final String status;
  @override
  final String scopeType;
  @override
  String? get continentCode => null;
  @override
  final String? countryCode;
  @override
  String? get stateOrRegion => state;
  @override
  String? get town => null;
  @override
  String? get city => null;
  @override
  final String? state;
  @override
  final DateTime expiresAt;
  @override
  final int participantCount;
  @override
  final List<String> tags;

  const _TestHomeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.expiresAt,
    this.state,
    this.participantCount = 0,
    this.tags = const [],
    this.scopeType = 'global',
    this.countryCode,
  });
}

class _FakeUser implements User {
  const _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required _TestHomeItem item,
    Widget? bottomAction,
    VoidCallback? onContentTap,
    Widget? topRightAction,
    UserProfile? userProfile,
  }) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseDetailPage<_TestHomeItem>(
          id: item.id,
          appBarTitle: 'Test',
          sharePathSegment: 'test',
          streamProvider: (_) => Stream<_TestHomeItem?>.value(item),
          contentBuilder: (_, _) {
            return TextButton(
              onPressed: onContentTap,
              child: const Text('content_action'),
            );
          },
          bottomAction: bottomAction,
          topRightActionBuilder: topRightAction == null
              ? null
              : (context, item) => topRightAction,
          userProfileFuture: Future<UserProfile?>.value(userProfile),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpPollPage(
    WidgetTester tester, {
    required Poll item,
    required AuthService auth,
  }) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseDetailPage<Poll>(
          id: item.id,
          appBarTitle: 'Test',
          sharePathSegment: 'poll',
          auth: auth,
          streamProvider: (_) => Stream<Poll?>.value(item),
          contentBuilder: (_, _) => const Text('group_content'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'closes UI when status is closed even if expiresAt is in future',
    (tester) async {
      final item = _TestHomeItem(
        id: '1',
        title: 'Title',
        description: 'Desc',
        createdBy: 'user-1',
        status: IConst.closed,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        state: 'NRW',
        participantCount: 10,
        tags: ['tag1'],
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Action'), findsNothing);
      expect(taps, 0);
    },
  );

  testWidgets('shows no positive eligibility label for an in-zone item', (
    tester,
  ) async {
    final item = _TestHomeItem(
      id: 'in-zone',
      title: 'Title',
      description: 'Desc',
      createdBy: 'user-1',
      status: IConst.active,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      scopeType: 'country',
      countryCode: 'DE',
    );

    await pumpPage(
      tester,
      item: item,
      userProfile: const UserProfile(uid: 'viewer', countryCode: 'DE'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eligible for you'), findsNothing);
    expect(find.text('Outside your zone'), findsNothing);
  });

  testWidgets('shows an outside-zone warning for a scope mismatch', (
    tester,
  ) async {
    final item = _TestHomeItem(
      id: 'outside-zone',
      title: 'Title',
      description: 'Desc',
      createdBy: 'user-1',
      status: IConst.active,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      scopeType: 'country',
      countryCode: 'DE',
    );

    await pumpPage(
      tester,
      item: item,
      userProfile: const UserProfile(uid: 'viewer', countryCode: 'US'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outside your zone'), findsOneWidget);
    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
  });

  testWidgets(
    'closes UI when expiresAt is in the past even if status is active',
    (tester) async {
      final item = _TestHomeItem(
        id: '2',
        title: 'Title',
        description: 'Desc',
        createdBy: 'user-1',
        status: IConst.active,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        state: 'NRW',
        participantCount: 10,
        tags: ['tag1'],
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Action'), findsNothing);
      expect(taps, 0);
    },
  );

  testWidgets(
    'keeps UI open when status is active and expiresAt is in future',
    (tester) async {
      final item = _TestHomeItem(
        id: '3',
        title: 'Title',
        description: 'Desc',
        createdBy: 'user-1',
        status: IConst.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        state: 'NRW',
        participantCount: 10,
        tags: ['tag1'],
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'));
      await tester.pump();

      expect(find.text('Closed'), findsNothing);
      expect(find.text('Action'), findsOneWidget);
      expect(taps, 1);
    },
  );

  testWidgets('renders top right action in the app bar actions area', (
    tester,
  ) async {
    final item = _TestHomeItem(
      id: '4',
      title: 'Title',
      description: 'Desc',
      createdBy: 'user-1',
      status: IConst.active,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );

    await pumpPage(
      tester,
      item: item,
      topRightAction: IconButton(
        key: const Key('overflow_action'),
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
    );

    expect(find.byKey(const Key('overflow_action')), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('hides group-only content from non-members', (tester) async {
    final poll = Poll(
      id: 'group-poll',
      title: 'Group Poll',
      description: 'Private group content',
      tags: const [],
      options: const [
        PollOption(id: 'yes', label: 'Yes'),
        PollOption(id: 'no', label: 'No'),
      ],
      votes: const {},
      createdBy: 'creator',
      createdAt: DateTime(2026),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      visibility: 'group',
      groupId: 'group-1',
      groupName: 'Members',
    );

    await pumpPollPage(
      tester,
      item: poll,
      auth: _FakeAuthService(const _FakeUser('outsider')),
    );

    expect(
      find.text('This form is only visible to members of its group.'),
      findsOneWidget,
    );
    expect(find.text('group_content'), findsNothing);
  });

  testWidgets('keeps group-only content visible for the creator', (
    tester,
  ) async {
    final poll = Poll(
      id: 'creator-poll',
      title: 'Group Poll',
      description: 'Private group content',
      tags: const [],
      options: const [
        PollOption(id: 'yes', label: 'Yes'),
        PollOption(id: 'no', label: 'No'),
      ],
      votes: const {},
      createdBy: 'creator',
      createdAt: DateTime(2026),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      visibility: 'group',
      groupId: 'group-1',
      groupName: 'Members',
    );

    await pumpPollPage(
      tester,
      item: poll,
      auth: _FakeAuthService(const _FakeUser('creator')),
    );

    expect(find.text('group_content'), findsOneWidget);
    expect(
      find.text('This form is only visible to members of its group.'),
      findsNothing,
    );
  });
}
