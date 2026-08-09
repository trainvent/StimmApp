import 'package:flutter/material.dart';
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
              }) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minimum 5 characters'), findsOneWidget);
    expect(find.text('Minimum 20 characters'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Valid title');
    await tester.enterText(fields.at(1), 'Too short');

    final submitButton = find.widgetWithText(ElevatedButton, 'Create form');
    await tester.scrollUntilVisible(
      submitButton,
      300,
      scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

    expect(find.text('Minimum 20 characters'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
