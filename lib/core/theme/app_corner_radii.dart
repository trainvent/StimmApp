import 'package:flutter/material.dart';

import '../constants/dimension_constants.dart';

/// Shared large corners, supplied by Riverpod when device data is available.
@immutable
class AppCornerRadii extends ThemeExtension<AppCornerRadii> {
  const AppCornerRadii({
    this.large = const BorderRadius.all(Radius.circular(AppRadii.large)),
  });

  final BorderRadius large;

  @override
  AppCornerRadii copyWith({BorderRadius? large}) =>
      AppCornerRadii(large: large ?? this.large);

  @override
  AppCornerRadii lerp(covariant AppCornerRadii? other, double t) {
    if (other == null) return this;
    return AppCornerRadii(large: BorderRadius.lerp(large, other.large, t)!);
  }
}

extension AppCornerRadiiContext on BuildContext {
  /// Use this for large surfaces; the theme updates when device data arrives.
  BorderRadius get largeBorderRadius =>
      (Theme.of(this).extension<AppCornerRadii>() ?? const AppCornerRadii())
          .large;
}
