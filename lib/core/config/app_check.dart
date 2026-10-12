import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  const diagnosticsEnabled = bool.fromEnvironment('APP_CHECK_DIAGNOSTICS');
  if (kDebugMode || diagnosticsEnabled) {
    // Also triggers the SDK's debug-token registration message. Never print
    // the resulting attestation token, and do not delay startup for networking.
    unawaited(_checkToken(appCheck, forceRefresh: diagnosticsEnabled));
  }
}

Future<void> _checkToken(
  FirebaseAppCheck appCheck, {
  required bool forceRefresh,
}) async {
  try {
    final token = await appCheck.getToken(forceRefresh);
    debugPrint('[AppCheck] Token ${token == null ? 'missing' : 'verified'}');
    if (forceRefresh) {
      await _recordValidationResult(
        token?.isNotEmpty == true ? 'verified' : 'missing',
      );
    }
  } on FirebaseException catch (error) {
    final message = error.message?.replaceAll(
      RegExp(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'),
      '[redacted]',
    );
    debugPrint(
      '[AppCheck] Token verification failed (${error.code}): $message. '
      'Check API/provider setup, signing, and debug-token registration '
      'when using the debug provider.',
    );
    if (forceRefresh) await _recordValidationResult('failed', code: error.code);
  } catch (_) {
    debugPrint('[AppCheck] Token verification failed. Check provider setup.');
    if (forceRefresh) await _recordValidationResult('failed');
  }
}

/// A token-free artifact for signed device runs whose Dart logs are unavailable.
Future<void> _recordValidationResult(String status, {String? code}) async {
  if (kIsWeb) return;
  try {
    final directory = await getApplicationDocumentsDirectory();
    await File('${directory.path}/app-check-validation.json').writeAsString(
      jsonEncode({
        'project': Firebase.app().options.projectId,
        'buildMode': kDebugMode
            ? 'debug'
            : kProfileMode
            ? 'profile'
            : 'release',
        'status': status,
        'errorCode': code,
        'forcedRefresh': true,
        'checkedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  } catch (_) {
    debugPrint('[AppCheck] Could not save validation result.');
  }
}
