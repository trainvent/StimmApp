import 'dart:async';

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

  testWidgets('publishing returns immediately from preview to overview', (
    tester,
  ) async {
    final publication = Completer<bool>();
    final key = GlobalKey<BaseCreatorPageState>();
    await tester.pumpWidget(
      createTestWidget(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BaseCreatorPage(
                    key: key,
                    title: 'Editor',
                    tutorialSteps: const [],
                    profileLoader: () async => null,
                    previewContentBuilder: (_) => const Text('Preview content'),
                    onSubmit: ({
                      required title,
                      required description,
                      required tags,
                      required scope,
                      required durationDays,
                      required openUntilClosed,
                    }) => publication.future,
                  ),
                ),
              ),
              child: const Text('Overview'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    await key.currentState!.applyTemplate(
      const PollTemplate(
        id: 'publish',
        name: 'Publish',
        title: 'A useful title',
        description: 'A description long enough to publish.',
        tags: ['Environment'],
        scopeType: 'global',
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.widgetWithText(ElevatedButton, 'Preview');
    await tester.scrollUntilVisible(
      preview,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(preview);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_publication')));
    await tester.pump();
    expect(find.text('Preview content'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    publication.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.byType(BaseCreatorPage), findsNothing);
    expect(find.text('Preview content'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'petition menu saves incomplete form without publication validation',
    (tester) async {
      PollTemplate? saved;
      var choseDraft = false;
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            title: 'Petition',
            tutorialSteps: const [],
            profileLoader: () async => null,
            onSaveDraft: (form) async => saved = form,
            onChooseDraft: () async {
              choseDraft = true;
            },
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Unfinished petition',
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      expect(saved!.title, 'Unfinished petition');
      expect(saved!.description, '');
      expect(saved!.tags, isEmpty);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved drafts'));
      await tester.pumpAndSettle();
      expect(choseDraft, isTrue);
    },
  );

  testWidgets('initial template replaces stale draft after profile loading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'draft_Reuse_title': 'Stale title',
      'draft_Reuse_description': 'Stale description',
      'draft_Reuse_duration': 1,
    });
    final key = GlobalKey<BaseCreatorPageState>();
    await tester.pumpWidget(
      createTestWidget(
        BaseCreatorPage(
          key: key,
          title: 'Reuse',
          tutorialSteps: const [],
          profileLoader: () async => null,
          initialTemplate: const PollTemplate(
            id: '',
            name: 'Expired form',
            title: 'Reused title',
            description: 'Reused description',
            tags: ['Environment'],
          ),
          onSubmit: ({
            required title,
            required description,
            required tags,
            required scope,
            required durationDays,
            required openUntilClosed,
          }) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'Reused title');
    expect(fields[1].controller!.text, 'Reused description');
    expect(key.currentState!.templateSettings.tags, ['Environment']);
    expect(key.currentState!.templateSettings.openUntilClosed, false);
  });

  testWidgets(
    'tag popup confirms selection, enforces the limit, and cancels edits',
    (tester) async {
      final key = GlobalKey<BaseCreatorPageState>();
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            key: key,
            title: 'Tag draft',
            tutorialSteps: const [],
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final add = find.byKey(const Key('select_tags_button'));
      await tester.scrollUntilVisible(
        add,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      for (final label in ['Environment', 'Politics', 'Education']) {
        await tester.tap(find.widgetWithText(FilterChip, label));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 of 3 selected'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Health'))
            .onSelected,
        isNull,
      );
      expect(key.currentState!.templateSettings.tags, isEmpty);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNWidgets(3));
      expect(find.byType(FilterChip), findsNothing);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Politics'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Health'))
            .onSelected,
        isNotNull,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(key.currentState!.templateSettings.tags, [
        'Environment',
        'Politics',
        'Education',
      ]);
    },
  );

  testWidgets(
    'preview does not publish until confirmed and failed publication preserves draft',
    (tester) async {
      final key = GlobalKey<BaseCreatorPageState>();
      var attempts = 0;
      var succeeds = false;
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            key: key,
            title: 'Review draft',
            tutorialSteps: const [],
            previewContentBuilder: (_) => const Text('Preview answers'),
            onSubmit:
                ({
                  required title,
                  required description,
                  required tags,
                  required scope,
                  required durationDays,
                  required openUntilClosed,
                }) async {
                  attempts++;
                  expect(title, 'A useful title');
                  expect(tags, ['Environment']);
                  return succeeds;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await key.currentState!.applyTemplate(
        const PollTemplate(
          id: 'review',
          name: 'Review',
          title: 'A useful title',
          description: 'A description long enough to publish.',
          tags: ['Environment'],
          scopeType: 'global',
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.widgetWithText(ElevatedButton, 'Preview');
      await tester.scrollUntilVisible(
        preview,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(attempts, 0);
      expect(find.text('Preview answers'), findsOneWidget);
      await tester.tap(find.text('Continue editing'));
      await tester.pumpAndSettle();
      expect(attempts, 0);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_publication')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(attempts, 1);
      expect(prefs.getString('draft_Review draft_title'), 'A useful title');
      succeeds = true;
      await tester.tap(preview);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_publication')));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(prefs.getString('draft_Review draft_title'), isNull);
    },
  );

  testWidgets('city scope dismisses focus and has no editable town field', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseCreatorPage(
          title: 'Create form',
          tutorialSteps: const [],
          onSubmit: ({
            required title,
            required description,
            required tags,
            required scope,
            required durationDays,
            required openUntilClosed,
          }) async => true,
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

    expect(
      find.descendant(
        of: scopeSelector,
        matching: find.byIcon(Icons.arrow_drop_up),
      ),
      findsOneWidget,
    );
    final anchorTop = tester.getTopLeft(scopeSelector).dy;
    await tester.tap(scopeSelector);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final reveal = find.byType(SizeTransition).last;
    final partial = tester.getRect(reveal);
    await tester.pumpAndSettle();
    final expanded = tester.getRect(reveal);
    expect(expanded.bottom, closeTo(anchorTop - 4, 0.1));
    expect(partial.bottom, closeTo(expanded.bottom, 0.1));
    expect(partial.top, greaterThan(expanded.top));

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
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => true,
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
          onSubmit: ({
            required title,
            required description,
            required tags,
            required scope,
            required durationDays,
            required openUntilClosed,
          }) async => true,
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Preview');
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
          onSubmit: ({
            required title,
            required description,
            required tags,
            required scope,
            required durationDays,
            required openUntilClosed,
          }) async => true,
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
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => true,
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
