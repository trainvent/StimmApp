import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/widgets/google_profile_requirements_dialog.dart';

import '../../../test_helper.dart';

void main() {
  testWidgets('links incomplete synchronization data to Google profile', (
    tester,
  ) async {
    var openCalls = 0;

    await tester.pumpWidget(
      createTestWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => GoogleProfileRequirementsDialog(
                onOpenGoogleProfile: () async => openCalls++,
              ),
            ),
            child: const Text('Show dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Complete your Google profile'), findsOneWidget);
    expect(
      find.text(
        'Add your full name, birthday, and current location to Google first.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open Google profile'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('openGoogleProfileFromRequirementsButton')),
    );
    await tester.pumpAndSettle();

    expect(openCalls, 1);
    expect(find.byType(GoogleProfileRequirementsDialog), findsNothing);
  });
}
