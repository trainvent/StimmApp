import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
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
      themeModeNotifier.value,
      appLocale.value,
    );

    // Persist runtime locale changes
    appLocale.addListener(_onLocaleChanged);
    showPetitionReasonNotifier.addListener(_onPetitionReasonChanged);
    themeModeNotifier.addListener(_onThemeChanged);

    // Load profile URL when user signs in and clear on sign-out
    _authSub = authService.authStateChanges.listen((user) async {
      if (user != null) {
        ProfilePictureService.instance.loadProfileUrl(user.uid).catchError((e) {
          debugPrint('[AppBootstrap] Error loading profile URL: $e');
          return null;
        });
        
        // Sync settings from Firestore
        try {
          final userRepo = UserRepository.create();
          final profile = await userRepo.getById(user.uid);
          if (profile != null) {
            final countryCode = profile.countryCode?.toUpperCase();
            final hasState =
                profile.state != null && profile.state!.trim().isNotEmpty;
            if (countryCode != null && countryCode != 'DE' && hasState) {
              // Self-heal stale profile data: outside Germany, state must be null.
              unawaited(
                userRepo.update(user.uid, {'state': null}).catchError((e) {
                  debugPrint('[AppBootstrap] Error clearing stale state: $e');
                }),
              );
            }
            if (profile.showPetitionReason != null) {
              showPetitionReasonNotifier.value = profile.showPetitionReason!;
            }
            if (profile.themeMode != null) {
              themeModeNotifier.value = _themeModeFromString(profile.themeMode!);
              // Sync legacy notifier for backward compatibility if needed
              isDarkModeNotifier.value = themeModeNotifier.value == ThemeMode.dark;
            }
            if (profile.locale != null && profile.locale!.isNotEmpty) {
              appLocale.value = _localeFromString(profile.locale!);
            }
          }
        } catch (e) {
          debugPrint('[AppBootstrap] Error syncing settings: $e');
        }
      } else {
        ProfilePictureService.instance.profileUrlNotifier.value = null;
      }
    });
  }

  void dispose() {
    _authSub?.cancel();
    appLocale.removeListener(_onLocaleChanged);
    showPetitionReasonNotifier.removeListener(_onPetitionReasonChanged);
    themeModeNotifier.removeListener(_onThemeChanged);
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
    
    // Sync to Firestore if logged in
    final user = authService.currentUser;
    if (user != null) {
      try {
        final userRepo = UserRepository.create();
        await userRepo.update(user.uid, {'locale': toSave});
      } catch (e) {
        debugPrint('[AppBootstrap] Error syncing locale to Firestore: $e');
      }
    }
  }

  void _onPetitionReasonChanged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPetitionReason', showPetitionReasonNotifier.value);
    
    // Sync to Firestore if logged in
    final user = authService.currentUser;
    if (user != null) {
      try {
        final userRepo = UserRepository.create();
        await userRepo.update(user.uid, {'showPetitionReason': showPetitionReasonNotifier.value});
      } catch (e) {
        debugPrint('[AppBootstrap] Error syncing petition reason setting to Firestore: $e');
      }
    }
  }

  void _onThemeChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = _themeModeToString(themeModeNotifier.value);
    await prefs.setString(IConst.themeModeKey, modeStr);
    
    // Sync legacy notifier
    isDarkModeNotifier.value = themeModeNotifier.value == ThemeMode.dark;
    
    // Sync to Firestore if logged in
    final user = authService.currentUser;
    if (user != null) {
      try {
        final userRepo = UserRepository.create();
        await userRepo.update(user.uid, {'themeMode': modeStr});
      } catch (e) {
        debugPrint('[AppBootstrap] Error syncing theme to Firestore: $e');
      }
    }
  }

  Future<void> _initThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Check for new string-based key first
    final String? modeStr = prefs.getString(IConst.themeModeKey);
    if (modeStr != null) {
      themeModeNotifier.value = _themeModeFromString(modeStr);
    } else {
      // Fallback to old boolean key migration
      try {
         // Try reading as bool (legacy)
         final bool? isDarkLegacy = prefs.getBool(IConst.themeModeKey);
         if (isDarkLegacy != null) {
           themeModeNotifier.value = isDarkLegacy ? ThemeMode.dark : ThemeMode.light;
           // Migrate to string immediately
           await prefs.setString(IConst.themeModeKey, _themeModeToString(themeModeNotifier.value));
         } else {
           themeModeNotifier.value = ThemeMode.system;
         }
      } catch (e) {
        // If it fails, it might be because it's already a string
        final String? modeStr = prefs.getString(IConst.themeModeKey);
        themeModeNotifier.value = _themeModeFromString(modeStr ?? 'system');
      }
    }
    isDarkModeNotifier.value = themeModeNotifier.value == ThemeMode.dark;
  }

  Future<void> _initLocale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? localeStr = prefs.getString(IConst.localeKey);
    if (localeStr != null && localeStr.isNotEmpty) {
      appLocale.value = _localeFromString(localeStr);
    } else {
      final defaultLocale = kIsWeb
          ? _defaultWebLocaleByHost()
          : (Environment.isVivot ? const Locale('en') : const Locale('de'));
      appLocale.value = defaultLocale;
      if (kIsWeb) {
        debugPrint(
          '[AppBootstrap] no stored locale, defaulting web locale to '
          '${defaultLocale.languageCode} for host ${Uri.base.host}',
        );
      }
    }
  }

  Locale _defaultWebLocaleByHost() {
    final host = Uri.base.host.toLowerCase();
    if (host == 'stimmapp.net' || host.endsWith('.stimmapp.net')) {
      return const Locale('de');
    }
    if (host == 'vivot.net' || host.endsWith('.vivot.net')) {
      return const Locale('en');
    }
    return Environment.isVivot ? const Locale('en') : const Locale('de');
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

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark: return 'dark';
      case ThemeMode.light: return 'light';
      case ThemeMode.system: return 'system';
    }
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.system;
    }
  }
}
