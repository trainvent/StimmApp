import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/polls/poll_detail_page.dart';
import 'package:stimmapp/app/pages/main/home/polls/survey_detail_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

import '../../../../../../test_helper.dart';

class _User implements User {
  @override
  String get uid => 'reader';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final isSurvey in [false, true]) {
    testWidgets(
      '${isSurvey ? 'survey' : 'poll'} results require the current user to submit',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer(
          overrides: [currentUserProvider.overrideWithValue(_User())],
        );
        addTearDown(container.dispose);
        final widget = createTestWidget(
          UncontrolledProviderScope(
            container: container,
            child: isSurvey
                ? const SurveyDetailPage(id: 'form')
                : const PollDetailPage(id: 'form'),
          ),
        );
        final db = locator.databaseService.instance;
        final reference = db
            .collection(isSurvey ? 'surveys' : 'polls')
            .doc('form');
        if (isSurvey) {
          final survey = Survey(
            id: 'form',
            title: 'Team preferences',
            description: 'Share your preference.',
            tags: const [],
            createdBy: 'creator',
            createdAt: DateTime.now(),
            responseCount: 4,
            questionVotes: const {
              'q': {'a': 3, 'b': 1},
            },
            questions: const [
              SurveyQuestion(
                id: 'q',
                title: 'Which option?',
                options: [
                  SurveyOption(id: 'a', label: 'Option A'),
                  SurveyOption(id: 'b', label: 'Option B'),
                ],
              ),
            ],
          );
          await reference.set(Survey.toFirestore(survey, null));
        } else {
          final poll = Poll(
            id: 'form',
            title: 'Team preferences',
            description: 'Share your preference.',
            questionTitle: 'Which option?',
            tags: const [],
            createdBy: 'creator',
            createdAt: DateTime.now(),
            votes: const {'a': 3, 'b': 1},
            options: const [
              PollOption(id: 'a', label: 'Option A'),
              PollOption(id: 'b', label: 'Option B'),
            ],
          );
          await reference.set(Poll.toFirestore(poll, null));
        }
        final submissions = reference.collection(
          isSurvey ? 'responses' : 'votes',
        );
        await submissions.doc('someone-else').set({'optionId': 'a'});
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.text('Option A'), findsOneWidget);
        expect(find.textContaining('%'), findsNothing);
        await tester.tap(find.text('Option A'));
        await tester.pumpAndSettle();
        expect(find.textContaining('%'), findsNothing);
        await submissions.doc('reader').set({'optionId': 'a'});
        await tester.pumpAndSettle();
        expect(find.text('3 • 75%'), findsOneWidget);
        expect(find.text('1 • 25%'), findsOneWidget);
        await submissions.doc('reader').delete();
        await tester.pumpAndSettle();
        expect(find.textContaining('%'), findsNothing);
        await submissions.doc('reader').set({'optionId': 'a'});
        await tester.pumpAndSettle();
        container.updateOverrides([
          currentUserProvider.overrideWithValue(null),
        ]);
        await tester.pumpAndSettle();
        expect(find.textContaining('%'), findsNothing);
      },
    );
  }
}
