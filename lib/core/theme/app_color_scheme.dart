import 'package:flutter/material.dart';

enum AppColorTheme {
  stimm,
  trainvent,
  ocean,
  sunset,
  rose,
  amber,
  plum,
  slate,
  mint,
  sky,

}

@immutable
class AppColorThemeData {
  const AppColorThemeData({
    required this.id,
    required this.label,
    required this.seedColor,
    required this.previewColors,
    this.primaryForegroundColor,
    this.secondaryForegroundColor,
  });

  final String id;
  final String label;
  final Color seedColor;
  final List<Color> previewColors;
  final Color? primaryForegroundColor;
  final Color? secondaryForegroundColor;
}

extension AppColorThemeX on AppColorTheme {
  AppColorThemeData get data {
    switch (this) {
      case AppColorTheme.stimm:
        return const AppColorThemeData(
          id: 'stimm',
          label: 'Forest',
          seedColor: Color(0xFF2E7D32),
          previewColors: [
            Color(0xFF2E7D32),
            Color(0xFF26A69A),
            Color(0xFFE8F5E9),
            Color(0xFF102A12),
          ],
        );
      case AppColorTheme.ocean:
        return const AppColorThemeData(
          id: 'ocean',
          label: 'Ocean',
          seedColor: Color(0xFF1565C0),
          previewColors: [
            Color(0xFF1565C0),
            Color(0xFF00ACC1),
            Color(0xFFE3F2FD),
            Color(0xFF0B1F33),
          ],
        );
      case AppColorTheme.sunset:
        return const AppColorThemeData(
          id: 'sunset',
          label: 'Sunset',
          seedColor: Color(0xFFEF6C00),
          previewColors: [
            Color(0xFFEF6C00),
            Color(0xFFFF8A65),
            Color(0xFFFFF3E0),
            Color(0xFF31130A),
          ],
        );
      case AppColorTheme.rose:
        return const AppColorThemeData(
          id: 'rose',
          label: 'Rose',
          seedColor: Color(0xFFC2185B),
          previewColors: [
            Color(0xFFC2185B),
            Color(0xFFE57399),
            Color(0xFFFCE4EC),
            Color(0xFF2D0E1D),
          ],
        );
      case AppColorTheme.amber:
        return const AppColorThemeData(
          id: 'amber',
          label: 'Amber',
          seedColor: Color(0xFFF9A825),
          previewColors: [
            Color(0xFFF9A825),
            Color(0xFFFFD54F),
            Color(0xFFFFF8E1),
            Color(0xFF332508),
          ],
        );
      case AppColorTheme.plum:
        return const AppColorThemeData(
          id: 'plum',
          label: 'Plum',
          seedColor: Color(0xFF6A1B9A),
          previewColors: [
            Color(0xFF6A1B9A),
            Color(0xFFAB47BC),
            Color(0xFFF3E5F5),
            Color(0xFF1D1026),
          ],
        );
      case AppColorTheme.slate:
        return const AppColorThemeData(
          id: 'slate',
          label: 'Slate',
          seedColor: Color(0xFF455A64),
          previewColors: [
            Color(0xFF455A64),
            Color(0xFF78909C),
            Color(0xFFECEFF1),
            Color(0xFF141A1D),
          ],
        );
      case AppColorTheme.mint:
        return const AppColorThemeData(
          id: 'mint',
          label: 'Mint',
          seedColor: Color(0xFFA5D6A7),
          previewColors: [
            Color(0xFFA5D6A7),
            Color(0xFFC8E6C9),
            Color(0xFFE8F5E9),
            Color(0xFFF6FFF6),
          ],
          primaryForegroundColor: Colors.black,
          secondaryForegroundColor: Colors.black,
        );
      case AppColorTheme.sky:
        return const AppColorThemeData(
          id: 'sky',
          label: 'Sky',
          seedColor: Color(0xFF90CAF9),
          previewColors: [
            Color(0xFF90CAF9),
            Color(0xFFBBDEFB),
            Color(0xFFE3F2FD),
            Color(0xFFF5FBFF),
          ],
          primaryForegroundColor: Colors.black,
          secondaryForegroundColor: Colors.black,
        );
      case AppColorTheme.trainvent:
        return const AppColorThemeData(
          id: 'trainvent',
          label: 'Trainvent',
          seedColor: Color(0xFFB71C1C),
          previewColors: [
            Color(0xFFB71C1C),
            Color(0xFFFFD700),
            Color(0xFF40E0D0),
            Color(0xFF111111),
          ],
        );
    }
  }

  static AppColorTheme fromId(String? id) {
    for (final theme in AppColorTheme.values) {
      if (theme.data.id == id) {
        return theme;
      }
    }
    return AppColorTheme.trainvent;
  }
}
