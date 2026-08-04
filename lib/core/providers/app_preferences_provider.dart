import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/core/services/crash_reporting_service.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final themeSchemeProvider =
    NotifierProvider<ThemeSchemeController, AppColorTheme?>(
      ThemeSchemeController.new,
    );

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

final showPetitionReasonProvider =
    NotifierProvider<ShowPetitionReasonController, bool>(
      ShowPetitionReasonController.new,
    );

final analyticsCollectionEnabledProvider =
    NotifierProvider<AnalyticsCollectionController, bool>(
      AnalyticsCollectionController.new,
    );

final crashLogsEnabledProvider = NotifierProvider<CrashLogsController, bool>(
  CrashLogsController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void initialize(ThemeMode mode) {
    state = mode;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_persistThemeMode(mode));
  }
}

class ThemeSchemeController extends Notifier<AppColorTheme?> {
  @override
  AppColorTheme? build() => AppColorTheme.trainvent;

  void initialize(AppColorTheme? theme) {
    state = theme;
  }

  void setThemeScheme(AppColorTheme theme) {
    state = theme;
    unawaited(_persistThemeScheme(theme));
  }
}

class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void initialize(Locale? locale) {
    state = locale;
    _applyBrand(locale);
  }

  void setLocale(Locale? locale) {
    state = locale;
    _applyBrand(locale);
    unawaited(_persistLocale(locale));
  }
}

class ShowPetitionReasonController extends Notifier<bool> {
  @override
  bool build() => false;

  void initialize(bool enabled) {
    state = enabled;
  }

  void setEnabled(bool enabled) {
    state = enabled;
    unawaited(_persistShowPetitionReason(enabled));
  }
}

class AnalyticsCollectionController extends Notifier<bool> {
  @override
  bool build() => false;

  void initialize(bool enabled) {
    state = enabled;
    unawaited(AnalyticsService.instance.setCollectionEnabled(enabled));
  }

  void setEnabled(bool enabled) {
    state = enabled;
    unawaited(_persistAnalyticsCollection(enabled));
  }
}

class CrashLogsController extends Notifier<bool> {
  @override
  bool build() => false;

  void initialize(bool enabled) {
    state = enabled;
    unawaited(CrashReportingService.instance.setCollectionEnabled(enabled));
  }

  void setEnabled(bool enabled) {
    state = enabled;
    unawaited(_persistCrashLogs(enabled));
  }
}

void _applyBrand(Locale? locale) {
  Environment.applyBrandForLocale(
    locale: locale,
    webHost: kIsWeb ? Uri.base.host : null,
  );
}

String _localeToString(Locale? locale) {
  if (locale == null) return '';
  return (locale.countryCode == null || locale.countryCode!.isEmpty)
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.light:
      return 'light';
    case ThemeMode.system:
      return 'system';
  }
}

Future<void> _updateCurrentUser(Map<String, Object?> data) async {
  final user = authService.currentUser;
  if (user == null) return;
  try {
    await UserRepository.create().update(user.uid, data);
  } catch (e) {
    debugPrint('[AppPreferences] Error syncing setting: $e');
  }
}

Future<void> _persistThemeMode(ThemeMode mode) async {
  final modeStr = _themeModeToString(mode);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(IConst.themeModeKey, modeStr);
  await _updateCurrentUser({'themeMode': modeStr});
}

Future<void> _persistThemeScheme(AppColorTheme theme) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(IConst.themeSchemeKey, theme.data.id);
  await _updateCurrentUser({'themeScheme': theme.data.id});
}

Future<void> _persistLocale(Locale? locale) async {
  final localeStr = _localeToString(locale);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(IConst.localeKey, localeStr);
  debugPrint('[AppPreferences] persisted locale: $localeStr');
  await _updateCurrentUser({'locale': localeStr});
}

Future<void> _persistShowPetitionReason(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showPetitionReason', enabled);
  await _updateCurrentUser({'showPetitionReason': enabled});
}

Future<void> _persistAnalyticsCollection(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(IConst.analyticsCollectionEnabledKey, enabled);
  await AnalyticsService.instance.setCollectionEnabled(enabled);
  await _updateCurrentUser({'analyticsCollectionEnabled': enabled});
}

Future<void> _persistCrashLogs(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(IConst.crashLogsEnabledKey, enabled);
  await CrashReportingService.instance.setCollectionEnabled(enabled);
  await _updateCurrentUser({'sendCrashLogs': enabled});
}
