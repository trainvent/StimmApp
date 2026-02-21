import 'package:flutter/material.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';

class AppState {
  final ThemeMode themeMode;
  final Locale? locale;
  const AppState(this.themeMode, this.locale);
}

/// Notifier that combines themeModeNotifier and appLocale into a single ValueListenable.
class AppStateNotifier extends ValueNotifier<AppState> {
  AppStateNotifier(ThemeMode themeMode, Locale? locale)
    : super(AppState(themeMode, locale)) {
    _update = _updateImpl;
    themeModeNotifier.addListener(_update);
    appLocale.addListener(_update);
  }

  late final VoidCallback _update;

  void _updateImpl() {
    value = AppState(themeModeNotifier.value, appLocale.value);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_update);
    appLocale.removeListener(_update);
    super.dispose();
  }
}
