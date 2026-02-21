import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/notifiers/app_state_notifier.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/services/ad_service.dart';

class AppBootstrap {
  StreamSubscription<User?>? _authSub;
  final AdService _adService = AdService();
  AppStateNotifier? _appStateNotifier;

  Future<void> init() async {
    // load persisted theme first
    await _initThemeMode();
    // load persisted locale (if any) before creating composite notifier
    await _initLocale();
    // load persisted petition reason setting
    await _initPetitionReasonSetting();
    // initialize ads
    await _adService.initialize();

    // only create the composite notifier after persisted state is loaded
    _appStateNotifier = AppStateNotifier(
      isDarkModeNotifier.value,
      appLocale.value,
    );

    // Persist runtime locale changes
    appLocale.addListener(_onLocaleChanged);
    showPetitionReasonNotifier.addListener(_onPetitionReasonChanged);

    // Load profile URL when user signs in and clear on sign-out
    _authSub = authService.authStateChanges.listen((user) {
      if (user != null) {
        ProfilePictureService.instance.loadProfileUrl(user.uid).catchError((e) {
          debugPrint('[AppBootstrap] Error loading profile URL: $e');
          return null;
        });
      } else {
        ProfilePictureService.instance.profileUrlNotifier.value = null;
      }
    });
  }

  void dispose() {
    _authSub?.cancel();
    appLocale.removeListener(_onLocaleChanged);
    showPetitionReasonNotifier.removeListener(_onPetitionReasonChanged);
    _appStateNotifier?.dispose();
  }

  void _onLocaleChanged() async {
    final Locale? loc = appLocale.value;
    final prefs = await SharedPreferences.getInstance();
    final String toSave = (loc == null)
        ? ''
        : (loc.countryCode == null || loc.countryCode!.isEmpty)
        ? loc.languageCode
        : '${loc.languageCode}_${loc.countryCode}';
    await prefs.setString(IConst.localeKey, toSave);
    debugPrint('[AppBootstrap] persisted locale: $toSave');
  }

  void _onPetitionReasonChanged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPetitionReason', showPetitionReasonNotifier.value);
  }

  Future<void> _initThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isDark = prefs.getBool(IConst.themeModeKey);
    isDarkModeNotifier.value = isDark ?? false;
  }

  Future<void> _initLocale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localeStr = prefs.getString(IConst.localeKey);
    if (localeStr != null && localeStr.isNotEmpty) {
      appLocale.value = _localeFromString(localeStr);
    } else if (kIsWeb) {
      // Default to German on web if no preference is set
      appLocale.value = const Locale('de');
    }
  }

  Future<void> _initPetitionReasonSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    showPetitionReasonNotifier.value = prefs.getBool('showPetitionReason') ?? false;
  }

  Locale? _localeFromString(String s) {
    if (s.isEmpty) return null;
    final parts = s.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }
}
