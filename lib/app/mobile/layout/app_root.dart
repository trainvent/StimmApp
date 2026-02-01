import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/widget_tree.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/email_confirmation_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/set_user_details_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/welcome_page.dart'
    show WelcomePage;
import 'package:stimmapp/app/mobile/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class AuthLayout extends StatefulWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  Stream<UserProfile?>? _profileStream;
  String? _profileStreamUid;

  Stream<UserProfile?> _getProfileStream(String uid) {
    // Only create a new stream if the UID has changed or we don't have one yet.
    // This prevents the StreamBuilder from resetting to 'waiting' when the
    // outer widget rebuilds (e.g. due to token refresh).
    if (_profileStream == null || _profileStreamUid != uid) {
      _profileStreamUid = uid;
      _profileStream = UserRepository.create().watchById(uid);
    }
    return _profileStream!;
  }

  @override
  Widget build(BuildContext context) {
    // Using idTokenChanges ensures we catch the token refresh event
    // triggered after email verification.
    return StreamBuilder<User?>(
      stream: authService.firebaseAuth.idTokenChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }

        final user = snapshot.data;

        if (user != null) {
          if (!user.emailVerified) {
            // If user is logged in but email is not verified, show confirmation page
            return const EmailConfirmationPage();
          }

          // If email is verified, proceed to check user profile
          return StreamBuilder<UserProfile?>(
            stream: _getProfileStream(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingPage();
              }
              final profile = profileSnapshot.data;
              if (profile != null) {
                return const WidgetTree();
              }
              return const SetUserDetailsPage();
            },
          );
        }

        // Reset stream cache when user logs out
        _profileStream = null;
        _profileStreamUid = null;

        return widget.pageIfNotConnected ?? const WelcomePage();
      },
    );
  }
}
