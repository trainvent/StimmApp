import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';

Future<void> updateUsername(String username) async {
  final normalized = normalizeUsername(username);

  final userRepository = UserRepository.create();
  final uid = authService.currentUser!.uid;
  final userProfile = await userRepository.getById(uid);
  if (userProfile?.isGoogleSyncActive == true) {
    throw StateError(
      'The username is managed by Google profile synchronization.',
    );
  }
  if (userProfile != null) {
    await userRepository.upsertWithUniqueUsername(
      userProfile.copyWith(displayName: normalized),
    );
  } else {
    await userRepository.upsertWithUniqueUsername(
      UserProfile(uid: uid, displayName: normalized),
    );
  }
  await authService.updateUsername(username: normalized);
}
