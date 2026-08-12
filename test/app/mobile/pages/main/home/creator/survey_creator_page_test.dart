import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/survey_creator_page.dart';
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
  _FakeAuthService(this.user);

  final User user;

  @override
  User get currentUser => user;
}

class _FakeGroupRepository extends PollGroupRepository {
  _FakeGroupRepository(this.groups)
    : super(DatabaseService(FakeFirebaseFirestore()));

  final List<PollGroup> groups;

  @override
  Stream<List<PollGroup>> watchGroupsForUser(String uid) {
    return Stream.value(groups);
  }
}

void main() {
  final group = PollGroup(
    id: 'group-1',
    name: 'Ops Team',
    createdBy: 'user-1',
    createdAt: DateTime(2026),
    joinCode: 'OPS-1',
    nicknameMode: PollGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['user-1'],
    importedMemberCount: 0,
    accessMode: PollGroupAccessMode.protected,
    inviteLinkEnabled: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('restores cached group, questions, and options in order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'draft_poll_specific_v1': jsonEncode({
        'groupId': 'group-1',
        'questions': [
          {
            'title': 'First question',
            'options': ['First A', 'First B'],
          },
          {
            'title': 'Second question',
            'options': ['Second A', 'Second B', 'Second C'],
          },
        ],
      }),
    });

    await tester.pumpWidget(
      createTestWidget(
        SurveyCreatorPage(
          presentAsPoll: true,
          auth: _FakeAuthService(_FakeUser()),
          groupRepository: _FakeGroupRepository([group]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ops Team'), findsOneWidget);
    expect(find.text('First question'), findsOneWidget);
    expect(find.text('First A'), findsOneWidget);
    expect(find.text('First B'), findsOneWidget);
    expect(find.text('Second question'), findsOneWidget);
    expect(find.text('Second A'), findsOneWidget);
    expect(find.text('Second B'), findsOneWidget);
    expect(find.text('Second C'), findsOneWidget);

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[2].controller!.text, 'First question');
    expect(fields[5].controller!.text, 'Second question');
  });

  testWidgets('writes question and option edits to the specific draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        SurveyCreatorPage(
          presentAsPoll: true,
          auth: _FakeAuthService(_FakeUser()),
          groupRepository: _FakeGroupRepository([group]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('survey_group_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ops Team').last);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'Cached question');
    await tester.enterText(fields.at(3), 'Cached A');
    await tester.enterText(fields.at(4), 'Cached B');
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final draft =
        jsonDecode(prefs.getString('draft_poll_specific_v1')!)
            as Map<String, dynamic>;
    final questions = draft['questions'] as List<dynamic>;
    expect(draft['groupId'], 'group-1');
    expect(questions.single, {
      'title': 'Cached question',
      'options': ['Cached A', 'Cached B'],
    });
  });
}
