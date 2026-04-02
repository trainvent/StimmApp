import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/ad_consent_service.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyAdsRevokePage extends StatefulWidget {
  const PrivacyPolicyAdsRevokePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<PrivacyPolicyAdsRevokePage> createState() =>
      _PrivacyPolicyAdsRevokePageState();
}

class _PrivacyPolicyAdsRevokePageState
    extends State<PrivacyPolicyAdsRevokePage> {
  final _userRepo = UserRepository.create();
  final _currentUser = authService.currentUser;
  final _adService = AdService();
  bool _saving = false;

  Future<void> _openPolicyUrl() async {
    final ok = await launchUrl(
      Uri.parse(IConst.privacyPolicyAdsUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.sharingNotSupported)));
  }

  Future<void> _setAdsConsent(bool granted, UserProfile profile) async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final bool canRequestAds;
      if (granted) {
        canRequestAds = await _adService
            .requestConsentInfoUpdateAndMaybeShowForm();
      } else {
        await _adService.showPrivacyOptionsFormIfRequired();
        canRequestAds = false;
      }
      await _userRepo.update(profile.uid, {
        'adsConsentGranted': canRequestAds ? true : null,
        'adsConsentUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _revokeAdsConsentAndLogout(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.adsConsentRevokeDialogTitle),
        content: Text(dialogContext.l10n.adsConsentRevokeDialogDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _adService.showPrivacyOptionsFormIfRequired();
      await _userRepo.update(profile.uid, {
        'adsConsentGranted': null,
        'adsConsentUpdatedAt': FieldValue.serverTimestamp(),
      });
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<UserProfile?>(
      stream: _currentUser == null
          ? null
          : _userRepo.watchById(_currentUser.uid),
      builder: (context, snapshot) {
        if (_currentUser == null) {
          return Center(child: Text(context.l10n.pleaseSignInFirst));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('${context.l10n.error}: ${snapshot.error}'),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return Center(child: Text(context.l10n.userNotFound));
        }

        final isPro = profile.isPro == true;
        final requiresConsent = AdConsentService.requiresAdsConsent(profile);
        final hasGrantedConsent = profile.adsConsentGranted == true;
        final hasResolvedConsent = AdConsentService.hasResolvedAdsConsent(
          profile,
        );
        final shouldBlockApp =
            requiresConsent && !AdConsentService.canUseFreeTier(profile);

        final statusTitle = !requiresConsent
            ? context.l10n.adsConsentManagementTitle
            : hasGrantedConsent
            ? context.l10n.adsConsentGrantedStatus
            : hasResolvedConsent
            ? context.l10n.adsConsentRevokedStatus
            : context.l10n.adsConsentStatusUnknown;

        final statusDescription = isPro
            ? context.l10n.adsDisabledForProDescription
            : !requiresConsent
            ? context.l10n.neededForAdsEnabledForFreeDescription
            : hasGrantedConsent
            ? context.l10n.adsConsentGrantedDetails
            : hasResolvedConsent
            ? context.l10n.adsConsentRevokedDetails
            : context.l10n.adsConsentPendingDetails;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              shouldBlockApp
                  ? context.l10n.adsConsentRequiredTitle
                  : context.l10n.adsConsentManagementTitle,
              style: AppTextStyles.xlBold,
            ),
            const SizedBox(height: 12),
            Text(
              shouldBlockApp
                  ? context.l10n.adsConsentRequiredDescription
                  : context.l10n.adsConsentManagementDescription,
              style: AppTextStyles.m,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusTitle, style: AppTextStyles.lBold),
                    const SizedBox(height: 8),
                    Text(statusDescription, style: AppTextStyles.m),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _openPolicyUrl,
              child: Text(context.l10n.openAdsPrivacyPolicy),
            ),
            if (!isPro && requiresConsent) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : () => _setAdsConsent(true, profile),
                child: Text(context.l10n.allowCookiesAndContinue),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving || !hasGrantedConsent
                    ? null
                    : () => _revokeAdsConsentAndLogout(profile),
                child: Text(context.l10n.revokeAdsConsent),
              ),
              if (!shouldBlockApp) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(context.l10n.continueToApp),
                ),
              ],
            ],
          ],
        );
      },
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text(context.l10n.adsConsentManagementTitle))
          : null,
      body: SafeArea(child: body),
    );
  }
}
