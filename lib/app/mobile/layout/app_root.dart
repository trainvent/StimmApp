import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/mobile/pages/main/home/widget_tree.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/email_confirmation_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/set_user_details_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/welcome_page.dart'
    show WelcomePage;
import 'package:stimmapp/app/mobile/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/subscription_provider.dart';

class AuthLayout extends ConsumerWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Listen to entitlement changes and sync to Firestore
    ref.listen(entitlementStreamProvider, (previous, next) {
      final user = ref.read(currentUserProvider);
      if (user != null && next.hasValue) {
        syncSubscriptionStatus(user.uid, next.value!);
      }
    });

    return authState.when(
      data: (user) {
        if (user == null) {
          return pageIfNotConnected ?? const WelcomePage();
        }

        if (!user.emailVerified) {
          return const EmailConfirmationPage();
        }

        final userProfileState = ref.watch(userProfileProvider);

        return userProfileState.when(
          data: (profile) {
            if (profile != null) {
              return const WidgetTree();
            }
            return const SetUserDetailsPage();
          },
          loading: () => const AppLoadingPage(),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const AppLoadingPage(),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
