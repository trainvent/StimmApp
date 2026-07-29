import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'package:stimmapp/core/theme/app_theme.dart';

void main() {
  test('standard button themes use the small app radius', () {
    final theme = AppTheme.lightFor(AppColorTheme.trainvent);
    final expected = BorderRadius.circular(AppRadii.small);

    expect(_borderRadius(theme.elevatedButtonTheme.style), expected);
    expect(_borderRadius(theme.outlinedButtonTheme.style), expected);
    expect(_borderRadius(theme.filledButtonTheme.style), expected);
  });
}

BorderRadiusGeometry? _borderRadius(ButtonStyle? style) {
  final shape = style?.shape?.resolve(<WidgetState>{});
  return switch (shape) {
    RoundedRectangleBorder(:final borderRadius) => borderRadius,
    _ => null,
  };
}
