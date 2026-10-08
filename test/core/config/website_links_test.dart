import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/config/brand_config.dart';
import 'package:stimmapp/core/config/environment.dart';

void main() {
  final original = Environment.config;
  tearDown(() => Environment.init(original));
  for (final brand in [BrandConfig.stimmappProd, BrandConfig.vivotProd]) {
    test('website links follow locale for ${brand.appName}', () {
      Environment.init(brand);
      expect(
        Environment.privacyPolicyUrlForLocale(const Locale('de')),
        'https://stimmapp.net/datenschutzerklaerung/',
      );
      expect(
        Environment.privacyPolicyUrlForLocale(const Locale('en')),
        'https://vivot.net/privacy-policy/',
      );
      expect(
        Environment.termsOfServiceUrlForLocale(const Locale('de')),
        'https://stimmapp.net/nutzungsbedingungen/',
      );
      expect(
        Environment.termsOfServiceUrlForLocale(const Locale('en')),
        'https://vivot.net/terms-of-service/',
      );
      expect(
        Environment.privacyPolicyCrashDataUrlForLocale(const Locale('de')),
        'https://stimmapp.net/datenschutzerklaerung-absturzdaten/',
      );
      expect(
        Environment.privacyPolicyCrashDataUrlForLocale(const Locale('en')),
        'https://vivot.net/privacy-policy-crash-data/',
      );
      expect(
        Environment.documentationUrlForLocale(const Locale('de')),
        'https://stimmapp.net/dokumentation/',
      );
      expect(
        Environment.documentationUrlForLocale(const Locale('en')),
        'https://vivot.net/documentation/',
      );
    });
  }
}
