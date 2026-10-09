import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'package:stimmapp/core/theme/app_corner_radii.dart';
import 'package:stimmapp/core/theme/app_theme.dart';

void main() {
  test('standard button themes use the small app radius', () {
    final theme = AppTheme.lightFor(AppColorTheme.trainvent);
    final expected = BorderRadius.circular(AppRadii.small);

    expect(_borderRadius(theme.elevatedButtonTheme.style), expected);
    expect(_borderRadius(theme.outlinedButtonTheme.style), expected);
    expect(_borderRadius(theme.filledButtonTheme.style), expected);
  });

  test('both themes expose device corners while preserving small buttons', () {
    const corners = AppCornerRadii(
      large: BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(42),
        bottomLeft: Radius.circular(44),
        bottomRight: Radius.circular(46),
      ),
    );
    for (final theme in [
      AppTheme.lightFor(AppColorTheme.trainvent, cornerRadii: corners),
      AppTheme.darkFor(AppColorTheme.trainvent, cornerRadii: corners),
    ]) {
      expect(theme.extension<AppCornerRadii>()?.large, corners.large);
      expect(
        (theme.dialogTheme.shape as RoundedRectangleBorder).borderRadius,
        corners.large,
      );
      expect(
        (theme.bottomSheetTheme.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.only(
          topLeft: corners.large.topLeft,
          topRight: corners.large.topRight,
        ),
      );
      expect(
        _borderRadius(theme.filledButtonTheme.style),
        BorderRadius.circular(AppRadii.small),
      );
    }
  });
}

BorderRadiusGeometry? _borderRadius(ButtonStyle? style) {
  final shape = style?.shape?.resolve(<WidgetState>{});
  return switch (shape) {
    RoundedRectangleBorder(:final borderRadius) => borderRadius,
    _ => null,
  };
}
