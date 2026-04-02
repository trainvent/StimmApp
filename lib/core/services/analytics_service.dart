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
}
