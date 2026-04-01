import 'package:flutter/material.dart';
import 'package:stimmapp/core/config/environment.dart';

class IConst {
  static const String themeModeKey = 'isDarkMode';
  static const String themeSchemeKey = 'themeScheme';
  static const String localeKey = 'locale';
  static const String active = 'active';
  static const String closed = 'closed';

  static const Color appColor = Colors.green;
  static const Color lightColor = Colors.teal;

  static const String adminEmail = 'service@trainvent.com';
  static const String ownerEmail = 'leon.marquardt@gmx.de';
  static const Set<String> alwaysProEmails = <String>{adminEmail, ownerEmail};
  static const String noreplyEmail = 'noreply@trainvent.com';

  // Legacy Google Places API key.
  static const String googlePlacesApiKey =
      'AIzaSyC2FIfql1gfwTanWRLCMU3ixmJkzpSIN8M';

  // Preferred address search provider key.
  // Supply via:
  // flutter run --dart-define=TOMTOM_SEARCH_API_KEY=...
  static const String tomTomSearchApiKey = 'IAa218B56ALkr3sDdVUpSkhbChKbFVWG';

  static const String googleAdMobAppId =
      'ca-app-pub-6799570171188466~3945205436';
  static const String googleAdMobBannerAdUnitId =
      'ca-app-pub-6799570171188466/8441562649';
  static const String googleAdMobAppIdIos =
      'ca-app-pub-6799570171188466~3626151987';
  static const String googleAdMobBannerAdUnitIdIos =
      'ca-app-pub-6799570171188466/9960752746';

  static const String imapServer = "imap.ionos.de";

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

  static const String _revenueCatApiKeyDevAndroid =
      'test_VEGOJICjsOpHUeSPdwjeXBwfLph';
  static const String _revenueCatApiKeyDevIos =
      'test_VEGOJICjsOpHUeSPdwjeXBwfLph';
  static const String _revenueCatApiKeyDevWeb =
      "rcb_sb_ecbYmpaiHqdSmuzpyvPMWXoMo";
  static const String _revenueCatApiKeyProdAndroid =
      'goog_gaOrZloplZgSgUVWiKGRXUXyFXF';
  static const String _revenueCatApiKeyProdIos =
      'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ';
  static const String _revenueCatApiKeyProdWeb =
      "rcb_nqCHzNIGqKhyjbDzNRvTeKcioUWQ";

  static String get revenueCatApiKeyDevAndroid => _revenueCatApiKeyDevAndroid;
  static String get revenueCatApiKeyDevIos => _revenueCatApiKeyDevIos;
  static String get revenueCatApiKeyDevWeb => _revenueCatApiKeyDevWeb;
  static String get revenueCatApiKeyProdAndroid => _revenueCatApiKeyProdAndroid;
  static String get revenueCatApiKeyProdIos => _revenueCatApiKeyProdIos;
  static String get revenueCatApiKeyProdWeb => _revenueCatApiKeyProdWeb;

  static const String testMail = "testLeMarq@gmx.de";
  static const String testSecurePassword = "8dsDk3,2a";
  static const String testweakPassword = "12345678";
  static const String testName = "Dummy";
  static const String testSurname = "NPC";
  static const String testLivingAddress =
      "Hauptbahnhof, Bielefeld, Deutschland";
}
