import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/home/polls/poll_detail_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/poll.dart';

import '../../../../../../test_helper.dart';

void main() {
  testWidgets('published poll displays its question above the answer options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final widget = createTestWidget(
      const ProviderScope(child: PollDetailPage(id: 'published')),
      locale: const Locale('de'),
    );
    final poll = Poll(
      id: 'published',
      title: 'Workplace satisfaction',
      description: 'Please share your experience at work.',
      questionTitle: 'How satisfied are you with your workplace?',
      tags: const [],
      options: const [
        PollOption(id: 'yes', label: 'Very satisfied'),
        PollOption(id: 'no', label: 'Not satisfied'),
      ],
      votes: const {},
      createdBy: 'author',
      createdAt: DateTime.now(),
    );
    await locator.databaseService.instance
        .collection('polls')
        .doc(poll.id)
        .set(Poll.toFirestore(poll, null));
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    final question = find.text(poll.questionTitle);
    final answer = find.text('Very satisfied');
    expect(question, findsOneWidget);
    expect(answer, findsOneWidget);
    expect(
      tester.getTopLeft(question).dy,
      lessThan(tester.getTopLeft(answer).dy),
    );
    expect(find.text('Teilnehmer'), findsNothing);
    await tester.tap(find.text(poll.title));
    await tester.pumpAndSettle();
    final metadata = find.byKey(const Key('form_participation_metadata'));
    expect(metadata, findsOneWidget);
    expect(
      find.descendant(of: find.byType(ExpansionTile), matching: metadata),
      findsOneWidget,
    );
    final expiration = find.byKey(const Key('form_expiration_metadata'));
    expect(expiration, findsOneWidget);
    expect(
      tester.getTopLeft(expiration).dy,
      lessThan(tester.getTopLeft(metadata).dy),
    );
    expect(
      find.descendant(
        of: metadata,
        matching: find.byIcon(Icons.schedule_outlined),
      ),
      findsNothing,
    );
    expect(find.text('Teilnehmer'), findsOneWidget);
    await tester.tap(find.text(poll.title));
    await tester.pumpAndSettle();
    expect(find.text('Teilnehmer'), findsNothing);
  });
}
