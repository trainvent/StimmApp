import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/blocked_forms_page.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test('blocked mode is opt-in and persists both toggle values', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(showBlockedFormsProvider), isFalse);
    await container.read(showBlockedFormsProvider.notifier).setEnabled(true);
    expect(container.read(showBlockedFormsProvider), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('showBlockedForms'),
      isTrue,
    );
    await container.read(showBlockedFormsProvider.notifier).setEnabled(false);
    expect(
      (await SharedPreferences.getInstance()).getBool('showBlockedForms'),
      isFalse,
    );
  });

  testWidgets('marker shows Settings hint without disabling mode', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(showBlockedFormsProvider.notifier).initialize(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: app(const BannedModeMarker()),
      ),
    );
    await tester.tap(find.text('Banned'));
    await tester.pump();
    expect(
      find.text(
        'You’re viewing only blocked forms. You can turn this off in Settings.',
      ),
      findsOneWidget,
    );
    expect(container.read(showBlockedFormsProvider), isTrue);
  });

  testWidgets('archive opens read-only safe summary with moderation details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedFormsProvider('petition').overrideWith(
            (ref) => Stream.value([
              {
                'title': 'Reviewed title',
                'summary': 'Safe summary',
                'guideline': 'Privacy',
                'explanation': 'Exposed personal data',
                'removedAt': Timestamp.fromDate(DateTime(2026, 9, 30)),
              },
            ]),
          ),
        ],
        child: app(const BlockedFormsPage(contentType: 'petition')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reviewed title'));
    await tester.pumpAndSettle();
    expect(find.text('Safe summary'), findsOneWidget);
    expect(find.text('Exposed personal data'), findsOneWidget);
    expect(find.text('Violated guideline'), findsOneWidget);
    expect(find.text('Removed on'), findsOneWidget);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('empty archive explains the mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedFormsProvider('poll').overrideWith((ref) => Stream.value([])),
        ],
        child: app(const BlockedFormsPage(contentType: 'poll')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No blocked forms to show.'), findsOneWidget);
  });
}
