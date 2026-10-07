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
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final widget = createTestWidget(
      const ProviderScope(child: PollDetailPage(id: 'published')),
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
  });
}
