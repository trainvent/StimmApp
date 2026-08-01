import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';

import '../../../../../test_helper.dart';

void main() {
  testWidgets('shows an already-participated chip', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DiscoveryStatusChips(
          status: DiscoveryStatus(
            hasParticipated: true,
            isFinished: false,
            isGroupOnly: false,
          ),
        ),
      ),
    );

    expect(find.text('Already participated'), findsOneWidget);
    expect(find.text('Eligible for you'), findsNothing);
    expect(find.text('Outside your zone'), findsNothing);
  });

  testWidgets('shows no status chip before participation', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DiscoveryStatusChips(
          status: DiscoveryStatus(
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
