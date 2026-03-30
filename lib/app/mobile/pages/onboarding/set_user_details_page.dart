import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/tomtom_address_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SetUserDetailsPage extends StatefulWidget {
  const SetUserDetailsPage({super.key});

  @override
  State<SetUserDetailsPage> createState() => _SetUserDetailsPageState();
}

class _SetUserDetailsPageState extends State<SetUserDetailsPage> {
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
  String errorMessage = '';
  double _progress = 0.0;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _acceptedCommunityRules = false;
  bool get _requiresStateScope => _selectedCountryCode == 'DE';

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

      // Update username (display name) - using email part as default
      await authService.updateUsername(
        username: currentUser.email?.split('@')[0] ?? context.l10n.newUser,
      );

      final profile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email,
        displayName: controllerDisplayName.text,
        state: _requiresStateScope ? _selectedState : null,
        countryCode: _selectedCountryCode,
        createdAt: DateTime.now(),
        surname: controllerSurname.text,
        givenName: controllerGivenName.text,
        dateOfBirth: _selectedDateOfBirth,
        address: controllerAddress.text,
        town: _selectedTown,
        acceptedCommunityRulesAt: DateTime.now(),
      );

      await UserRepository.create().upsert(profile);

      AppData.isAuthConnected.value = true; // Signal that auth is connected

      // In dev/sandbox we can run without Storage to keep costs minimal.
      if (!Environment.isDev) {
        // Try to upload a default profile picture from assets.
        try {
          final bytes = await rootBundle.load(AppAssets.defaultAvatar);
          final Uint8List list = bytes.buffer.asUint8List();

          final xFile = XFile.fromData(
            list,
            name: 'default_avatar.png',
            mimeType: 'image/png',
          );

          await ProfilePictureService.instance.uploadProfilePicture(
            currentUser.uid,
            xFile,
            onProgress: (p) {
              if (!mounted) return;
              if ((p - _progress).abs() > 0.01) setState(() => _progress = p);
            },
          );
        } catch (e, st) {
          // Don't block registration for asset/upload failures.
          debugPrint('Default avatar upload failed: $e\n$st');
        }
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      setState(() {
        errorMessage = '${e.code}: ${e.message ?? S.of(context).unknownError}';
      });
      showErrorSnackBar(errorMessage);
    } on DatabaseException catch (e) {
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
      setState(() {
        errorMessage = context.l10n.unexpectedErrorWithDetails(e.toString());
      });
      debugPrintStack(label: 'saveUserDetails error', stackTrace: st);
      showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _openUrl(String url) async {
    final couldNotOpenLink = context.l10n.couldNotOpenLink;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
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
                      decoration: InputDecoration(
                        labelText: context.l10n.surname,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).pleaseEnterYourSurname;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('givenNameTextField'),
                      controller: controllerGivenName,
                      decoration: InputDecoration(
                        labelText: context.l10n.givenName,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('displayNameTextField'),
                      controller: controllerDisplayName,
                      decoration: InputDecoration(
                        labelText: context.l10n.displayName,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).faultyInput;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('dateOfBirthTextField'),
                      controller: controllerDateOfBirth,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.dateOfBirth,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
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
                        onStateChanged: (state) {
                          setState(() {
                            _selectedState = state;
                          });
                        },
                        onTownChanged: (town) {
                          setState(() {
                            _selectedTown = town;
                          });
                        },
                        onCountryCodeChanged: (countryCode) {
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
                key: const Key('saveButton'),
                isFilled: true,
                label: context.l10n.save,
                callback: () async {
                  final faultyInput = S.of(context).faultyInput;
                  setState(() {
                    _autoValidateMode = AutovalidateMode.onUserInteraction;
                  });

                  await _addressFieldKey.currentState
                      ?.resolveCurrentTextIfNeeded();

                  if (controllerAddress.text.trim().isEmpty) {
                    showErrorSnackBar(faultyInput);
                    // Force validation to show error on address field if it has a validator
                    _formKey.currentState!.validate();
                    return;
                  }

                  if (!_formKey.currentState!.validate()) {
                    return;
                  } else {
                    _saveUserDetails();
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
