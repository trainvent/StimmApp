import 'package:flutter/material.dart';

class IConst {
  static const String themeModeKey = 'isDarkMode';
  static const String localeKey = 'locale';
  static const String appName = 'StimmApp';
  static const String active = 'active';
  static const String closed = 'closed';

  static const Color appColor = Colors.green;
  static const Color lightColor = Colors.teal;

  static const String adminEmail = 'service@stimmapp.org';
  static const String ownerEmail = 'leon.marquardt@gmx.de';
  static const Set<String> alwaysProEmails = <String>{adminEmail, ownerEmail};
  static const String supportEmail = 'support@stimmapp.org';
  static const String noreplyEmail = 'noreply@stimmapp.org';
  static const String privacyPolicyUrl =
      'https://www.stimmapp.org/privacy-policy';
  static const String termsOfServiceUrl =
      'https://www.stimmapp.org/nutzungsbedingungen.html';
  static const String faqUrl = 'https://www.stimmapp.org/faq';

  static const String revenueCatApiKeyDevAndroid =
      'test_VEGOJICjsOpHUeSPdwjeXBwfLph';
  static const String revenueCatApiKeyDevIos =
      'test_VEGOJICjsOpHUeSPdwjeXBwfLph';
  static const String revenueCatApiKeyProdAndroid =
      'goog_gaOrZloplZgSgUVWiKGRXUXyFXF';
  static const String revenueCatApiKeyProdIos =
      'appl_IaicnIHIbjAeSXsFTiHklZRlMOJ';

  // Google Places API Key.
  // If your Firebase API key is restricted and doesn't work for Places,
  // create an unrestricted API key in Google Cloud Console and put it here.
  static const String googlePlacesApiKey =
      'AIzaSyC2FIfql1gfwTanWRLCMU3ixmJkzpSIN8M'; // Default to Android key for now

  static const String googleAdMobAppId =
      'ca-app-pub-5296065079333841~8760518694';

  static const String imapServer = "imap.ionos.de";

  static const String testMail = "testLeMarq@gmx.de";
  static const String testSecurePassword = "8dsDk3,2a";
  static const String testweakPassword = "12345678";
  static const String testName = "Dummy";
  static const String testSurname = "NPC";
  static const String testLivingAddress =
      "Hauptbahnhof, Bielefeld, Deutschland";

  static const String surveyTutorial =
      'https://www.bpb.de/system/files/dokument_pdf/M%2001.04%20Fragebogenerstellung_3.pdf';
  static const String petitionTutorial =
      'https://epetitionen.bundestag.de/epet/peteinreichen.html';
}
