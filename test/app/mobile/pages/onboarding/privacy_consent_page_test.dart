import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/onboarding/privacy_consent_page.dart';
import 'package:stimmapp/core/config/brand_config.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';

import '../../../../test_helper.dart';

void main() {
  setUp(() => Environment.init(BrandConfig.stimmappProd));

  testWidgets('starts unset collection choices disabled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      createTestWidget(
        const ProviderScope(
          child: PrivacyConsentPage(profile: UserProfile(uid: 'new-user')),
        ),
      ),
    );

    final analytics = tester.widget<SwitchListTile>(
      find.byKey(const Key('analyticsConsentSwitch')),
    );
    final crashLogs = tester.widget<SwitchListTile>(
      find.byKey(const Key('crashLogsConsentSwitch')),
    );

    expect(analytics.value, isFalse);
    expect(crashLogs.value, isFalse);
    expect(find.text('Save selection'), findsOneWidget);
    expect(find.text('Allow all'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Allow all')).dy,
      lessThan(tester.getTopLeft(find.text('Save selection')).dy),
    );
    expect(
      find.ancestor(
        of: find.text('Allow all'),
        matching: find.byType(ElevatedButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preserves an existing choice when only one is unset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      createTestWidget(
        const ProviderScope(
          child: PrivacyConsentPage(
            profile: UserProfile(
              uid: 'partial-user',
              analyticsCollectionEnabled: true,
            ),
          ),
        ),
      ),
    );

    final analytics = tester.widget<SwitchListTile>(
      find.byKey(const Key('analyticsConsentSwitch')),
    );
    final crashLogs = tester.widget<SwitchListTile>(
      find.byKey(const Key('crashLogsConsentSwitch')),
    );

    expect(analytics.value, isTrue);
    expect(crashLogs.value, isFalse);
  });

  testWidgets('animates both switches before saving Allow all', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const profile = UserProfile(uid: 'allow-all-user');
    final app = createTestWidget(
      const ProviderScope(child: PrivacyConsentPage(profile: profile)),
    );
    final userRepository = UserRepository.create();
    await userRepository.upsert(profile);
    await tester.pumpWidget(app);

    await tester.tap(find.text('Allow all'));
    await tester.pump();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('analyticsConsentSwitch')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('crashLogsConsentSwitch')),
          )
          .value,
      isTrue,
    );
    expect((await userRepository.getById(profile.uid))?.sendCrashLogs, isNull);

    await tester.pump(kThemeAnimationDuration);
    await tester.pump();

    final savedProfile = await userRepository.getById(profile.uid);
    expect(savedProfile?.analyticsCollectionEnabled, isTrue);
    expect(savedProfile?.sendCrashLogs, isTrue);
  });
}
