import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

/// Provider for the AuthService instance.
/// We use the one from the service locator for now to maintain compatibility.
final authServiceProvider = Provider<AuthService>((ref) {
  return locator.authService;
});

/// Stream provider that listens to the authentication state changes.
/// This will automatically update whenever the user logs in or out.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  // Using idTokenChanges to catch token refreshes (e.g. after email verification)
  return authService.firebaseAuth.idTokenChanges();
});

/// Provider that returns the current user, or null if not logged in.
/// It's a computed provider based on authStateProvider.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Password accounts must complete StimmApp's verification-code flow.
/// Federated Google accounts have already verified control of their email.
bool requiresEmailVerification(User user) {
  if (user.emailVerified) return false;
  return !user.providerData.any(
    (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
  );
}

/// Stream provider for the current user's profile.
/// It depends on the authStateProvider.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return UserRepository.create().watchById(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => Stream.value(null),
  );
});
