import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

void main() {
  bool skips({
    String key = 'test_example',
    bool dev = true,
    bool debug = false,
    bool web = false,
    TargetPlatform platform = TargetPlatform.iOS,
  }) => shouldSkipDevAppleTestStore(
    apiKey: key,
    isDev: dev,
    isDebug: debug,
    isWeb: web,
    platform: platform,
  );

  test(
    'dev Apple profile/release skips Test Store before native configure',
    () {
      expect(skips(), isTrue);
      expect(skips(platform: TargetPlatform.macOS), isTrue);
    },
  );

  test('debug keeps Test Store purchases available', () {
    expect(skips(debug: true), isFalse);
  });

  test('dev Apple SDK key still configures platform sandbox purchases', () {
    expect(skips(key: 'appl_example'), isFalse);
  });

  test('does not silently disable billing in production', () {
    expect(skips(dev: false), isFalse);
  });

  test('does not change Android or web Test Store configuration', () {
    expect(skips(platform: TargetPlatform.android), isFalse);
    expect(skips(web: true), isFalse);
  });
}
