import 'package:flutter/widgets.dart';
import 'package:stimmapp/core/config/brand_config.dart';

class Environment {
  static BrandConfig config = BrandConfig.stimmappProd;

  static void init(BrandConfig brandConfig) {
    config = brandConfig;
  }

  static void applyBrandForLocale({Locale? locale, String? webHost}) {
    final bool useVivot = _shouldUseVivotBrand(webHost: webHost);
    final bool dev = config.isDev;
    if (useVivot) {
      config = dev ? BrandConfig.vivotDev : BrandConfig.vivotProd;
    } else {
      config = dev ? BrandConfig.stimmappDev : BrandConfig.stimmappProd;
    }
  }

  static bool _shouldUseVivotBrand({String? webHost}) {
    final String host = (webHost ?? '').toLowerCase();
    if (host == 'vivot.net' || host.endsWith('.vivot.net')) return true;
    if (host == 'stimmapp.net' || host.endsWith('.stimmapp.net')) return false;
    return false;
  }

  static bool get isDev => config.isDev;
  static bool get isProd => config.isProd;
  static bool get isVivot => config.brand == AppBrand.vivot;
  static bool get isStimmapp => config.brand == AppBrand.stimmapp;
  static bool get supportsStateScope => isStimmapp;
  static String get appName => config.appName;
  static String get supportEmail => config.supportEmail;
  static String get privacyPolicyUrl => config.privacyPolicyUrl;
  static String get termsOfServiceUrl => config.termsOfServiceUrl;
  static String get faqUrl => config.faqUrl;
  static String get shareHost => config.shareHost;
  static String get shareBaseUrl => config.shareBaseUrl;
}
