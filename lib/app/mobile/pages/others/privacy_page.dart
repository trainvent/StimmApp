import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  final _userRepo = UserRepository.create();

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
      ref.read(crashLogsEnabledProvider.notifier).setEnabled(value);
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
      ref.read(analyticsCollectionEnabledProvider.notifier).setEnabled(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
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
    bool showInfoButton = true,
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
      secondary: showInfoButton
          ? IconButton(
              tooltip: context.l10n.about,
              onPressed: () => _openPolicyUrl(url),
              icon: const Icon(Icons.info_outline),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final sendCrashLogs = ref.watch(crashLogsEnabledProvider);
    final analyticsCollectionEnabled = ref.watch(
      analyticsCollectionEnabledProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacySettings)),
      body: profileState.when(
        loading: () => const Center(child: TriangleLoadingIndicator()),
        error: (error, _) =>
            Center(child: Text('${context.l10n.error}: $error')),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(context.l10n.pleaseSignInFirst));
          }

          return ListView(
            children: [
              _buildPolicyTile(
                title: context.l10n.privacyPolicyEssentialTitle,
                subtitle: context.l10n.privacyPolicyEssentialDescription,
                url: IConst.privacyPolicyUrl,
              ),
              _buildPolicyTile(
                title: context.l10n.analyticsData,
                subtitle: context.l10n.analyticsDataDescription,
                url: IConst.privacyPolicyUrl,
                switchValue: analyticsCollectionEnabled,
                onChanged: (value) =>
                    _toggleAnalyticsCollection(value, profile),
                showInfoButton: false,
              ),
              _buildPolicyTile(
                title: context.l10n.sendCrashLogs,
                subtitle: context.l10n.sendCrashLogsDescription,
                url: IConst.privacyPolicyCrashDataUrl,
                switchValue: sendCrashLogs,
                onChanged: (value) => _toggleCrashLogs(value, profile),
                showInfoButton: false,
              ),
            ],
          );
        },
      ),
    );
  }
}
