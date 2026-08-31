import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyConsentPage extends ConsumerStatefulWidget {
  const PrivacyConsentPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends ConsumerState<PrivacyConsentPage> {
  late bool _analyticsEnabled;
  late bool _crashLogsEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _analyticsEnabled = widget.profile.analyticsCollectionEnabled ?? false;
    _crashLogsEnabled = widget.profile.sendCrashLogs ?? false;
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      Uri.parse(IConst.privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showErrorSnackBar(context.l10n.couldNotOpenLink);
    }
  }

  Future<void> _saveConsent({
    bool? analyticsEnabled,
    bool? crashLogsEnabled,
    bool animateSelection = false,
  }) async {
    if (_saving) return;

    final selectedAnalytics = analyticsEnabled ?? _analyticsEnabled;
    final selectedCrashLogs = crashLogsEnabled ?? _crashLogsEnabled;
    final analyticsController = ref.read(
      analyticsCollectionEnabledProvider.notifier,
    );
    final crashLogsController = ref.read(crashLogsEnabledProvider.notifier);

    setState(() {
      _analyticsEnabled = selectedAnalytics;
      _crashLogsEnabled = selectedCrashLogs;
      _saving = true;
    });

    if (animateSelection) {
      await Future<void>.delayed(kThemeAnimationDuration);
    }

    try {
      await UserRepository.create().update(widget.profile.uid, {
        'analyticsCollectionEnabled': selectedAnalytics,
        'sendCrashLogs': selectedCrashLogs,
      });
      analyticsController.setEnabled(selectedAnalytics);
      crashLogsController.setEnabled(selectedCrashLogs);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar('${context.l10n.error}: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacySettings)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      context.l10n.privacyPolicyEssentialDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _openPrivacyPolicy,
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(context.l10n.openPrivacyPolicy),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      key: const Key('analyticsConsentSwitch'),
                      contentPadding: EdgeInsets.zero,
                      value: _analyticsEnabled,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _analyticsEnabled = value),
                      title: Text(context.l10n.analyticsData),
                      subtitle: Text(context.l10n.analyticsDataDescription),
                    ),
                    SwitchListTile(
                      key: const Key('crashLogsConsentSwitch'),
                      contentPadding: EdgeInsets.zero,
                      value: _crashLogsEnabled,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _crashLogsEnabled = value),
                      title: Text(context.l10n.sendCrashLogs),
                      subtitle: Text(context.l10n.sendCrashLogsDescription),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  isFilled: true,
                  isLoading: _saving,
                  label: _saving ? context.l10n.saving : context.l10n.allowAll,
                  callback: _saving
                      ? null
                      : () => _saveConsent(
                          analyticsEnabled: true,
                          crashLogsEnabled: true,
                          animateSelection: true,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  isLoading: _saving,
                  label: _saving
                      ? context.l10n.saving
                      : context.l10n.saveSelection,
                  callback: _saving ? null : _saveConsent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
