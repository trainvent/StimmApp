enum AppFlavor {
  stimmappDev,
  stimmappProd,
  vivotDev,
  vivotProd,
}

enum AppBrand { stimmapp, vivot }

class BrandConfig {
  const BrandConfig({
    required this.flavor,
    required this.brand,
    required this.appName,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.faqUrl,
    required this.shareHost,
    required this.revenueCatApiKeyDevAndroid,
    required this.revenueCatApiKeyDevIos,
    required this.revenueCatApiKeyProdAndroid,
    required this.revenueCatApiKeyProdIos,
  });

  final AppFlavor flavor;
  final AppBrand brand;
  final String appName;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String faqUrl;
  final String shareHost;
  final String revenueCatApiKeyDevAndroid;
  final String revenueCatApiKeyDevIos;
  final String revenueCatApiKeyProdAndroid;
  final String revenueCatApiKeyProdIos;

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
    privacyPolicyUrl: 'https://www.stimmapp.eu/privacy-policy',
    termsOfServiceUrl: 'https://www.stimmapp.eu/terms-of-service',
    faqUrl: 'https://www.stimmapp.eu/faq',
    shareHost: 'stimmapp-dev.web.app',
    revenueCatApiKeyDevAndroid: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyDevIos: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyProdAndroid: 'goog_gaOrZloplZgSgUVWiKGRXUXyFXF',
    revenueCatApiKeyProdIos: 'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ',
  );

  static const BrandConfig stimmappProd = BrandConfig(
    flavor: AppFlavor.stimmappProd,
    brand: AppBrand.stimmapp,
    appName: 'StimmApp',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://www.stimmapp.eu/privacy-policy',
    termsOfServiceUrl: 'https://www.stimmapp.eu/terms-of-service',
    faqUrl: 'https://www.stimmapp.eu/faq',
    shareHost: 'stimmapp.eu',
    revenueCatApiKeyDevAndroid: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyDevIos: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyProdAndroid: 'goog_gaOrZloplZgSgUVWiKGRXUXyFXF',
    revenueCatApiKeyProdIos: 'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ',
  );

  static const BrandConfig vivotDev = BrandConfig(
    flavor: AppFlavor.vivotDev,
    brand: AppBrand.vivot,
    appName: 'Vivot Dev',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://vivot.net/privacy',
    termsOfServiceUrl: 'https://vivot.net/terms',
    faqUrl: 'https://vivot.net/faq',
    shareHost: 'vivot-dev.web.app',
    revenueCatApiKeyDevAndroid: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyDevIos: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyProdAndroid: 'goog_gaOrZloplZgSgUVWiKGRXUXyFXF',
    revenueCatApiKeyProdIos: 'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ',
  );

  static const BrandConfig vivotProd = BrandConfig(
    flavor: AppFlavor.vivotProd,
    brand: AppBrand.vivot,
    appName: 'Vivot',
    supportEmail: 'support@trainvent.com',
    privacyPolicyUrl: 'https://vivot.net/privacy',
    termsOfServiceUrl: 'https://vivot.net/terms',
    faqUrl: 'https://vivot.net/faq',
    shareHost: 'vivot.net',
    revenueCatApiKeyDevAndroid: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyDevIos: 'test_VEGOJICjsOpHUeSPdwjeXBwfLph',
    revenueCatApiKeyProdAndroid: 'goog_gaOrZloplZgSgUVWiKGRXUXyFXF',
    revenueCatApiKeyProdIos: 'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ',
  );
}
