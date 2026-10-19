import 'package:stimmapp/app/widgets/lemm_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/functions/parse_website_link.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';
import 'package:stimmapp/core/functions/update_user_name.dart';

enum EditableProfileField { username, givenName, surname, websiteUrl }

class UpdateProfileFieldPage extends StatefulWidget {
  const UpdateProfileFieldPage({
    required this.field,
    required this.initialValue,
    super.key,
  });

  final EditableProfileField field;
  final String? initialValue;

  @override
  State<UpdateProfileFieldPage> createState() => _UpdateProfileFieldPageState();
}

class _UpdateProfileFieldPageState extends State<UpdateProfileFieldPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pageTitle() {
    return switch (widget.field) {
      EditableProfileField.username => context.l10n.updateUsername,
      EditableProfileField.givenName => context.l10n.editGivenName,
      EditableProfileField.surname => context.l10n.editSurname,
      EditableProfileField.websiteUrl => context.l10n.webLinkTitle,
    };
  }

  String _fieldLabel() {
    return switch (widget.field) {
      EditableProfileField.username => context.l10n.newUsername,
      EditableProfileField.givenName => context.l10n.givenName,
      EditableProfileField.surname => context.l10n.surname,
      EditableProfileField.websiteUrl => context.l10n.webLinkLabel,
    };
  }

  int get _maxLength => switch (widget.field) {
    EditableProfileField.username => AppLimits.maxDisplayNameLength,
    EditableProfileField.websiteUrl => 2048,
    _ => AppLimits.maxPersonNameLength,
  };

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        showErrorSnackBar(context.l10n.notAuthenticated);
        return;
      }

      final repository = UserRepository.create();
      final profile = await repository.getById(currentUser.uid);
      if (!mounted) return;
      if (profile == null) {
        showErrorSnackBar(context.l10n.profileSaveFailed);
        return;
      }

      if ((widget.field == EditableProfileField.givenName ||
              widget.field == EditableProfileField.surname) &&
          profile.isGoogleSyncActive == true) {
        showErrorSnackBar(context.l10n.googleSyncLocksPersonalData);
        return;
      }

      final value = widget.field == EditableProfileField.username
          ? normalizeUsername(_controller.text)
          : _controller.text.trim();

      switch (widget.field) {
        case EditableProfileField.username:
          final available = await repository.isUsernameAvailable(
            value,
            forUserId: currentUser.uid,
          );
          if (!mounted) return;
          if (!available) {
            showErrorSnackBar(context.l10n.usernameUnavailable);
            return;
          }
          await updateUsername(value);
        case EditableProfileField.givenName:
          await repository.upsert(profile.copyWith(givenName: value));
        case EditableProfileField.surname:
          await repository.upsert(profile.copyWith(surname: value));
        case EditableProfileField.websiteUrl:
          await repository.upsert(
            profile.copyWith(websiteUrl: value.isEmpty ? null : value),
          );
      }

      if (!mounted) return;
      showSuccessSnackBar(
        widget.field == EditableProfileField.username
            ? context.l10n.usernameChangedSuccessfully
            : context.l10n.profileDetailsUpdated,
      );
      Navigator.of(context).pop();
    } on DatabaseException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        e.code == 'already-exists'
            ? context.l10n.usernameUnavailable
            : context.l10n.profileSaveFailed,
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context.l10n.profileSaveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _pageTitle();
    return AppBottomBarButtons(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                LemmImage(
                  assetPath: 'assets/images/Lemm_pen.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Center(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _controller,
                          maxLength: _maxLength,
                          keyboardType:
                              widget.field == EditableProfileField.websiteUrl
                              ? TextInputType.url
                              : TextInputType.text,
                          autocorrect:
                              widget.field != EditableProfileField.websiteUrl,
                          textCapitalization:
                              (widget.field == EditableProfileField.username ||
                                  widget.field ==
                                      EditableProfileField.websiteUrl)
                              ? TextCapitalization.none
                              : TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_maxLength),
                          ],
                          decoration: InputDecoration(
                            labelText: _fieldLabel(),
                            hintText:
                                widget.field == EditableProfileField.websiteUrl
                                ? 'https://…'
                                : null,
                            helperText:
                                widget.field == EditableProfileField.websiteUrl
                                ? context.l10n.webLinkHelp
                                : null,
                            helperMaxLines: 3,
                            errorMaxLines: 3,
                            counterText: '',
                          ),
                          validator: (String? value) {
                            if (widget.field ==
                                EditableProfileField.websiteUrl) {
                              return value == null ||
                                      value.trim().isEmpty ||
                                      parseWebsiteLink(value) != null
                                  ? null
                                  : context.l10n.publicationInvalidWebsiteLink;
                            }
                            if (value == null || value.trim().isEmpty) {
                              return context.l10n.enterSomething;
                            }
                            if (widget.field == EditableProfileField.username &&
                                !hasValidUsernameLength(value)) {
                              return context.l10n.usernameTooShort(
                                AppLimits.minUsernameLength,
                              );
                            }
                            if (value.trim().length > _maxLength) {
                              return context.l10n.enterSomething;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      buttons: [
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) await _save();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 24,
                  child: Center(
                    child: TriangleLoadingIndicator(
                      size: 20,
                      showFill: false,
                      strokeColor: Colors.black,
                    ),
                  ),
                )
              : Text(
                  widget.field == EditableProfileField.websiteUrl
                      ? context.l10n.save
                      : title,
                ),
        ),
      ],
    );
  }
}
