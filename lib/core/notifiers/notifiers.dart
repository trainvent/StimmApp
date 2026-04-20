import 'package:flutter/material.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';

class AppData {
  //Onboarding
  static final ValueNotifier<double> onboardingSlider1Notifier = ValueNotifier(
    3.0,
  );
  static final ValueNotifier<double> onboardingSlider2Notifier = ValueNotifier(
    1.0,
  );
  static final ValueNotifier<int> onboardingCurrentIndexNotifier =
      ValueNotifier(0);

  //App
  static final ValueNotifier<bool> isAuthConnected = ValueNotifier(false);
  static final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  static final ValueNotifier<bool> isAppOutdatedNotifier = ValueNotifier(false);
  static final ValueNotifier<int> navBarCurrentIndexNotifier = ValueNotifier(0);
}

//leon
ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
// ThemeMode: system, light, dark
ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
ValueNotifier<AppColorTheme?> themeSchemeNotifier = ValueNotifier(
  AppColorTheme.trainvent,
);
// Deprecated: kept for backward compatibility if needed, but should be removed eventually
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(true);

final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);
final ValueNotifier<bool> showPetitionReasonNotifier = ValueNotifier(false);
final ValueNotifier<bool> analyticsCollectionEnabledNotifier = ValueNotifier(
  false,
);
