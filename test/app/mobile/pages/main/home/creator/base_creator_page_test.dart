import 'package:flutter/material.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

import '../../../../../../test_helper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('city scope dismisses focus and has no editable town field', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseCreatorPage(
          title: 'Create form',
          tutorialSteps: const [],
          onSubmit:
              ({
                required title,
                required description,
                required tags,
                required scope,
                required durationDays,
                required openUntilClosed,
              }) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleField = find.byType(TextFormField).first;
    await tester.tap(titleField);
    await tester.pump();

    final titleEditable = tester.widget<EditableText>(
      find.descendant(of: titleField, matching: find.byType(EditableText)),
    );
    expect(titleEditable.focusNode.hasFocus, isTrue);

    final scopeSelector = find.byKey(const Key('scopeSelectorCard'));
    await tester.scrollUntilVisible(
      scopeSelector,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(scopeSelector);
    await tester.pumpAndSettle();
    expect(
      find.text('Please set your country in your address first'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<FormScopeType>,
      ),
      findsNothing,
    );

    await tester.tap(scopeSelector);
    await tester.pumpAndSettle();

    expect(titleEditable.focusNode.hasFocus, isFalse);

    await tester.tap(find.text('City').last);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is InputDecorator && widget.decoration.labelText == 'Town',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Add a town to your address before selecting City as the scope',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'country union scope offers every union for the profile country',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            title: 'Create form',
            tutorialSteps: const [],
            profileLoader: () async =>
                const UserProfile(uid: 'german-user', countryCode: 'DE'),
            onSubmit:
                ({
                  required title,
                  required description,
                  required tags,
                  required scope,
                  required durationDays,
                  required openUntilClosed,
                }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scopeSelector = find.byKey(const Key('scopeSelectorCard'));
      await tester.scrollUntilVisible(
        scopeSelector,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(scopeSelector);
      await tester.pumpAndSettle();
      await tester.tap(scopeSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Country union').last);
      await tester.pumpAndSettle();

      final unionSelector = find.byKey(const Key('countryUnionSelectorCard'));
      expect(unionSelector, findsOneWidget);
      await tester.tap(unionSelector);
      await tester.pumpAndSettle();

      expect(find.text('EU'), findsWidgets);
      expect(find.text('UN'), findsOneWidget);
    },
  );

  testWidgets('shows minimum lengths inline without a generic error snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseCreatorPage(
          title: 'Create form',
          tutorialSteps: const [],
          onSubmit:
              ({
                required title,
                required description,
                required tags,
                required scope,
                required durationDays,
                required openUntilClosed,
              }) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minimum 5 characters'), findsOneWidget);
    expect(
      find.text('Minimum 20 characters', skipOffstage: false),
      findsOneWidget,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Valid title');
    await tester.enterText(fields.at(1), 'Too short');

    final submitButton = find.widgetWithText(ElevatedButton, 'Create form');
    await tester.scrollUntilVisible(
      submitButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Minimum 20 characters', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('defaults to six weeks and can switch to open until closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseCreatorPage(
          title: 'Create form',
          tutorialSteps: const [],
          onSubmit:
              ({
                required title,
                required description,
                required tags,
                required scope,
                required durationDays,
                required openUntilClosed,
              }) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sliderFinder = find.byKey(const Key('durationSlider'));
    await tester.scrollUntilVisible(
      sliderFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(sliderFinder);
    await tester.pumpAndSettle();
    expect(find.text('42 days'), findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, 42);
    expect(tester.widget<Slider>(sliderFinder).max, 42);
    expect(find.text('42'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openUntilClosedButton')));
    await tester.pumpAndSettle();

    expect(find.text('42 days'), findsNothing);
    expect(find.text('Open until closed'), findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, 42);
    expect(
      tester
          .widget<SliderTheme>(find.byKey(const Key('durationSliderTheme')))
          .data
          .thumbShape,
      SliderComponentShape.noThumb,
    );

    tester.widget<Slider>(sliderFinder).onChanged!(41);
    await tester.pumpAndSettle();

    expect(find.text('41 days'), findsOneWidget);
    expect(
      tester
          .widget<SliderTheme>(find.byKey(const Key('durationSliderTheme')))
          .data
          .thumbShape,
      isNot(SliderComponentShape.noThumb),
    );
  });
  testWidgets(
    'templates restore settings and leave excluded settings unchanged',
    (tester) async {
      final key = GlobalKey<BaseCreatorPageState>();
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            key: key,
            title: 'Template settings',
            tutorialSteps: const [],
            profileLoader: () async => null,
            onSubmit:
                ({
                  required title,
                  required description,
                  required tags,
                  required scope,
                  required durationDays,
                  required openUntilClosed,
                }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        await key.currentState!.applyTemplate(
          const PollTemplate(
            id: 'one',
            name: 'All settings',
            title: 'Original title',
            description: 'Original description',
            tags: ['community'],
            scopeType: 'global',
            durationDays: 7,
            openUntilClosed: true,
          ),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      final settings = key.currentState!.templateSettings;
      expect(settings.tags, ['community']);
      expect(settings.scopeType, 'global');
      expect(settings.durationDays, 7);
      expect(settings.openUntilClosed, isTrue);
      await key.currentState!.applyTemplate(
        const PollTemplate(id: 'two', name: 'Title only', title: 'New title'),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.templateSettings.toJson(), settings.toJson());
      expect(find.text('New title'), findsOneWidget);
      expect(find.text('Original description'), findsOneWidget);
      await key.currentState!.applyTemplate(
        const PollTemplate(id: 'three', name: 'Clear tags', tags: []),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.templateSettings.tags, isEmpty);
      expect(
        await key.currentState!.applyTemplate(
          const PollTemplate(
            id: 'four',
            name: 'Unavailable scope',
            title: 'Do not apply',
            scopeType: 'countryUnion',
            countryUnion: 'EU',
          ),
        ),
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(find.text('New title'), findsOneWidget);
      expect(key.currentState!.templateSettings.scopeType, 'global');
    },
  );
}
