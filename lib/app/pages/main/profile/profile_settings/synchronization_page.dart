import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_service.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_preview.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/google_account_links.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

class SynchronizationPage extends ConsumerStatefulWidget {
  const SynchronizationPage({super.key});

  @override
  ConsumerState<SynchronizationPage> createState() =>
      _SynchronizationPageState();
}

class _SynchronizationPageState extends ConsumerState<SynchronizationPage> {
  bool _isSyncingGoogleProfile = false;
  GoogleProfileSyncPreview? _preview;

  Future<void> _setGoogleSyncActive(UserProfile profile, bool active) async {
    if (_isSyncingGoogleProfile) return;
    setState(() => _isSyncingGoogleProfile = true);
    try {
      final service = GoogleProfileSyncService();
      if (active) {
        final updated = await service.synchronize(
          profile: profile,
          activate: true,
        );
        _preview = GoogleProfileSyncPreview.fromProfile(
          updated,
          fallbackEmail: authService.authenticatedEmail,
        );
      } else {
        await service.setActive(profile, false);
      }
      if (!mounted) return;
      showSuccessSnackBar(
        active
            ? context.l10n.googleSyncEnabled
            : context.l10n.googleSyncDisabled,
      );
    } on GoogleProfileSyncPreviewException catch (error, stackTrace) {
      debugPrint('Google profile synchronization validation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _preview = error.preview);
        showErrorSnackBar(context.l10n.googleSyncFailed);
      }
    } catch (error, stackTrace) {
      debugPrint('Google profile synchronization setting failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context.l10n.googleSyncFailed);
    } finally {
      if (mounted) setState(() => _isSyncingGoogleProfile = false);
    }
  }

  Future<void> _syncGoogleProfileNow(UserProfile profile) async {
    if (_isSyncingGoogleProfile) return;
    setState(() => _isSyncingGoogleProfile = true);
    try {
      final updated = await GoogleProfileSyncService().synchronize(
        profile: profile,
      );
      _preview = GoogleProfileSyncPreview.fromProfile(
        updated,
        fallbackEmail: authService.authenticatedEmail,
      );
      if (mounted) showSuccessSnackBar(context.l10n.googleSyncSucceeded);
    } on GoogleProfileSyncPreviewException catch (error, stackTrace) {
      debugPrint('Google profile synchronization validation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _preview = error.preview);
        showErrorSnackBar(context.l10n.googleSyncFailed);
      }
    } catch (error, stackTrace) {
      debugPrint('Google profile synchronization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) showErrorSnackBar(context.l10n.googleSyncFailed);
    } finally {
      if (mounted) setState(() => _isSyncingGoogleProfile = false);
    }
  }

  Future<void> _openGoogleProfile(String? email) async {
    final opened = await openGoogleProfile(email);
    if (mounted && !opened) {
      showErrorSnackBar(context.l10n.couldNotOpenLink);
    }
  }

  String _displayValue(Object? value) {
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value);
    }
    final text = value?.toString().trim();
    return text?.isNotEmpty == true ? text! : '—';
  }

  Future<void> _showFieldInfo({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _syncFieldTile({
    required String label,
    required Object? currentValue,
    required Object? nextValue,
    required bool hasWarning,
    String? infoMessage,
  }) {
    final current = _displayValue(currentValue);
    final next = _displayValue(nextValue);
    final changed = current != next;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: SizedBox.square(
        dimension: 24,
        child: hasWarning
            ? Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 22,
              )
            : const Icon(Icons.check_circle_outline, size: 20),
      ),
      title: Text(label),
      subtitle: Text(
        changed ? '$current → $next' : next,
        style: hasWarning ? TextStyle(color: colorScheme.error) : null,
      ),
      trailing: changed || infoMessage != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (changed && !hasWarning)
                  const Icon(Icons.sync_alt, size: 20),
                if (infoMessage != null)
                  IconButton(
                    key: ValueKey('syncFieldInfo_$label'),
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline, size: 18),
                    tooltip: label,
                    onPressed: () =>
                        _showFieldInfo(title: label, message: infoMessage),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _managedFieldsCard(
    UserProfile profile,
    GoogleProfileSyncPreview preview,
  ) {
    final warnings = preview.warningFields;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              context.l10n.googleSyncManagedFields,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _syncFieldTile(
            label: context.l10n.givenName,
            currentValue: profile.givenName,
            nextValue: preview.givenName,
            hasWarning: warnings.contains(GoogleProfileSyncField.givenName),
          ),
          _syncFieldTile(
            label: context.l10n.surname,
            currentValue: profile.surname,
            nextValue: preview.surname,
            hasWarning: warnings.contains(GoogleProfileSyncField.surname),
          ),
          _syncFieldTile(
            label: context.l10n.email,
            currentValue: profile.email,
            nextValue: preview.email,
            hasWarning: warnings.contains(GoogleProfileSyncField.email),
          ),
          _syncFieldTile(
            label: context.l10n.dateOfBirth,
            currentValue: profile.dateOfBirth,
            nextValue: preview.dateOfBirth,
            hasWarning: warnings.contains(GoogleProfileSyncField.dateOfBirth),
          ),
          _syncFieldTile(
            label: context.l10n.address,
            currentValue: profile.address,
            nextValue: preview.address,
            hasWarning: warnings.contains(GoogleProfileSyncField.address),
            infoMessage: context.l10n.googleSyncAddressMustBePublic,
          ),
          _syncFieldTile(
            label: context.l10n.town,
            currentValue: profile.town,
            nextValue: preview.town,
            hasWarning: warnings.contains(GoogleProfileSyncField.town),
          ),
          _syncFieldTile(
            label: context.l10n.stateRegionScopeFallback,
            currentValue: profile.state,
            nextValue: preview.stateOrRegion,
            hasWarning: warnings.contains(GoogleProfileSyncField.stateOrRegion),
          ),
          _syncFieldTile(
            label: context.l10n.countryScopeFallback,
            currentValue: profile.countryCode,
            nextValue: preview.countryCode,
            hasWarning: warnings.contains(GoogleProfileSyncField.country),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.synchronization)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: profileState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text(context.l10n.googleSyncFailed)),
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(context.l10n.userNotFound));
            }
            final preview =
                _preview ??
                GoogleProfileSyncPreview.fromProfile(
                  profile,
                  fallbackEmail: authService.authenticatedEmail,
                );
            return ListView(
              children: [
                ListTile(
                  key: const Key('editGoogleProfileButton'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(FontAwesome5.google, size: 18),
                  title: Text(context.l10n.editGoogleProfile),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openGoogleProfile(
                    authService.authenticatedEmail ?? profile.email,
                  ),
                ),
                SwitchListTile(
                  key: const Key('googleProfileSyncSwitch'),
                  contentPadding: EdgeInsets.zero,
                  value: profile.isGoogleSyncActive == true,
                  onChanged: _isSyncingGoogleProfile
                      ? null
                      : (active) => _setGoogleSyncActive(profile, active),
                  title: Text(context.l10n.synchronizeGoogleDataPeriodically),
                  subtitle: Text(context.l10n.googleSyncLocksPersonalData),
                ),
                ListTile(
                  key: const Key('syncGoogleProfileNowButton'),
                  contentPadding: EdgeInsets.zero,
                  enabled: !_isSyncingGoogleProfile,
                  leading: _isSyncingGoogleProfile
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  title: Text(context.l10n.syncGoogleDataNow),
                  onTap: _isSyncingGoogleProfile
                      ? null
                      : () => _syncGoogleProfileNow(profile),
                ),
                _managedFieldsCard(profile, preview),
              ],
            );
          },
        ),
      ),
    );
  }
}
