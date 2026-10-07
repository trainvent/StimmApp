import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/app/pages/main/home/polls/polls_page.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
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

  testWidgets(
    'no group excludes assigned forms and clears back to all groups',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(const PollsPage(initialGroupId: '')),
      );
      await tester.pumpAndSettle();
      BaseOverviewPage<HomeItem> overview() =>
          tester.widget<BaseOverviewPage<HomeItem>>(
            find.byType(BaseOverviewPage<HomeItem>),
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
      createTestWidget(const PollsPage(initialGroupId: 'group-1')),
    );
    await tester.pumpAndSettle();
    final overview = tester.widget<BaseOverviewPage<HomeItem>>(
      find.byType(BaseOverviewPage<HomeItem>),
    );
    expect(overview.extraFilter!(poll('group-1')), isTrue);
    expect(overview.extraFilter!(poll('group-2')), isFalse);
    expect(overview.extraFilter!(poll(null)), isFalse);
  });
}
