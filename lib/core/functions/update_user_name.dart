import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

Future<void> updateUsername(String username) async {
  final normalized = username.trim();
  final clamped = normalized.length > AppLimits.maxDisplayNameLength
      ? normalized.substring(0, AppLimits.maxDisplayNameLength)
      : normalized;

  await authService.updateUsername(username: clamped);
  final userRepository = UserRepository.create();
  final uid = authService.currentUser!.uid;
  final userProfile = await userRepository.getById(uid);
  if (userProfile != null) {
    await userRepository.upsert(userProfile.copyWith(displayName: clamped));
  } else {
    await userRepository.upsert(UserProfile(uid: uid, displayName: clamped));
  }
}
