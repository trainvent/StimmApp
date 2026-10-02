import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/survey_creator_page.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
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

    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      createTestWidget(
        ProviderScope(
          child: SurveyCreatorPage(
            presentAsPoll: true,
            auth: _FakeAuthService(_FakeUser()),
            groupRepository: _FakeGroupRepository([group]),
          ),
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

  testWidgets(
    'preview includes group and ordered questions without publishing',
    (tester) async {
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
              'options': ['Second A', 'Second B'],
            },
          ],
        }),
      });
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          ProviderScope(
            child: SurveyCreatorPage(
              presentAsPoll: true,
              auth: _FakeAuthService(_FakeUser()),
              groupRepository: _FakeGroupRepository([group]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final base = tester.state<BaseCreatorPageState>(
        find.byType(BaseCreatorPage),
      );
      await base.applyTemplate(
        const PollTemplate(
          id: 'review',
          name: 'Review',
          title: 'Team decisions',
          description: 'The agenda for our next team meeting.',
          tags: ['Social'],
          scopeType: 'global',
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.widgetWithText(ElevatedButton, 'Preview');
      await tester.scrollUntilVisible(
        preview,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(find.text('Ops Team'), findsOneWidget);
      expect(find.text('1. First question'), findsOneWidget);
      expect(find.text('2. Second question'), findsOneWidget);
      expect(find.text('Second B'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.text('Continue editing'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('draft_poll_specific_v1'),
        contains('First question'),
      );
    },
  );

  testWidgets('review rejects an empty question scrolled off screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'draft_poll_specific_v1': jsonEncode({
        'questions': [
          {
            'title': '',
            'options': ['Yes', 'No'],
          },
          {
            'title': 'Valid question',
            'options': ['Yes', 'No'],
          },
        ],
      }),
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      createTestWidget(
        ProviderScope(
          child: SurveyCreatorPage(
            presentAsPoll: true,
            auth: _FakeAuthService(_FakeUser()),
            groupRepository: _FakeGroupRepository([]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final base = tester.state<BaseCreatorPageState>(
      find.byType(BaseCreatorPage),
    );
    await base.applyTemplate(
      const PollTemplate(
        id: 'review',
        name: 'Review',
        title: 'Team decisions',
        description: 'The agenda for our next team meeting.',
        tags: ['Social'],
        scopeType: 'global',
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.widgetWithText(ElevatedButton, 'Preview');
    await tester.scrollUntilVisible(
      preview,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_publication')), findsNothing);
  });

  testWidgets('writes question and option edits to the specific draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      createTestWidget(
        ProviderScope(
          child: SurveyCreatorPage(
            presentAsPoll: true,
            auth: _FakeAuthService(_FakeUser()),
            groupRepository: _FakeGroupRepository([group]),
          ),
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
      'type': 'multipleChoice',
      'options': ['Cached A', 'Cached B'],
    });
  });
  testWidgets(
    'consent preset replaces blank options and persists the ordered answers',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          ProviderScope(
            child: SurveyCreatorPage(
              presentAsPoll: true,
              auth: _FakeAuthService(_FakeUser()),
              groupRepository: _FakeGroupRepository([]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final preset = find.byTooltip('Answer presets');
      await tester.ensureVisible(preset);
      await tester.tap(preset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consent: Yes / Undecided / No / Veto'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final draft =
          jsonDecode(prefs.getString('draft_poll_specific_v1')!) as Map;
      expect((draft['questions'] as List).single['options'], [
        'Yes',
        'Undecided',
        'No',
        'Veto',
      ]);
      await tester.tap(find.byTooltip('Answer presets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frequency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final unchanged =
          jsonDecode(prefs.getString('draft_poll_specific_v1')!) as Map;
      expect((unchanged['questions'] as List).single['options'], [
        'Yes',
        'Undecided',
        'No',
        'Veto',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final includeAll in [true, false]) {
    testWidgets('save and reuse a template (include all: $includeAll)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        createTestWidget(
          ProviderScope(
            child: SurveyCreatorPage(
              presentAsPoll: true,
              auth: _FakeAuthService(_FakeUser()),
              groupRepository: _FakeGroupRepository([group]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('survey_group_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ops Team').last);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Weekly meeting');
      await tester.enterText(fields.at(1), 'Our recurring agenda');
      await tester.enterText(fields.at(2), 'Shall we proceed?');
      await tester.enterText(fields.at(3), 'Yes');
      await tester.enterText(fields.at(4), 'No');
      await tester.ensureVisible(find.byTooltip('Save as template'));
      await tester.tap(find.byTooltip('Save as template'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((field) => field.value == true),
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isFalse);
      if (!includeAll) {
        for (final field in [
          'description',
          'questions',
          'tags',
          'scope',
          'duration',
          'audience',
        ]) {
          await tester.tap(find.byKey(ValueKey('template_field_$field')));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('poll_templates_v1_user-1'), hasLength(1));
      if (includeAll) {
        await tester.tap(find.byTooltip('Save as template'));
        await tester.pumpAndSettle();
        final nameField = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(nameField, '  WEEKLY meeting  ');
        await tester.pumpAndSettle();
        final update = find.widgetWithText(FilledButton, 'Update template');
        expect(tester.widget<FilledButton>(update).onPressed, isNotNull);
        await tester.enterText(nameField, 'Another meeting');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirm'),
              )
              .onPressed,
          isNotNull,
        );
        await tester.enterText(nameField, 'Weekly meeting');
        await tester.pumpAndSettle();
        final beforeOverwrite = prefs.getStringList('poll_templates_v1_user-1');
        await tester.tap(find.text('Update template'));
        await tester.pumpAndSettle();
        expect(find.text('Overwrite existing template?'), findsOneWidget);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          prefs.getStringList('poll_templates_v1_user-1'),
          beforeOverwrite,
        );
        await tester.tap(find.text('Update template'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        expect(prefs.getStringList('poll_templates_v1_user-1'), hasLength(1));
      }

      final saved =
          jsonDecode(prefs.getStringList('poll_templates_v1_user-1')!.single)
              as Map;
      expect(saved.containsKey('scopeType'), includeAll);
      expect(saved.containsKey('durationDays'), includeAll);
      expect(saved.containsKey('tags'), includeAll);
      expect(saved.containsKey('includesAudience'), includeAll);
      expect(saved.containsKey('questions'), includeAll);
      await tester.enterText(fields.at(1), 'Changed description');
      await tester.tap(find.byKey(const Key('survey_group_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public').last);
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(0), 'Changed title');
      await tester.ensureVisible(find.byTooltip('Poll templates'));
      await tester.tap(find.byTooltip('Poll templates'));
      await tester.pumpAndSettle();
      final templateTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Weekly meeting'),
      );
      final summary = (templateTile.subtitle! as Text).data!;
      expect(summary, includeAll ? contains('question') : 'Title');
      await tester.tap(find.text('Weekly meeting'));
      await tester.pumpAndSettle();
      expect(find.text('Changed title'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly meeting'), findsOneWidget);
      expect(
        find.text(includeAll ? 'Our recurring agenda' : 'Changed description'),
        findsOneWidget,
      );
      expect(find.text('Shall we proceed?'), findsOneWidget);
      final draft =
          jsonDecode(prefs.getString('draft_poll_specific_v1')!) as Map;
      expect(draft['groupId'], includeAll ? 'group-1' : null);
      expect(tester.takeException(), isNull);
    });
  }
}
