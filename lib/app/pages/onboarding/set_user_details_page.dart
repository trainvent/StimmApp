import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show LengthLimitingTextInputFormatter, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/widgets/tomtom_address_widget.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_validator.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/providers/profile_picture_provider.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SetUserDetailsPage extends ConsumerStatefulWidget {
  const SetUserDetailsPage({super.key});

  @override
  ConsumerState<SetUserDetailsPage> createState() => _SetUserDetailsPageState();
}

class _SetUserDetailsPageState extends ConsumerState<SetUserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressFieldKey = GlobalKey<TomTomAddressWidgetState>();
  final TextEditingController controllerSurname = TextEditingController();
  final TextEditingController controllerGivenName = TextEditingController();
  final TextEditingController controllerDisplayName = TextEditingController();
  final TextEditingController controllerDateOfBirth = TextEditingController();
  final TextEditingController controllerAddress = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String? _selectedState;
  String? _selectedCountryCode;
  String? _selectedTown;
  String? _googleEmail;
  String errorMessage = '';
  double _progress = 0.0;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _acceptedCommunityRules = false;
  bool _isSaving = false;
  bool _isCancellingRegistration = false;
  bool _isImportingGoogleProfile = false;
  bool _isGoogleSyncActive = false;
  bool get _requiresStateScope => _selectedCountryCode == 'DE';
  bool get _isGoogleAccount =>
      authService.currentUser?.providerData.any(
        (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
      ) ??
      false;

  @override
  void initState() {
    super.initState();
    _googleEmail = authService.currentUser?.email?.trim();
    final googleName = authService.currentUser?.displayName?.trim();
    if (googleName == null || googleName.isEmpty) return;

    final nameParts = googleName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (nameParts.isEmpty) return;

    controllerGivenName.text = _limitName(nameParts.first);
    if (nameParts.length > 1) {
      controllerSurname.text = _limitName(nameParts.skip(1).join(' '));
    }
  }

  String _limitName(String value) {
    return value.length <= AppLimits.maxPersonNameLength
        ? value
        : value.substring(0, AppLimits.maxPersonNameLength);
  }

  Future<bool> _importGoogleProfile({bool activateSync = false}) async {
    if (_isImportingGoogleProfile) return false;
    setState(() => _isImportingGoogleProfile = true);

    try {
      final data = await authService.importGoogleProfileData();
      if (!mounted) return false;
      final googleEmail = data.email?.trim();
      if (googleEmail?.isNotEmpty == true) {
        _googleEmail = googleEmail;
      }
      if (activateSync) {
        GoogleProfileSyncValidator.validateGoogleData(data);
      }

      var birthdayImported = false;
      var addressImported = false;
      final givenName = data.givenName?.trim();
      if (givenName != null && givenName.isNotEmpty) {
        controllerGivenName.text = _limitName(givenName);
      }
      final surname = data.surname?.trim();
      if (surname != null && surname.isNotEmpty) {
        controllerSurname.text = _limitName(surname);
      }
      final birthday = data.dateOfBirth;
      if (birthday != null && birthday.year >= 1900) {
        _selectedDateOfBirth = birthday;
        controllerDateOfBirth.text = DateFormat('yyyy-MM-dd').format(birthday);
        birthdayImported = true;
      }

      final address = data.address?.trim();
      if (address != null && address.isNotEmpty) {
        _selectedTown = null;
        _selectedState = null;
        _selectedCountryCode = null;
        controllerAddress.text = address;
        controllerAddress.selection = TextSelection.collapsed(
          offset: address.length,
        );
        await _addressFieldKey.currentState?.resolveCurrentTextIfNeeded(
          force: true,
        );
        if (!mounted) return false;
        addressImported = true;
      }

      if (activateSync) {
        GoogleProfileSyncValidator.validateResolvedAddress(
          PlaceAddressInfo(
            town: _selectedTown,
            state: _selectedState,
            countryCode: _selectedCountryCode,
          ),
        );
      }

      setState(() {
        if (activateSync) _isGoogleSyncActive = true;
      });
      final message = switch ((birthdayImported, addressImported)) {
        (true, true) => context.l10n.googleProfileImported,
        (true, false) => context.l10n.googleBirthdayImportedAddressUnavailable,
        (false, true) => context.l10n.googleAddressImportedBirthdayUnavailable,
        (false, false) => context.l10n.googleProfileHasNoBirthdayOrAddress,
      };
      showSuccessSnackBar(message);
      if (!addressImported) {
        _addressFieldKey.currentState?.requestFocus();
      }
      return true;
    } on GoogleProfileImportCancelledException {
      return false;
    } on GoogleProfileSyncException catch (e, st) {
      debugPrint('Google profile synchronization validation failed: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context.l10n.googleSyncRequiresCompleteProfile);
      }
      return false;
    } on GoogleProfileImportException catch (e, st) {
      debugPrint('Google profile import failed (${e.code}): ${e.message}');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context.l10n.googleProfileImportFailed);
      }
      return false;
    } catch (e, st) {
      debugPrint('Google profile import failed: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context.l10n.googleProfileImportFailed);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isImportingGoogleProfile = false);
      }
    }
  }

  @override
  void dispose() {
    controllerSurname.dispose();
    controllerGivenName.dispose();
    controllerDisplayName.dispose();
    controllerDateOfBirth.dispose();
    controllerAddress.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetails() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final User? currentUser = authService.currentUser;

      if (currentUser == null) {
        showErrorSnackBar(context.l10n.notAuthenticated);
        return;
      }

      if (controllerAddress.text.trim().isEmpty) {
        showErrorSnackBar(S.of(context).faultyInput);
        return;
      }

      if (_selectedTown == null || _selectedTown!.trim().isEmpty) {
        showErrorSnackBar('Please select an address with a town');
        return;
      }

      if (_requiresStateScope && _selectedState == null) {
        showErrorSnackBar(
          S.of(context).weFailedToGetYourStatePleaseProofreadYourLivingaddress,
        );
        return;
      }

      if (!_acceptedCommunityRules) {
        showErrorSnackBar(context.l10n.acceptCommunityRulesBeforeContinuing);
        return;
      }

      if (ContentModerationService.instance.containsObjectionableContent(
        <String?>[controllerDisplayName.text],
      )) {
        showErrorSnackBar(context.l10n.removeAbusiveLanguageFromPublicName);
        return;
      }

      final displayName = normalizeUsername(controllerDisplayName.text);
      final crashLogsController = ref.read(crashLogsEnabledProvider.notifier);
      final analyticsController = ref.read(
        analyticsCollectionEnabledProvider.notifier,
      );
      final profilePictureController = ref.read(
        profilePictureUrlProvider.notifier,
      );

      final profile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email ?? _googleEmail,
        displayName: displayName,
        state: _requiresStateScope ? _selectedState : null,
        countryCode: _selectedCountryCode,
        createdAt: DateTime.now(),
        surname: controllerSurname.text.trim(),
        givenName: controllerGivenName.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        address: controllerAddress.text.trim(),
        town: _selectedTown,
        sendCrashLogs: true,
        analyticsCollectionEnabled: true,
        acceptedCommunityRulesAt: DateTime.now(),
        isGoogleSyncActive: _isGoogleSyncActive,
        googleSyncLastAt: _isGoogleSyncActive ? DateTime.now() : null,
      );

      await authService.updateUsername(username: displayName);
      crashLogsController.setEnabled(true);
      analyticsController.setEnabled(true);
      await AnalyticsService.instance.logProfileCompleted(
        countryCode: profile.countryCode,
        supportsStateScope: profile.supportsStateScope,
      );

      final googlePhotoUrl = currentUser.photoURL?.trim();
      String? profilePictureUrl = googlePhotoUrl?.isEmpty ?? true
          ? null
          : googlePhotoUrl;

      // In dev/sandbox we can run without Storage to keep costs minimal.
      if (profilePictureUrl == null && !Environment.isDev) {
        // Try to upload a default profile picture from assets.
        try {
          final bytes = await rootBundle.load(AppAssets.defaultAvatar);
          final Uint8List list = bytes.buffer.asUint8List();

          final xFile = XFile.fromData(
            list,
            name: 'default_avatar.png',
            mimeType: 'image/png',
          );

          profilePictureUrl = await ProfilePictureService.instance
              .uploadProfilePicture(
                currentUser.uid,
                xFile,
                persistUrl: false,
                onProgress: (p) {
                  if (!mounted) return;
                  if ((p - _progress).abs() > 0.01) {
                    setState(() => _progress = p);
                  }
                },
              );
          if (!mounted) return;
        } catch (e, st) {
          // Don't block registration for asset/upload failures.
          debugPrint('Default avatar upload failed: $e\n$st');
        }
      }

      if (!mounted) return;
      profilePictureController.setUrl(profilePictureUrl);

      // AuthLayout leaves this page as soon as the profile document exists, so
      // this must be the final awaited operation that touches this State.
      await UserRepository.create().upsertWithUniqueUsername(profile);

      if (profilePictureUrl != null) {
        unawaited(
          ProfilePictureService.instance
              .setProfileUrl(currentUser.uid, profilePictureUrl)
              .catchError((Object e, StackTrace st) {
                debugPrint('Failed to persist default avatar URL: $e\n$st');
              }),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = '${e.code}: ${e.message ?? S.of(context).unknownError}';
      });
      showErrorSnackBar(errorMessage);
    } on DatabaseException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = context.l10n.databaseError(
          e.code,
          e.message ?? S.of(context).unknownError,
        );
      });
      debugPrintStack(
        label: 'saveUserDetails database error',
        stackTrace: StackTrace.current,
      );
      showErrorSnackBar(errorMessage);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        errorMessage = context.l10n.unexpectedErrorWithDetails(e.toString());
      });
      debugPrintStack(label: 'saveUserDetails error', stackTrace: st);
      showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _cancelRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteAccount),
        content: Text(
          dialogContext
              .l10n
              .areYouSureYouWantToDeleteYourAccountThisActionIsIrreversible,
        ),
        actions: [
          TextButton(
            key: const Key('cancelRegistrationDialogButton'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmCancelRegistrationButton'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    setState(() => _isCancellingRegistration = true);

    try {
      await authService.deleteCurrentUser();
      if (!mounted) return;
      navigator.popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        '${e.code}: ${e.message ?? context.l10n.deleteAccountUnexpectedError}',
      );
    } catch (e, st) {
      debugPrintStack(label: 'cancel registration error: $e', stackTrace: st);
      if (!mounted) return;
      showErrorSnackBar(context.l10n.deleteAccountUnexpectedError);
    } finally {
      if (mounted) {
        setState(() => _isCancellingRegistration = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final couldNotOpenLink = context.l10n.couldNotOpenLink;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (mounted && !ok) {
      showErrorSnackBar(couldNotOpenLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidateMode,
      child: Builder(
        builder: (context) {
          return AppBottomBarButtons(
            appBar: AppBar(title: Text(context.l10n.setUserDetails)),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      key: const Key('surnameTextField'),
                      controller: controllerSurname,
                      enabled: !_isGoogleSyncActive,
                      maxLength: AppLimits.maxPersonNameLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppLimits.maxPersonNameLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.surname,
                        counterText: '',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).pleaseEnterYourSurname;
                        }
                        if (value.trim().length >
                            AppLimits.maxPersonNameLength) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('givenNameTextField'),
                      controller: controllerGivenName,
                      enabled: !_isGoogleSyncActive,
                      maxLength: AppLimits.maxPersonNameLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppLimits.maxPersonNameLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.givenName,
                        counterText: '',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).faultyInput;
                        }
                        if (value.trim().length >
                            AppLimits.maxPersonNameLength) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('displayNameTextField'),
                      controller: controllerDisplayName,
                      maxLength: AppLimits.maxDisplayNameLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppLimits.maxDisplayNameLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.displayName,
                        counterText: '',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).faultyInput;
                        }
                        if (value.trim().length >
                            AppLimits.maxDisplayNameLength) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_isGoogleAccount) ...[
                      CheckboxListTile(
                        key: const Key('googleProfileSyncCheckbox'),
                        contentPadding: EdgeInsets.zero,
                        value: _isGoogleSyncActive,
                        onChanged:
                            _isImportingGoogleProfile ||
                                _isSaving ||
                                _isCancellingRegistration
                            ? null
                            : (value) async {
                                if (value != true) {
                                  setState(() => _isGoogleSyncActive = false);
                                  return;
                                }
                                await _importGoogleProfile(activateSync: true);
                              },
                        title: Text(
                          context.l10n.synchronizeGoogleDataPeriodically,
                        ),
                        subtitle: Text(
                          context.l10n.googleSyncLocksPersonalData,
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('importGoogleProfileButton'),
                        onPressed:
                            _isImportingGoogleProfile ||
                                _isSaving ||
                                _isCancellingRegistration
                            ? null
                            : () => _importGoogleProfile(
                                activateSync: _isGoogleSyncActive,
                              ),
                        icon: _isImportingGoogleProfile
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isImportingGoogleProfile
                              ? context.l10n.importingFromGoogle
                              : context.l10n.syncGoogleDataNow,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      key: const Key('dateOfBirthTextField'),
                      controller: controllerDateOfBirth,
                      readOnly: true,
                      enabled: !_isGoogleSyncActive,
                      decoration: InputDecoration(
                        labelText: context.l10n.dateOfBirth,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: _isGoogleSyncActive
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (!mounted) return;
                              if (date != null) {
                                setState(() {
                                  _selectedDateOfBirth = date;
                                  controllerDateOfBirth.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(date);
                                });
                              }
                            },
                      validator: (String? value) {
                        if (_selectedDateOfBirth == null) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_requiresStateScope) ...[
                      Text(_selectedState ?? context.l10n.state),
                      const SizedBox(height: 10),
                    ],
                    KeyedSubtree(
                      key: const Key('addressTextField'),
                      child: TomTomAddressWidget(
                        key: _addressFieldKey,
                        controller: controllerAddress,
                        enabled: !_isGoogleSyncActive,
                        onStateChanged: (state) {
                          if (!mounted) return;
                          setState(() {
                            _selectedState = state;
                          });
                        },
                        onTownChanged: (town) {
                          if (!mounted) return;
                          setState(() {
                            _selectedTown = town;
                          });
                        },
                        onCountryCodeChanged: (countryCode) {
                          if (!mounted) return;
                          setState(() {
                            _selectedCountryCode = countryCode?.toUpperCase();
                            if (_selectedCountryCode != 'DE') {
                              _selectedState = null;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).faultyInput;
                          }
                          if (_selectedTown == null || _selectedTown!.isEmpty) {
                            return 'Please select an address with a town';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      key: const Key('agreenmentCheckboxListTile'),
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedCommunityRules,
                      onChanged: (value) {
                        setState(() {
                          _acceptedCommunityRules = value ?? false;
                        });
                      },
                      title: Text(context.l10n.communityRulesAcceptance),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => _openUrl(IConst.termsOfServiceUrl),
                            child: Text(context.l10n.terms),
                          ),
                          TextButton(
                            onPressed: () => _openUrl(IConst.privacyPolicyUrl),
                            child: Text(context.l10n.privacy),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buttons: [
              ButtonWidget(
                key: const Key('cancelRegistrationButton'),
                label: context.l10n.cancel,
                callback:
                    _isCancellingRegistration ||
                        _isSaving ||
                        _isImportingGoogleProfile
                    ? null
                    : _cancelRegistration,
              ),
              const SizedBox(height: 12),
              ButtonWidget(
                key: const Key('saveButton'),
                isFilled: true,
                label: context.l10n.save,
                callback:
                    _isCancellingRegistration ||
                        _isSaving ||
                        _isImportingGoogleProfile
                    ? null
                    : () async {
                        final faultyInput = S.of(context).faultyInput;
                        setState(() {
                          _autoValidateMode =
                              AutovalidateMode.onUserInteraction;
                        });

                        final addressField = _addressFieldKey.currentState;
                        await addressField?.resolveCurrentTextIfNeeded();
                        if (!mounted) return;

                        if (controllerAddress.text.trim().isEmpty) {
                          showErrorSnackBar(faultyInput);
                          // Force validation to show error on address field if it has a validator
                          _formKey.currentState!.validate();
                          return;
                        }

                        if (!_formKey.currentState!.validate()) {
                          return;
                        } else {
                          await _saveUserDetails();
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
