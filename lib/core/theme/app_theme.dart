import 'package:flutter/material.dart';
import '../constants/dimension_constants.dart';
import '../constants/internal_constants.dart';
import 'app_text_styles.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color(0x33000000),
      selectionHandleColor: Colors.black,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DConst.kBorderRadius10)),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: IConst.appColor,
      foregroundColor: Colors.black, // Changed to black for readability
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: IConst.appColor,
        foregroundColor: Colors.black, // Changed to black for readability
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DConst.kBorderRadius10),
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: IConst.appColor,
      primary: IConst.appColor,
      onPrimary: Colors.black, // Ensure text on primary color is black
      secondary: IConst.lightColor,
      onSecondary: Colors.black, // Ensure text on secondary color is black
      brightness: Brightness.light,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Color(0x33FFFFFF),
      selectionHandleColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DConst.kBorderRadius10)),
      ),
      filled: true,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: IConst.appColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DConst.kBorderRadius10),
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: IConst.appColor,
      primary: IConst.appColor,
      onPrimary: Colors.black, // Ensure text on primary color is black
      secondary: IConst.lightColor,
      onSecondary: Colors.black, // Ensure text on secondary color is black
      brightness: Brightness.dark,
    ),
  );
}
