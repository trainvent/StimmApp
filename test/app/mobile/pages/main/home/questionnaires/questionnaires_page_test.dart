import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/app/pages/main/home/questionnaires/questionnaires_page.dart';
import 'package:stimmapp/core/data/models/questionnaire.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';

import '../../../../../../test_helper.dart';

void main() {
  Poll poll(String? groupId) => Poll(
    id: 'poll',
    title: 'Poll',
    description: '',
    tags: const [],
    options: const [],
    votes: const {},
    createdBy: 'author',
    createdAt: DateTime(2026),
    groupId: groupId,
  );
  Survey survey(String? groupId) => Survey(
    id: 'survey',
    title: 'Survey',
    description: '',
    tags: const [],
    questions: const [],
    questionVotes: const {},
    createdBy: 'author',
    createdAt: DateTime(2026),
    groupId: groupId,
  );

  testWidgets('German type controls fit a narrow phone under Other', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      createTestWidget(const QuestionnairesPage(), locale: const Locale('de')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('other_filters')));
    await tester.pumpAndSettle();
    final slider = find.byKey(const Key('questionnaire_type_filter_slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(slider).value, 1);
    expect(find.text('Beide'), findsOneWidget);
    tester.widget<Slider>(slider).onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('Abstimmung'), findsOneWidget);
    tester.widget<Slider>(slider).onChanged!(2);
    await tester.pumpAndSettle();
    expect(find.text('Fragebogen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('type slider supports polls, both, surveys, and clearing', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const QuestionnairesPage(initialGroupId: 'group-1')),
    );
    await tester.pumpAndSettle();
    BaseOverviewPage<Questionnaire> overview() =>
        tester.widget<BaseOverviewPage<Questionnaire>>(
          find.byType(BaseOverviewPage<Questionnaire>),
        );
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    final finder = find.byKey(const Key('questionnaire_type_filter_slider'));
    Slider slider() => tester.widget<Slider>(finder);
    expect(slider().value, 1);
    slider().onChanged!(0);
    await tester.pumpAndSettle();
    expect(overview().extraFilter!(poll('group-1')), isTrue);
    expect(overview().extraFilter!(survey('group-1')), isFalse);
    expect(overview().extraFilter!(poll('other-group')), isFalse);
    expect(overview().extraFilterCount, 2);
    slider().onChanged!(2);
    await tester.pumpAndSettle();
    expect(overview().extraFilter!(poll('group-1')), isFalse);
    expect(overview().extraFilter!(survey('group-1')), isTrue);
    expect(overview().extraFilterCount, 2);
    slider().onChanged!(1);
    await tester.pumpAndSettle();
    expect(overview().extraFilter!(poll('group-1')), isTrue);
    expect(overview().extraFilter!(survey('group-1')), isTrue);
    expect(overview().extraFilterCount, 1);
    slider().onChanged!(2);
    await tester.pumpAndSettle();
    overview().clearExtraFilters!();
    await tester.pumpAndSettle();
    expect(overview().extraFilterCount, 0);
    expect(overview().extraFilter!(poll(null)), isTrue);
    expect(overview().extraFilter!(survey('other-group')), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'no group excludes assigned forms and clears back to all groups',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(const QuestionnairesPage(initialGroupId: '')),
      );
      await tester.pumpAndSettle();
      BaseOverviewPage<Questionnaire> overview() =>
          tester.widget<BaseOverviewPage<Questionnaire>>(
            find.byType(BaseOverviewPage<Questionnaire>),
          );
      expect(overview().extraFilterCount, 1);
      for (final item in [poll(null), poll(''), survey(null), survey('')]) {
        expect(overview().extraFilter!(item), isTrue);
      }
      expect(overview().extraFilter!(poll('group-1')), isFalse);
      expect(overview().extraFilter!(survey('group-1')), isFalse);
      overview().clearExtraFilters!();
      await tester.pumpAndSettle();
      expect(overview().extraFilterCount, 0);
      expect(overview().extraFilter!(poll('group-1')), isTrue);
      expect(overview().extraFilter!(poll(null)), isTrue);
    },
  );

  testWidgets('a particular group still excludes unassigned and other groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const QuestionnairesPage(initialGroupId: 'group-1')),
    );
    await tester.pumpAndSettle();
    final overview = tester.widget<BaseOverviewPage<Questionnaire>>(
      find.byType(BaseOverviewPage<Questionnaire>),
    );
    expect(overview.extraFilter!(poll('group-1')), isTrue);
    expect(overview.extraFilter!(poll('group-2')), isFalse);
    expect(overview.extraFilter!(poll(null)), isFalse);
  });
}
