import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
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
  String? _adsConsentPromptUid;

  Future<void> _recordAdsConsent(String uid, bool granted) async {
    await UserRepository.create().update(uid, {
      'adsConsentGranted': granted,
      'adsConsentUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _maybePromptForAdsConsent(UserProfile? profile) {
    if (!mounted || profile == null) return;
    if (!AdConsentService.shouldPromptForAdsConsent(profile)) return;
    if (_adsConsentPromptUid == profile.uid) return;

    _adsConsentPromptUid = profile.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Personalized ads consent'),
          content: const Text(
            'StimmApp shows ads only to non-Pro users. If you are in the EU, UK, or Switzerland, we need your permission before showing personalized ads. You can change this choice later in Privacy Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (!mounted || granted == null) {
        _adsConsentPromptUid = null;
        return;
      }

      try {
        await _recordAdsConsent(profile.uid, granted);
      } finally {
        _adsConsentPromptUid = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;
      if (prevUser?.uid == nextUser?.uid) return;
      PurchasesService.instance.syncAppUser(nextUser?.uid);
      if (nextUser == null) {
        _adsConsentPromptUid = null;
        return;
      }
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

    ref.listen(userProfileProvider, (previous, next) {
      next.whenData(_maybePromptForAdsConsent);
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
