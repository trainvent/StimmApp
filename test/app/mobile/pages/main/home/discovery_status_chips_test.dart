import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';

import '../../../../../test_helper.dart';

void main() {
  testWidgets('shows only a red warning when an item is outside the zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        const DiscoveryStatusChips(
          status: DiscoveryStatus(
            isEligible: false,
            hasParticipated: false,
            isFinished: false,
            isGroupOnly: false,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Outside your zone'));
    expect(
      text.style?.color,
      Theme.of(tester.element(find.byType(Text))).colorScheme.error,
    );
    expect(find.text('Eligible for you'), findsNothing);
  });

  testWidgets('shows no eligibility chip when an item is in zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        const DiscoveryStatusChips(
          status: DiscoveryStatus(
            isEligible: true,
            hasParticipated: false,
            isFinished: false,
            isGroupOnly: false,
          ),
        ),
      ),
    );

    expect(find.byType(Chip), findsNothing);
    expect(find.text('Eligible for you'), findsNothing);
    expect(find.text('Outside your zone'), findsNothing);
  });
}
