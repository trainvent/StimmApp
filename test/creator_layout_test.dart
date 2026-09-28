import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/theme/app_theme.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'test_helper.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('German creator fits $size with larger text and anchored scope', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader(
        'Poppins',
      )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader(
        'Roboto',
      )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
      await (FontLoader(
        'Ahem',
      )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
      final stateKey = GlobalKey<BaseCreatorPageState>();
      final app =
          createTestWidget(
                BaseCreatorPage(
                  key: stateKey,
                  title: 'Umfrage erstellen',
                  tutorialSteps: const [],
                  onSubmit:
                      ({
                        required title,
                        required description,
                        required tags,
                        required scope,
                        required durationDays,
                        required openUntilClosed,
                      }) async => false,
                ),
                locale: const Locale('de'),
              )
              as MaterialApp;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: app.locale,
          localizationsDelegates: app.localizationsDelegates,
          supportedLocales: app.supportedLocales,
          home: app.home,
          theme: AppTheme.lightFor(AppColorTheme.forest),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await stateKey.currentState!.applyTemplate(
        const PollTemplate(
          id: 'v',
          name: 'v',
          title: 'Mehr Grün in unserem Viertel',
          description:
              'Sollen wir im nächsten Jahr mehr Bäume und Grünflächen in unserem Viertel anlegen?',
          tags: ['Environment', 'Social'],
          scopeType: 'global',
        ),
      );
      await tester.pumpAndSettle();
      void checkLayout() => expect(tester.takeException(), isNull);
      final edit = find.byKey(const Key('durationSlider'));
      await tester.scrollUntilVisible(
        edit,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      checkLayout();
      await tester.ensureVisible(find.byKey(const Key('select_tags_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('select_tags_button')));
      await tester.pumpAndSettle();
      checkLayout();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      final scope = find.byKey(const Key('scopeSelectorCard'));
      await tester.ensureVisible(scope);
      await tester.pumpAndSettle();
      await tester.tap(scope);
      await tester.pumpAndSettle();
      checkLayout();
      final firstOption = find.byType(PopupMenuItem<FormScopeType>).first;
      expect(
        tester.getRect(firstOption).center.dx,
        closeTo(tester.getRect(scope).center.dx, 1),
      );
      expect(find.byIcon(Icons.arrow_left), findsOneWidget);
      await tester.tap(find.text('Global').last);
      await tester.pumpAndSettle();
      final preview = find.widgetWithText(ElevatedButton, 'Vorschau');
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();
      await tester.tap(preview);
      await tester.pumpAndSettle();
      checkLayout();
    });
  }
}
