import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/onboarding/welcome_page.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';

import '../../../../test_helper.dart';

void main() {
  testWidgets('places Google sign-in below the login flow and divider', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(const WelcomePage()));

    final login = find.byKey(const Key('login_button'));
    final google = find.byKey(keys.welcomePage.googleSignInButton);

    expect(login, findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(google, findsOneWidget);
    expect(tester.getTopLeft(login).dy, lessThan(tester.getTopLeft(google).dy));
  });

  testWidgets('localizes the Google button in German', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      createTestWidget(const WelcomePage(), locale: const Locale('de')),
    );

    expect(find.text('Mit Google fortfahren'), findsOneWidget);
    expect(find.text('oder'), findsOneWidget);
  });
}
