import 'package:stimmapp/app/pages/main/profile/profile_settings/update_profile_field_page.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:trainvent_general/trainvent_general.dart';

class PublicProfileSettingsDialog extends StatefulWidget {
  const PublicProfileSettingsDialog({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<PublicProfileSettingsDialog> createState() =>
      _PublicProfileSettingsDialogState();
}

class _PublicProfileSettingsDialogState
    extends State<PublicProfileSettingsDialog> {
  late bool _showPublications = !widget.profile.hidePublications;
  late bool _showFullName = widget.profile.publicProfileShowFullName;
  late bool _showAddress = widget.profile.publicProfileShowAddress;
  late bool _showLink = widget.profile.publicProfileShowLink;
  late String? _websiteUrl = widget.profile.websiteUrl;
  bool _editingLink = false;
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await UserRepository.create().setPublicProfileVisibility(
        widget.profile.uid,
        showPublications: _showPublications,
        showFullName: _showFullName,
        showAddress: _showAddress,
        showLink: _showLink,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editLink() async {
    if (_editingLink || _saving) return;
    setState(() => _editingLink = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UpdateProfileFieldPage(
            field: EditableProfileField.websiteUrl,
            initialValue: _websiteUrl,
          ),
        ),
      );
      if (!mounted) return;
      final profile = await UserRepository.create().getById(widget.profile.uid);
      if (mounted && profile != null) {
        setState(() => _websiteUrl = profile.websiteUrl);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _editingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final fullName = [profile.givenName, profile.surname]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(context.l10n.publicProfileSettingsTitle),
        scrollable: true,
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.publicProfileVisibilityIntro),
              const SizedBox(height: 16),
              SwitchListTile(
                key: const ValueKey('public_profile_show_publications'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.publicProfilePublicationHistory),
                subtitle: Text(context.l10n.publicProfileHistoryHelp),
                value: _showPublications,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _showPublications = value),
              ),
              SwitchListTile(
                key: const ValueKey('public_profile_show_full_name'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.publicProfileFullName),
                subtitle: Text(
                  fullName.isEmpty
                      ? context.l10n.publicProfileNotAdded
                      : fullName,
                ),
                value: _showFullName,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _showFullName = value),
              ),
              SwitchListTile(
                key: const ValueKey('public_profile_show_address'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.address),
                subtitle: Text(
                  profile.address?.trim().isNotEmpty == true
                      ? profile.address!
                      : context.l10n.publicProfileNotAdded,
                ),
                value: _showAddress,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _showAddress = value),
              ),
              SwitchListTile(
                key: const ValueKey('public_profile_show_link'),
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.profileLinkTitle),
                subtitle: Text(
                  _websiteUrl?.trim().isNotEmpty == true
                      ? _websiteUrl!
                      : context.l10n.publicProfileNotAdded,
                ),
                value: _showLink,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _showLink = value),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    _websiteUrl?.isNotEmpty == true
                        ? context.l10n.profileLinkEdit
                        : context.l10n.profileLinkAdd,
                  ),
                  onPressed: _saving || _editingLink ? null : _editLink,
                ),
              ),
              if (_failed)
                Text(
                  context.l10n.profileSaveFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: TriangleLoadingIndicator(
                        size: 20,
                        showFill: false,
                        strokeColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}
