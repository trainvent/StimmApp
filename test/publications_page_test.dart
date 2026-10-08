import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/list/publications_page.dart';

import 'test_helper.dart';

void main() {
  testWidgets('publications hub renders and scrolls inside its scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const PublicationsPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Your ideas in action'), findsOneWidget);
    final createSurvey = find.widgetWithText(OutlinedButton, 'Create Survey');
    // Small screens can still reach the final action through the scaffold.
    await tester.scrollUntilVisible(
      createSurvey,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(createSurvey, findsOneWidget);
  });
}
