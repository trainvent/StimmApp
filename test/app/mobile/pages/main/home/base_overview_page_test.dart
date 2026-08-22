import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/core/data/models/petition.dart';

import '../../../../../test_helper.dart';

class _RebuildHarness extends StatefulWidget {
  const _RebuildHarness({super.key, required this.streamProvider});

  final Stream<List<Petition>> Function(String query, String status)
  streamProvider;

  @override
  State<_RebuildHarness> createState() => _RebuildHarnessState();
}

class _RebuildHarnessState extends State<_RebuildHarness> {
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return BaseOverviewPage<Petition>(
      streamProvider: widget.streamProvider,
      itemBuilder: (context, petition, _) => Text(petition.title),
    );
  }
}

void main() {
  testWidgets('keeps loaded overview streams across parent rebuilds', (
    tester,
  ) async {
    var subscriptionsCreated = 0;
    final petition = Petition(
      id: 'petition-1',
      title: 'Loaded petition',
      description: 'Description',
      tags: const [],
      signatureCount: 0,
      createdBy: 'creator',
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2027, 1, 1),
    );
    final harnessKey = GlobalKey<_RebuildHarnessState>();

    await tester.pumpWidget(
      createTestWidget(
        _RebuildHarness(
          key: harnessKey,
          streamProvider: (_, _) {
            subscriptionsCreated += 1;
            return Stream.value([petition]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialSubscriptions = subscriptionsCreated;
    expect(find.text('Loaded petition'), findsOneWidget);

    harnessKey.currentState!.rebuild();
    await tester.pump();

    expect(subscriptionsCreated, initialSubscriptions);
    expect(find.text('Loaded petition'), findsOneWidget);
  });

  testWidgets('rapid overview tab switching does not reuse subscriptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        _RebuildHarness(
          streamProvider: (_, _) => Stream.value(const <Petition>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tabs = find.byType(Tab);
    expect(tabs, findsNWidgets(2));
    for (var index = 0; index < 5; index++) {
      await tester.tap(tabs.at(1));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(tabs.at(0));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
