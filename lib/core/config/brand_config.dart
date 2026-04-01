enum AppFlavor { stimmappDev, stimmappProd, vivotDev, vivotProd }

enum AppBrand { stimmapp, vivot }

class BrandConfig {
  const BrandConfig({
    required this.flavor,
    required this.brand,
    required this.appName,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.privacyPolicyCrashDataUrl,
    required this.privacyPolicyAdsUrl,
    required this.privacyPolicyCookiesUrl,
    required this.termsOfServiceUrl,
    required this.faqUrl,
    required this.shareHost,
  });

  final AppFlavor flavor;
  final AppBrand brand;
  final String appName;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String privacyPolicyCrashDataUrl;
  final String privacyPolicyAdsUrl;
  final String privacyPolicyCookiesUrl;
  final String termsOfServiceUrl;
  final String faqUrl;
  final String shareHost;

  bool get isDev => switch (flavor) {
    AppFlavor.stimmappDev || AppFlavor.vivotDev => true,
    AppFlavor.stimmappProd || AppFlavor.vivotProd => false,
  };

  bool get isProd => !isDev;

  String get shareBaseUrl => 'https://$shareHost';

  static const BrandConfig stimmappDev = BrandConfig(
    flavor: AppFlavor.stimmappDev,
    brand: AppBrand.stimmapp,
    appName: 'StimmApp',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://www.stimmapp.net/privacy-policy',
    privacyPolicyCrashDataUrl:
        'https://www.stimmapp.net/privacy_policy_crashdata.html',
    privacyPolicyAdsUrl: 'https://www.stimmapp.net/privacy_policy_ads.html',
    privacyPolicyCookiesUrl: 'https://www.stimmapp.net/privacy-policy',
    termsOfServiceUrl: 'https://www.stimmapp.net/terms-of-service',
    faqUrl: 'https://www.stimmapp.net/faq',
    shareHost: 'stimmapp-dev.web.app',
  );

  static const BrandConfig stimmappProd = BrandConfig(
    flavor: AppFlavor.stimmappProd,
    brand: AppBrand.stimmapp,
    appName: 'StimmApp',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://www.stimmapp.net/privacy-policy',
    privacyPolicyCrashDataUrl:
        'https://www.stimmapp.net/privacy_policy_crashdata.html',
    privacyPolicyAdsUrl: 'https://www.stimmapp.net/privacy_policy_ads.html',
    privacyPolicyCookiesUrl: 'https://www.stimmapp.net/privacy-policy',
    termsOfServiceUrl: 'https://www.stimmapp.net/terms-of-service',
    faqUrl: 'https://www.stimmapp.net/faq',
    shareHost: 'stimmapp.net',
  );

  static const BrandConfig vivotDev = BrandConfig(
    flavor: AppFlavor.vivotDev,
    brand: AppBrand.vivot,
    appName: 'Vivot Dev',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://vivot.net/privacy',
    privacyPolicyCrashDataUrl: 'https://vivot.net/privacy',
    privacyPolicyAdsUrl: 'https://vivot.net/privacy',
    privacyPolicyCookiesUrl: 'https://vivot.net/privacy',
    termsOfServiceUrl: 'https://vivot.net/terms',
    faqUrl: 'https://vivot.net/faq',
    shareHost: 'vivot-dev.web.app',
  );

  static const BrandConfig vivotProd = BrandConfig(
    flavor: AppFlavor.vivotProd,
    brand: AppBrand.vivot,
    appName: 'Vivot',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://vivot.net/privacy',
    privacyPolicyCrashDataUrl: 'https://vivot.net/privacy',
    privacyPolicyAdsUrl: 'https://vivot.net/privacy',
    privacyPolicyCookiesUrl: 'https://vivot.net/privacy',
    termsOfServiceUrl: 'https://vivot.net/terms',
    faqUrl: 'https://vivot.net/faq',
    shareHost: 'vivot.net',
  );
}
