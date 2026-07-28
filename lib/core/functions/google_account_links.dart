import 'package:url_launcher/url_launcher.dart';

Uri googleProfileUri(String? email) {
  final accountEmail = email?.trim();
  return Uri.https(
    'myaccount.google.com',
    '/profile',
    accountEmail?.isNotEmpty == true
        ? <String, String>{'authuser': accountEmail!}
        : null,
  );
}

Future<bool> openGoogleProfile(String? email) {
  return launchUrl(
    googleProfileUri(email),
    mode: LaunchMode.externalApplication,
  );
}
