import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _userRepo = UserRepository.create();
  final _currentUser = authService.currentUser;

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
