import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/scaffolds/app_bar_scaffold.dart';

void main() {
  testWidgets('can be repeatedly scrolled without scheduling builds in frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBarScaffold(
          title: 'Scrollable page',
          child: SizedBox(height: 1600),
        ),
      ),
    );

    final scrollView = find.byType(CustomScrollView);
    for (var index = 0; index < 3; index++) {
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pump();
      await tester.drag(scrollView, const Offset(0, 500));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
