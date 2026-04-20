import 'package:flutter/material.dart';
import '../constants/dimension_constants.dart';
import 'app_text_styles.dart';
import 'app_color_scheme.dart';

class AppTheme {
  static ThemeData lightFor(AppColorTheme theme) {
    return _buildTheme(
      theme: theme,
      scheme: ColorScheme.fromSeed(
        seedColor: theme.data.seedColor,
        brightness: Brightness.light,
      ),
      isDark: false,
    );
  }

  static ThemeData darkFor(AppColorTheme theme) {
    return _buildTheme(
      theme: theme,
      scheme: ColorScheme.fromSeed(
        seedColor: theme.data.seedColor,
        brightness: Brightness.dark,
      ),
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required AppColorTheme theme,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final previewColors = theme.data.previewColors;
    final primary = previewColors.first;
    final secondary = previewColors.length > 1 ? previewColors[1] : primary;
    final tertiary = previewColors.length > 2 ? previewColors[2] : secondary;
    // Material ColorScheme has no dedicated "quaternary" slot; use tertiaryContainer.
    final quaternary = previewColors.length > 3 ? previewColors[3] : tertiary;

    Color onColor(Color color) {
      return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    final onPrimary = theme.data.primaryForegroundColor ?? onColor(primary);
    final onSecondary =
        theme.data.secondaryForegroundColor ?? onColor(secondary);
    final onTertiary = onColor(tertiary);
    final onQuaternary = onColor(quaternary);

    final themedScheme = scheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: quaternary,
      onTertiaryContainer: onQuaternary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: themedScheme,
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
        fillColor: isDark ? themedScheme.surfaceContainerHighest : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onPrimary,
        unselectedLabelColor: onPrimary.withValues(alpha: 0.7),
        indicatorColor: onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DConst.kBorderRadius10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
      ),
    );
  }
}
