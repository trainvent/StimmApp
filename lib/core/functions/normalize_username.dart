import 'package:stimmapp/core/constants/app_limits.dart';

String normalizeUsername(String username) {
  final trimmed = username.trim();
  return trimmed.length > AppLimits.maxDisplayNameLength
      ? trimmed.substring(0, AppLimits.maxDisplayNameLength)
      : trimmed;
}

String usernameKeyFor(String username) =>
    normalizeUsername(username).toLowerCase();
