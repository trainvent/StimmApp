import 'package:stimmapp/core/config/environment.dart';

class IConst {
  static const String themeModeKey = 'isDarkMode';
  static const String themeSchemeKey = 'themeScheme';
  static const String localeKey = 'locale';
  static const String analyticsCollectionEnabledKey =
      'analyticsCollectionEnabled';
  static const String active = 'active';
  static const String closed = 'closed';

  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: '',
  );
  static const String ownerEmail = String.fromEnvironment(
    'OWNER_EMAIL',
    defaultValue: '',
  );
  static Set<String> get alwaysProEmails => <String>{
    if (adminEmail.isNotEmpty) adminEmail.toLowerCase(),
    if (ownerEmail.isNotEmpty) ownerEmail.toLowerCase(),
  };
  static const String noreplyEmail = String.fromEnvironment(
    'NOREPLY_EMAIL',
    defaultValue: '',
  );

  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static const String tomTomSearchApiKey = String.fromEnvironment(
    'TOMTOM_SEARCH_API_KEY',
    defaultValue: '',
  );

  static const String googleAdMobAppId = String.fromEnvironment(
    'GOOGLE_ADMOB_APP_ID',
    defaultValue: '',
  );
  static const String googleAdMobBannerAdUnitId = String.fromEnvironment(
    'GOOGLE_ADMOB_BANNER_AD_UNIT_ID',
    defaultValue: '',
  );
  static const String googleAdMobAppIdIos = String.fromEnvironment(
    'GOOGLE_ADMOB_APP_ID_IOS',
    defaultValue: '',
  );
  static const String googleAdMobBannerAdUnitIdIos = String.fromEnvironment(
    'GOOGLE_ADMOB_BANNER_AD_UNIT_ID_IOS',
    defaultValue: '',
  );
  static const String googleAdSenseClientId = String.fromEnvironment(
    'GOOGLE_ADSENSE_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleAdSenseListTileSlotId = String.fromEnvironment(
    'ADSENSE_LIST_TILE_SLOT_ID',
    defaultValue: '',
  );

  static const String imapServer = String.fromEnvironment(
    'IMAP_SERVER',
    defaultValue: '',
  );

  static const String surveyTutorial =
      'https://www.bpb.de/system/files/dokument_pdf/M%2001.04%20Fragebogenerstellung_3.pdf';
  static const String petitionTutorial =
      'https://epetitionen.bundestag.de/epet/peteinreichen.html';

  static String get appName => Environment.appName;
  static String get supportEmail => Environment.supportEmail;
  static String get privacyPolicyUrl => Environment.privacyPolicyUrl;
  static String get privacyPolicyCrashDataUrl =>
      Environment.privacyPolicyCrashDataUrl;
  static String get privacyPolicyAdsUrl => Environment.privacyPolicyAdsUrl;
  static String get privacyPolicyCookiesUrl =>
      Environment.privacyPolicyCookiesUrl;
  static String get termsOfServiceUrl => Environment.termsOfServiceUrl;
  static String get faqUrl => Environment.faqUrl;

  static const String _revenueCatApiKeyDevAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_DEV_ANDROID',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyDevIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_DEV_IOS',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyDevWeb = String.fromEnvironment(
    'REVENUECAT_API_KEY_DEV_WEB',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyProdAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_PROD_ANDROID',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyProdIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_PROD_IOS',
    defaultValue: '',
  );
  static const String _revenueCatApiKeyProdWeb = String.fromEnvironment(
    'REVENUECAT_API_KEY_PROD_WEB',
    defaultValue: '',
  );

  static String get revenueCatApiKeyDevAndroid => _revenueCatApiKeyDevAndroid;
  static String get revenueCatApiKeyDevIos => _revenueCatApiKeyDevIos;
  static String get revenueCatApiKeyDevWeb => _revenueCatApiKeyDevWeb;
  static String get revenueCatApiKeyProdAndroid => _revenueCatApiKeyProdAndroid;
  static String get revenueCatApiKeyProdIos => _revenueCatApiKeyProdIos;
  static String get revenueCatApiKeyProdWeb => _revenueCatApiKeyProdWeb;

  static const String testMail = String.fromEnvironment(
    'TEST_MAIL',
    defaultValue: '',
  );
  static const String testSecurePassword = String.fromEnvironment(
    'TEST_SECURE_PASSWORD',
    defaultValue: '',
  );
  static const String testweakPassword = String.fromEnvironment(
    'TEST_WEAK_PASSWORD',
    defaultValue: '',
  );
  static const String testName = String.fromEnvironment(
    'TEST_NAME',
    defaultValue: 'Dummy',
  );
  static const String testSurname = String.fromEnvironment(
    'TEST_SURNAME',
    defaultValue: 'NPC',
  );
  static const String testLivingAddress = String.fromEnvironment(
    'TEST_LIVING_ADDRESS',
    defaultValue: 'Hauptbahnhof, Bielefeld, Deutschland',
  );
}
