import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  Future<void> configure({required bool collectionEnabled}) async {
    if (kIsWeb) {
      return;
    }

    try {
      await setCollectionEnabled(collectionEnabled);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        errorLogTool(
          exception: details.exception,
          errorCustomMessage: 'Flutter framework error',
        );
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        errorLogTool(
          exception: error,
          errorCustomMessage: 'Uncaught async error',
        );
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (error) {
      errorLogTool(
        exception: error,
        errorCustomMessage: 'Crashlytics configuration failed',
      );
    }
  }

  Future<void> setCollectionEnabled(bool enabled) async {
    if (kIsWeb) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
      debugPrint(
        '[CrashReportingService] Crashlytics collection '
        '${enabled ? 'enabled' : 'disabled'}',
      );
    } catch (error) {
      errorLogTool(
        exception: error,
        errorCustomMessage: 'Crashlytics collection setting failed',
      );
    }
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    errorLogTool(
      exception: error,
      errorCustomMessage: reason ?? 'Non-fatal error',
    );
    if (kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (reportingError) {
      errorLogTool(
        exception: reportingError,
        errorCustomMessage: 'Failed to report non-fatal error',
      );
    }
  }
}
