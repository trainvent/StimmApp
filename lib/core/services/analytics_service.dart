import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  Future<void> init() async {
    try {
      _analytics ??= FirebaseAnalytics.instance;
    } catch (error, stackTrace) {
      debugPrint('[AnalyticsService] init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await init();
      await _analytics?.setAnalyticsCollectionEnabled(enabled);
      debugPrint(
        '[AnalyticsService] Analytics collection '
        '${enabled ? 'enabled' : 'disabled'}',
      );
    } catch (error, stackTrace) {
      debugPrint('[AnalyticsService] setCollectionEnabled failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    try {
      await init();
      await _analytics?.logEvent(
        name: name,
        parameters: _sanitizeParameters(parameters),
      );
    } catch (error, stackTrace) {
      debugPrint('[AnalyticsService] logEvent($name) failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is String || value is int || value is double) {
        sanitized[key] = value;
        return;
      }
      if (value is bool) {
        sanitized[key] = value ? 1 : 0;
        return;
      }
      sanitized[key] = value.toString();
    });
    return sanitized;
  }

  Future<void> logAuthFlowOpened(String flow) {
    return logEvent('auth_flow_opened', parameters: {'flow': flow});
  }

  Future<void> logAuthResult({
    required String action,
    required bool success,
    String? errorCode,
  }) {
    return logEvent(
      'auth_result',
      parameters: {
        'action': action,
        'success': success,
        'error_code': errorCode,
      },
    );
  }

  Future<void> logVerificationCodeSent(String trigger) {
    return logEvent('verification_code_sent', parameters: {'trigger': trigger});
  }

  Future<void> logEmailVerified() {
    return logEvent('email_verified');
  }

  Future<void> logProfileCompleted({
    String? countryCode,
    bool supportsStateScope = false,
  }) {
    return logEvent(
      'profile_completed',
      parameters: {
        'country_code': countryCode,
        'state_scope': supportsStateScope,
      },
    );
  }

  Future<void> logPetitionCreated({
    required String scopeType,
    required bool hasImage,
  }) {
    return logEvent(
      'petition_created',
      parameters: {'scope_type': scopeType, 'has_image': hasImage},
    );
  }

  Future<void> logPollCreated({
    required String scopeType,
    required String visibility,
    required int optionCount,
  }) {
    return logEvent(
      'poll_created',
      parameters: {
        'scope_type': scopeType,
        'visibility': visibility,
        'option_count': optionCount,
      },
    );
  }

  Future<void> logSearchUsed({
    required int queryLength,
    required int filterCount,
  }) {
    return logEvent(
      'search_used',
      parameters: {'query_length': queryLength, 'filter_count': filterCount},
    );
  }

  Future<void> logPaywallOpened(String source) {
    return logEvent('paywall_opened', parameters: {'source': source});
  }

  Future<void> logPaywallResult({
    required String source,
    required bool success,
  }) {
    return logEvent(
      'paywall_result',
      parameters: {'source': source, 'success': success},
    );
  }
}
