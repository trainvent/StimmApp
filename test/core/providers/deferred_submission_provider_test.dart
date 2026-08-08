import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/providers/deferred_submission_provider.dart';

void main() {
  testWidgets('undo cancels a pending submission before it commits', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var commitCount = 0;

    container
        .read(deferredSubmissionProvider.notifier)
        .queue(
          id: 'petition:1',
          action: () async => commitCount++,
          onSuccess: () {},
          onError: (_) {},
        );

    expect(
      container.read(deferredSubmissionProvider)['petition:1'],
      DeferredSubmissionPhase.pending,
    );

    await tester.pump(const Duration(seconds: 4));
    container.read(deferredSubmissionProvider.notifier).cancel('petition:1');
    await tester.pump(const Duration(seconds: 2));

    expect(commitCount, 0);
    expect(container.read(deferredSubmissionProvider), isEmpty);
  });

  testWidgets('a pending submission commits after the undo window', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var commitCount = 0;
    var successCount = 0;

    container
        .read(deferredSubmissionProvider.notifier)
        .queue(
          id: 'survey:1',
          action: () async => commitCount++,
          onSuccess: () => successCount++,
          onError: (_) {},
        );

    await tester.pump(DeferredSubmissionController.undoDuration);
    await tester.pump();

    expect(commitCount, 1);
    expect(successCount, 1);
    expect(container.read(deferredSubmissionProvider), isEmpty);
  });
}
