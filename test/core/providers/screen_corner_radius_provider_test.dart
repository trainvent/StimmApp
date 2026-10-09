import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/providers/screen_corner_radius_provider.dart';

void main() {
  const channel = MethodChannel('corner_radius_plugin');
  const fallback = BorderRadius.all(Radius.circular(AppRadii.large));

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'loads once, preserves per-corner values, and can refresh',
    (tester) async {
      var calls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expectSync(call.method, 'getScreenRadius');
        calls++;
        return {
          'topLeft': 40.0 + calls,
          'topRight': 42.0,
          'bottomLeft': 44.0,
          'bottomRight': 46.0,
        };
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appCornerRadiiProvider).large, fallback);
      await tester.pump();
      await tester.runAsync(
        () => container.read(screenCornerRadiusProvider.future),
      );
      final corners = container.read(appCornerRadiiProvider).large;
      expect(corners.topLeft.x, 41);
      expect(corners.topRight.x, 42);
      expect(corners.bottomLeft.x, 44);
      expect(corners.bottomRight.x, 46);
      container.read(appCornerRadiiProvider);
      expect(calls, 1);

      container.invalidate(screenCornerRadiusProvider);
      expect(container.read(appCornerRadiiProvider).large, corners);
      await tester.pump();
      await tester.runAsync(
        () => container.read(screenCornerRadiusProvider.future),
      );
      expect(container.read(appCornerRadiiProvider).large.topLeft.x, 42);
      expect(calls, 2);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  for (final failure in ['null', 'missing', 'platform']) {
    testWidgets(
      'uses fallback for $failure plugin result',
      (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (failure == 'missing') throw MissingPluginException();
            if (failure == 'platform') {
              throw PlatformException(code: 'unavailable');
            }
            return null;
          },
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(appCornerRadiiProvider);
        await tester.pump();
        await tester.runAsync(
          () => container.read(screenCornerRadiusProvider.future),
        );
        expect(container.read(appCornerRadiiProvider).large, fallback);
      },
      variant: TargetPlatformVariant({TargetPlatform.android}),
    );
  }

  testWidgets(
    'invalid and zero corners fall back individually',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'topLeft': 0.0,
          'topRight': -1.0,
          'bottomLeft': double.nan,
          'bottomRight': 48.0,
        },
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appCornerRadiiProvider);
      await tester.pump();
      await tester.runAsync(
        () => container.read(screenCornerRadiusProvider.future),
      );
      expect(
        container.read(appCornerRadiiProvider).large,
        fallback.copyWith(bottomRight: const Radius.circular(48)),
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets(
    'iOS reads the bundled device dataset',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expectSync(call.method, 'getDeviceInfo');
        return {'modelIdentifier': 'iPhone16,1', 'deviceType': 'iPhone'};
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        final future = container.read(screenCornerRadiusProvider.future);
        await tester.pump();
        await future;
      });
      expect(
        container.read(appCornerRadiiProvider).large,
        BorderRadius.circular(55),
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'unknown iOS models use the fallback',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => {'modelIdentifier': 'unknown', 'deviceType': 'iPhone'},
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        final future = container.read(screenCornerRadiusProvider.future);
        await tester.pump();
        await future;
      });
      expect(container.read(appCornerRadiiProvider).large, fallback);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'desktop uses fallback without invoking the native plugin',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => fail('Desktop must not call the mobile plugin'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(screenCornerRadiusProvider.future);
      expect(container.read(appCornerRadiiProvider).large, fallback);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
