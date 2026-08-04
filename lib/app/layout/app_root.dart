import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/home/widget_tree.dart';
import 'package:stimmapp/app/pages/onboarding/community_guidelines_page.dart';
import 'package:stimmapp/app/pages/onboarding/email_confirmation_page.dart';
import 'package:stimmapp/app/pages/onboarding/privacy_consent_page.dart';
import 'package:stimmapp/app/pages/onboarding/set_user_details_page.dart';
import 'package:stimmapp/app/pages/onboarding/welcome_page.dart'
    show WelcomePage;
import 'package:stimmapp/app/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/subscription_provider.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

class AuthLayout extends ConsumerStatefulWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  ConsumerState<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends ConsumerState<AuthLayout>
    with WidgetsBindingObserver {
  static const _automaticSyncInterval = Duration(hours: 6);
  bool _isAutomaticallySyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      unawaited(_synchronizeGoogleProfileIfDue(profile));
    }
  }

  Future<void> _synchronizeGoogleProfileIfDue(UserProfile profile) async {
    if (_isAutomaticallySyncing || profile.isGoogleSyncActive != true) return;
    final lastSync = profile.googleSyncLastAt;
    if (lastSync != null &&
        DateTime.now().difference(lastSync) < _automaticSyncInterval) {
      return;
    }

    _isAutomaticallySyncing = true;
    try {
      await GoogleProfileSyncService().synchronize(
        profile: profile,
        promptIfNecessary: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Automatic Google profile synchronization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isAutomaticallySyncing = false;
    }
  }

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
          authenticatedEmail: nextUser.email,
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
        syncSubscriptionStatus(
          user.uid,
          next.value!,
          authenticatedEmail: user.email,
        );
      }
    });

    ref.listen(userProfileProvider, (previous, next) {
      final profile = next.value;
      if (profile != null) {
        unawaited(_synchronizeGoogleProfileIfDue(profile));
      }
    });

    return authState.when(
      data: (user) {
        if (user == null) {
          return widget.pageIfNotConnected ?? const WelcomePage();
        }

        if (requiresEmailVerification(user)) {
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
          if (profile.analyticsCollectionEnabled == null ||
              profile.sendCrashLogs == null) {
            return PrivacyConsentPage(profile: profile);
          }
          return const WidgetTree();
        }

        return userProfileState.when(
          data: buildProfileRoute,
          loading: () => const AppLoadingPage(),
          error: (error, stack) => Center(child: Text('Error: $error')),
          skipLoadingOnRefresh: true,
        );
      },
      loading: () => const AppLoadingPage(),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
