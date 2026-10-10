import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/widgets/overview_filter_dialog.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/participation_filter.dart';

import '../../../test_helper.dart';

void main() {
  for (final language in ['en', 'de']) {
    testWidgets('participation defaults, changes and clears ($language)', (
      tester,
    ) async {
      const initial = OverviewFilterSelection(
        tags: [],
        scopes: {},
        countryUnions: {},
      );
      OverviewFilterSelection? result;
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<OverviewFilterSelection>(
                  context: context,
                  builder: (_) => const OverviewFilterDialog(
                    initialSelection: initial,
                    showParticipationFilter: true,
                  ),
                );
              },
              child: const Text('Open filter'),
            ),
          ),
          locale: Locale(language),
        ),
      );
      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      ChoiceChip chip(ParticipationFilter filter) => tester.widget<ChoiceChip>(
        find.byKey(ValueKey('participation_filter_${filter.name}')),
      );
      expect(chip(ParticipationFilter.notParticipated).selected, isTrue);
      for (final option in [
        ParticipationFilter.all,
        ParticipationFilter.participated,
      ]) {
        await tester.tap(
          find.byKey(ValueKey('participation_filter_${option.name}')),
        );
        await tester.pumpAndSettle();
        expect(chip(option).selected, isTrue);
        expect(chip(ParticipationFilter.notParticipated).selected, isFalse);
      }
      expect(initial.participation, ParticipationFilter.notParticipated);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(result!.participation, ParticipationFilter.participated);

      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          TextButton,
          language == 'en' ? 'Remove' : 'Entfernen',
        ),
      );
      await tester.pumpAndSettle();
      expect(chip(ParticipationFilter.all).selected, isTrue);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(result!.participation, ParticipationFilter.all);
    });

    testWidgets('filter drafts clear and confirm independently ($language)', (
      tester,
    ) async {
      final initial = OverviewFilterSelection(
        tags: [],
        scopes: {FormScopeType.country},
        countryUnions: {},
      );
      OverviewFilterSelection? result;
      var clearCount = 0;
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<OverviewFilterSelection>(
                  context: context,
                  builder: (context) => OverviewFilterDialog(
                    initialSelection: initial,
                    structureFilterSectionBuilder: (context, update) =>
                        const Text('Structure option'),
                    clearExtraFilters: () => clearCount++,
                  ),
                );
              },
              child: const Text('Open filter'),
            ),
          ),
          locale: Locale(language),
        ),
      );
      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'en' ? 'Structure' : 'Struktur'),
        findsOneWidget,
      );
      expect(find.text('Design'), findsNothing);
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      final chip = find.byType(FilterChip).first;
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(initial.scopes, {FormScopeType.country});
      await tester.tap(
        find.widgetWithText(
          TextButton,
          language == 'en' ? 'Remove' : 'Entfernen',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(clearCount, 1);
      expect(result!.scopes, isEmpty);
      expect(result!.tags, isEmpty);
      expect(result!.participation, ParticipationFilter.all);
      expect(initial.scopes, {FormScopeType.country});
    });
  }
}
