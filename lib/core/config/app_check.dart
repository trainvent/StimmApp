import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/config/environment.dart';

/// Install providers before any Firebase service makes requests.
Future<void> configureAppCheck() async {
  final appCheck = FirebaseAppCheck.instance;
  if (kIsWeb) {
    const overrideSiteKey = String.fromEnvironment(
      'APP_CHECK_RECAPTCHA_ENTERPRISE_SITE_KEY',
    );
    // Site keys are public. Each Firebase project has its own restricted key.
    final siteKey = overrideSiteKey.isNotEmpty
        ? overrideSiteKey
        : Environment.isDev
        ? '6LeYN-otAAAAAIO8iXIlMgatyAdOhaG5rniwnic_'
        : '6Lck_OktAAAAACXRBgp6E6OzIfh9UqWeiFMGO3ht';
    if (kDebugMode) {
      await appCheck.activate(providerWeb: WebDebugProvider());
    } else {
      await appCheck.activate(
        providerWeb: ReCaptchaEnterpriseProvider(siteKey),
      );
    }
  } else if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await appCheck.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } else {
    return;
  }
  await appCheck.setTokenAutoRefreshEnabled(true);
  debugPrint(
    '[AppCheck] ${kDebugMode ? 'Debug' : 'Production'} provider activated',
  );
  if (kDebugMode) {
    // Also triggers the SDK's debug-token registration message. Never print
    // the resulting attestation token, and do not delay startup for networking.
    unawaited(_checkDebugToken(appCheck));
  }
}

Future<void> _checkDebugToken(FirebaseAppCheck appCheck) async {
  try {
    final token = await appCheck.getToken();
    debugPrint('[AppCheck] Token ${token == null ? 'missing' : 'verified'}');
  } on FirebaseException catch (error) {
    final message = error.message?.replaceAll(
      RegExp(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'),
      '[redacted]',
    );
    debugPrint(
      '[AppCheck] Token verification failed (${error.code}): $message. '
      'Check API/provider setup and this device\'s debug-token registration.',
    );
  } catch (_) {
    debugPrint('[AppCheck] Token verification failed. Check provider setup.');
  }
}
