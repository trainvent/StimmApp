import 'package:corner_radius_plugin/corner_radius_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/dimension_constants.dart';
import '../theme/app_corner_radii.dart';

/// Cached for this ProviderScope. Invalidate after display metrics change.
/// Plugin-specific types stay here so widgets do not depend on the package.
final screenCornerRadiusProvider = FutureProvider<BorderRadius?>((ref) async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return null;
  }

  try {
    // Android window insets are available after the first frame is attached.
    await WidgetsBinding.instance.endOfFrame;
    if (!ref.mounted) return null;
    final radius = await CornerRadiusPlugin.init(
      defaultRadius: AppRadii.large,
    ).timeout(const Duration(seconds: 2));

    double validRadius(double value) =>
        value.isFinite && value > 0 ? value : AppRadii.large;

    return BorderRadius.only(
      topLeft: Radius.circular(validRadius(radius.topLeft)),
      topRight: Radius.circular(validRadius(radius.topRight)),
      bottomLeft: Radius.circular(validRadius(radius.bottomLeft)),
      bottomRight: Radius.circular(validRadius(radius.bottomRight)),
    );
  } catch (error) {
    // Missing native registration, unsupported devices, and plugin failures
    // must not prevent the app from starting.
    debugPrint('[ScreenCornerRadius] Using fallback: $error');
    return null;
  }
});

/// Synchronous theme value, including a fallback during loading and failures.
final appCornerRadiiProvider = Provider<AppCornerRadii>((ref) {
  final radius = ref.watch(screenCornerRadiusProvider).value;
  return radius == null
      ? const AppCornerRadii()
      : AppCornerRadii(large: radius);
});
