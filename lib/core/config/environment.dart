import 'package:stimmapp/core/config/brand_config.dart';

class Environment {
  static BrandConfig config = BrandConfig.stimmappProd;

  static void init(BrandConfig brandConfig) {
    config = brandConfig;
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
