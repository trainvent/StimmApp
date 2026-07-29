import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/onboarding/welcome_page.dart';
import 'package:stimmapp/app/widgets/buttons/login_provider_button_widget.dart';
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

  testWidgets('shows the compact Google provider label', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      createTestWidget(const WelcomePage(), locale: const Locale('de')),
    );

    expect(find.text('Google'), findsOneWidget);
    expect(find.text('oder'), findsOneWidget);
  });

  testWidgets(
    'places compact, equally sized provider buttons in one row on iOS',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        createTestWidget(const WelcomePage(), locale: const Locale('de')),
      );

      final google = find.byKey(keys.welcomePage.googleSignInButton);
      final apple = find.byKey(keys.welcomePage.appleSignInButton);
      debugDefaultTargetPlatformOverride = null;

      expect(google, findsOneWidget);
      expect(apple, findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.byType(LoginProviderButtonWidget), findsNWidgets(2));
      expect(tester.getSize(google), tester.getSize(apple));
      expect(tester.getTopLeft(google).dy, tester.getTopLeft(apple).dy);
      expect(
        tester.getTopLeft(google).dx,
        lessThan(tester.getTopLeft(apple).dx),
      );
    },
  );
}
