import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';

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
                required scopeType,
                scopeContinentCode,
                scopeCountryCode,
                scopeStateOrRegion,
                scopeTown,
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
}
