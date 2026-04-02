import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/core/services/ad_consent_service.dart';
import 'package:stimmapp/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _userRepo = UserRepository.create();
  final _currentUser = authService.currentUser;
  final _adService = AdService();
  bool _saving = false;

  Future<void> _openPolicyUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.sharingNotSupported)));
  }

  Future<void> _toggleCrashLogs(bool value, UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(sendCrashLogs: value);
      await _userRepo.upsert(updatedProfile);
      // TODO: Initialize/Deinitialize crash reporting SDK here if possible
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    }
  }

  Future<void> _toggleAnalyticsCollection(
    bool value,
    UserProfile profile,
  ) async {
    try {
      final updatedProfile = profile.copyWith(
        analyticsCollectionEnabled: value,
      );
      await _userRepo.upsert(updatedProfile);
      analyticsCollectionEnabledNotifier.value = value;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    }
  }

  Future<void> _grantAdsConsent(UserProfile profile) async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final granted = await _adService
          .requestConsentInfoUpdateAndMaybeShowForm();
      await _userRepo.update(profile.uid, {
        'adsConsentGranted': granted ? true : null,
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

  Widget _buildPolicyTile({
    required String title,
    required String subtitle,
    required String url,
    bool? switchValue,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    if (switchValue == null) {
      return ListTile(
        leading: IconButton(
          tooltip: context.l10n.about,
          onPressed: () => _openPolicyUrl(url),
          icon: const Icon(Icons.info_outline),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () => _openPolicyUrl(url),
      );
    }

    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: switchValue,
      onChanged: enabled ? onChanged : null,
      secondary: IconButton(
        tooltip: context.l10n.about,
        onPressed: () => _openPolicyUrl(url),
        icon: const Icon(Icons.info_outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.privacySettings)),
        body: Center(child: Text(context.l10n.pleaseSignInFirst)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacySettings)),
      body: StreamBuilder<UserProfile?>(
        stream: _userRepo.watchById(_currentUser.uid),
        builder: (context, snapshot) {
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

          final sendCrashLogs = profile.sendCrashLogs ?? true;
          final analyticsCollectionEnabled =
              profile.analyticsCollectionEnabled ?? false;
          final isPro = profile.isPro == true;
          final canManageAdsConsent =
              !kIsWeb && !isPro && AdConsentService.isInConsentRegion(profile);
          final adsConsentGranted = profile.adsConsentGranted == true;

          return ListView(
            children: [
              _buildPolicyTile(
                title: context.l10n.privacyPolicyEssentialTitle,
                subtitle: context.l10n.privacyPolicyEssentialDescription,
                url: IConst.privacyPolicyUrl,
              ),
              if (canManageAdsConsent)
                _buildPolicyTile(
                  title: context.l10n.personalizedAds,
                  subtitle: context.l10n.personalizedAdsDescription,
                  url: IConst.privacyPolicyAdsUrl,
                  switchValue: adsConsentGranted,
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value) {
                            _grantAdsConsent(profile);
                          } else {
                            _revokeAdsConsentAndLogout(profile);
                          }
                        },
                )
              else
                _buildPolicyTile(
                  title: context.l10n.neededForAds,
                  subtitle: isPro
                      ? context.l10n.neededForAdsDisabledForProDescription
                      : context.l10n.neededForAdsEnabledForFreeDescription,
                  url: IConst.privacyPolicyAdsUrl,
                  switchValue: !isPro,
                  enabled: false,
                ),
              if (canManageAdsConsent &&
                  !AdConsentService.hasResolvedAdsConsent(profile))
                ListTile(
                  title: Text(context.l10n.adsCurrentlyDisabled),
                  subtitle: Text(context.l10n.adsCurrentlyDisabledDescription),
                ),
              _buildPolicyTile(
                title: context.l10n.analyticsData,
                subtitle: context.l10n.analyticsDataDescription,
                url: IConst.privacyPolicyUrl,
                switchValue: analyticsCollectionEnabled,
                onChanged: (value) =>
                    _toggleAnalyticsCollection(value, profile),
              ),
              _buildPolicyTile(
                title: context.l10n.sendCrashLogs,
                subtitle: context.l10n.sendCrashLogsDescription,
                url: IConst.privacyPolicyCrashDataUrl,
                switchValue: sendCrashLogs,
                onChanged: (value) => _toggleCrashLogs(value, profile),
              ),
            ],
          );
        },
      ),
    );
  }
}
