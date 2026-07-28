import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_service.dart';
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

  Future<void> _setGoogleSyncActive(UserProfile profile, bool active) async {
    if (_isSyncingGoogleProfile) return;
    setState(() => _isSyncingGoogleProfile = true);
    try {
      final service = GoogleProfileSyncService();
      if (active) {
        await service.synchronize(profile: profile, activate: true);
      } else {
        await service.setActive(profile, false);
      }
      if (!mounted) return;
      showSuccessSnackBar(
        active
            ? context.l10n.googleSyncEnabled
            : context.l10n.googleSyncDisabled,
      );
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
      await GoogleProfileSyncService().synchronize(profile: profile);
      if (mounted) showSuccessSnackBar(context.l10n.googleSyncSucceeded);
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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

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
            return ListView(
              children: [
                ListTile(
                  key: const Key('editGoogleProfileButton'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(FontAwesome5.google, size: 18),
                  title: Text(context.l10n.editGoogleProfile),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () =>
                      _openGoogleProfile(currentUser?.email ?? profile.email),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
