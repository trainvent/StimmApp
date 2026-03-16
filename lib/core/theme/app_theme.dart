import 'package:flutter/material.dart';
import '../constants/dimension_constants.dart';
import 'app_text_styles.dart';
import 'app_color_scheme.dart';

class AppTheme {
  static ThemeData lightFor(AppColorTheme theme) {
    return _buildTheme(
      scheme: ColorScheme.fromSeed(
        seedColor: theme.data.seedColor,
        brightness: Brightness.light,
      ),
      isDark: false,
    );
  }

  static ThemeData darkFor(AppColorTheme theme) {
    return _buildTheme(
      scheme: ColorScheme.fromSeed(
        seedColor: theme.data.seedColor,
        brightness: Brightness.dark,
      ),
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final onPrimary =
        ThemeData.estimateBrightnessForColor(scheme.primary) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final onSecondary =
        ThemeData.estimateBrightnessForColor(scheme.secondary) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: isDark
            ? const Color(0x33FFFFFF)
            : const Color(0x33000000),
        selectionHandleColor: isDark ? Colors.white : Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(DConst.kBorderRadius10),
          ),
        ),
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.primary,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? Colors.white : Colors.black,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
        indicatorColor: isDark ? Colors.white : Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DConst.kBorderRadius10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: onPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: onSecondary,
      ),
    );
  }
}
