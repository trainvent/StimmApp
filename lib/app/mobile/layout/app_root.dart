import 'package:flutter/foundation.dart';
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
import 'package:stimmapp/core/services/purchases_service.dart';

class AuthLayout extends ConsumerWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Sync RevenueCat app user with Firebase auth user.
    ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;
      if (prevUser?.uid == nextUser?.uid) return;
      PurchasesService.instance.syncAppUser(nextUser?.uid);
      if (nextUser != null) {
        // Ensure we don't miss an entitlement event that happened before the listener attached.
        Future.microtask(() async {
          await PurchasesService.instance.refreshCustomerInfo();
          await syncSubscriptionStatus(
            nextUser.uid,
            PurchasesService.instance.currentStatus,
          );
        });
      }
    });

    // Listen to entitlement changes and sync to Firestore
    ref.listen(entitlementStreamProvider, (previous, next) {
      final user = ref.read(currentUserProvider);
      if (kDebugMode) {
        debugPrint(
          'AuthLayout entitlement listener: user=${user?.uid} '
          'hasValue=${next.hasValue} value=${next.value}',
        );
      }
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
