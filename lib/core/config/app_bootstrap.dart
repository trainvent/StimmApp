import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/providers/profile_picture_provider.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/core/services/crash_reporting_service.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';

class AppBootstrap {
  StreamSubscription<User?>? _authSub;

  Future<void> init(WidgetRef ref) async {
    ref.read(themeModeProvider.notifier).initialize(await _loadThemeMode());
    ref.read(themeSchemeProvider.notifier).initialize(await _loadThemeScheme());
    ref.read(appLocaleProvider.notifier).initialize(await _loadLocale());
    ref
        .read(showPetitionReasonProvider.notifier)
        .initialize(await _loadPetitionReasonSetting());
    ref
        .read(analyticsCollectionEnabledProvider.notifier)
        .initialize(await _loadAnalyticsCollectionSetting());
    ref
        .read(crashLogsEnabledProvider.notifier)
        .initialize(await _loadCrashLogsSetting());

    _authSub = authService.authStateChanges.listen((user) async {
      if (user != null) {
        ProfilePictureService.instance
            .loadProfileUrl(user.uid)
            .then((url) {
              ref.read(profilePictureUrlProvider.notifier).setUrl(url);
            })
            .catchError((e) {
              debugPrint('[AppBootstrap] Error loading profile URL: $e');
              return null;
            });

        try {
          final userRepo = UserRepository.create();
          final profile = await userRepo.getById(user.uid);
          if (profile != null) {
            final countryCode = profile.countryCode?.toUpperCase();
            final hasState =
                profile.state != null && profile.state!.trim().isNotEmpty;
            if (countryCode != null && countryCode != 'DE' && hasState) {
              unawaited(
                userRepo.update(user.uid, {'state': null}).catchError((e) {
                  debugPrint('[AppBootstrap] Error clearing stale state: $e');
                }),
              );
            }
            if (profile.showPetitionReason != null) {
              ref
                  .read(showPetitionReasonProvider.notifier)
                  .setEnabled(profile.showPetitionReason!);
            }
            if (profile.analyticsCollectionEnabled != null) {
              ref
                  .read(analyticsCollectionEnabledProvider.notifier)
                  .setEnabled(profile.analyticsCollectionEnabled!);
            }
            if (profile.sendCrashLogs != null) {
              ref
                  .read(crashLogsEnabledProvider.notifier)
                  .setEnabled(profile.sendCrashLogs!);
            }
            if (profile.themeMode != null) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(_themeModeFromString(profile.themeMode!));
            }
            if (profile.themeScheme != null) {
              final theme = AppColorThemeX.fromId(profile.themeScheme);
              ref.read(themeSchemeProvider.notifier).setThemeScheme(theme);
            }
            if (profile.locale != null && profile.locale!.isNotEmpty) {
              ref
                  .read(appLocaleProvider.notifier)
                  .setLocale(_localeFromString(profile.locale!));
            }
          }
        } catch (e) {
          debugPrint('[AppBootstrap] Error syncing settings: $e');
        }
      } else {
        ref.read(profilePictureUrlProvider.notifier).clear();
      }
    });
  }

  void dispose() {
    _authSub?.cancel();
  }

  Future<ThemeMode> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(IConst.themeModeKey);
    if (modeStr != null) {
      return _themeModeFromString(modeStr);
    }

    try {
      final isDarkLegacy = prefs.getBool(IConst.themeModeKey);
      if (isDarkLegacy != null) {
        final mode = isDarkLegacy ? ThemeMode.dark : ThemeMode.light;
        await prefs.setString(IConst.themeModeKey, _themeModeToString(mode));
        return mode;
      }
    } catch (_) {
      return _themeModeFromString(prefs.getString(IConst.themeModeKey));
    }
    return ThemeMode.system;
  }

  Future<AppColorTheme?> _loadThemeScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return AppColorThemeX.fromId(prefs.getString(IConst.themeSchemeKey));
  }

  Future<bool> _loadAnalyticsCollectionSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(IConst.analyticsCollectionEnabledKey) ?? false;
    await AnalyticsService.instance.setCollectionEnabled(enabled);
    return enabled;
  }

  Future<bool> _loadCrashLogsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(IConst.crashLogsEnabledKey) ?? false;
    await CrashReportingService.instance.setCollectionEnabled(enabled);
    return enabled;
  }

  Future<Locale?> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeStr = prefs.getString(IConst.localeKey);
    if (localeStr != null && localeStr.isNotEmpty) {
      final locale = _localeFromString(localeStr);
      Environment.applyBrandForLocale(
        locale: locale,
        webHost: kIsWeb ? Uri.base.host : null,
      );
      return locale;
    }

    final defaultLocale = kIsWeb
        ? _defaultWebLocaleByHost()
        : _defaultMobileLocaleByDevice();
    Environment.applyBrandForLocale(
      locale: defaultLocale,
      webHost: kIsWeb ? Uri.base.host : null,
    );
    if (kIsWeb) {
      debugPrint(
        '[AppBootstrap] no stored locale, defaulting web locale to '
        '${defaultLocale.languageCode} for host ${Uri.base.host}',
      );
    }
    return defaultLocale;
  }

  Future<bool> _loadPetitionReasonSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showPetitionReason') ?? false;
  }

  Locale? _localeFromString(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  Locale _defaultWebLocaleByHost() {
    final host = Uri.base.host.toLowerCase();
    if (host == 'stimmapp.net' || host.endsWith('.stimmapp.net')) {
      return const Locale('de');
    }
    if (host == 'vivot.net' || host.endsWith('.vivot.net')) {
      return const Locale('en');
    }
    return _defaultLocaleFromDevice();
  }

  Locale _defaultMobileLocaleByDevice() {
    return _defaultLocaleFromDevice();
  }

  Locale _defaultLocaleFromDevice() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode.toLowerCase();
    if (languageCode == 'de') return const Locale('de');
    if (languageCode == 'en') return const Locale('en');

    final countryCode = locale.countryCode?.toUpperCase();
    return countryCode != null && countryCode != 'DE'
        ? const Locale('en')
        : const Locale('de');
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

  ThemeMode _themeModeFromString(String? s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}
