import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/mobile/pages/main/home/widget_tree.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/community_guidelines_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/email_confirmation_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/set_user_details_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/welcome_page.dart'
    show WelcomePage;
import 'package:stimmapp/app/mobile/pages/others/app_loading_page.dart';
import 'package:stimmapp/app/mobile/pages/others/privacy_policy_ads_revoke_page.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/subscription_provider.dart';
import 'package:stimmapp/core/services/ad_consent_service.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

class AuthLayout extends ConsumerStatefulWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  ConsumerState<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends ConsumerState<AuthLayout> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;
      if (prevUser?.uid == nextUser?.uid) return;
      PurchasesService.instance.syncAppUser(nextUser?.uid);
      if (nextUser == null) return;
      Future.microtask(() async {
        await PurchasesService.instance.refreshCustomerInfo();
        await syncSubscriptionStatus(
          nextUser.uid,
          PurchasesService.instance.currentStatus,
        );
      });
    });

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
          return widget.pageIfNotConnected ?? const WelcomePage();
        }

        if (!user.emailVerified) {
          return const EmailConfirmationPage();
        }

        final userProfileState = ref.watch(userProfileProvider);
        Widget buildProfileRoute(profile) {
          if (profile == null) {
            return const SetUserDetailsPage();
          }
          if (!AdConsentService.canUseFreeTier(profile)) {
            return const PrivacyPolicyAdsRevokePage(showAppBar: false);
          }
          if (profile.acceptedCommunityRulesAt == null) {
            return CommunityGuidelinesPage(profile: profile);
          }
          return const WidgetTree();
        }

        return userProfileState.when(
          data: buildProfileRoute,
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => Center(child: Text('Error: $error')),
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
        );
      },
      loading: () => const AppLoadingPage(),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
