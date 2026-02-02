import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/google_places_address_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/generated/l10n.dart';

class SetUserDetailsPage extends StatefulWidget {
  const SetUserDetailsPage({super.key});

  @override
  State<SetUserDetailsPage> createState() => _SetUserDetailsPageState();
}

class _SetUserDetailsPageState extends State<SetUserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController controllerSurname = TextEditingController();
  final TextEditingController controllerGivenName = TextEditingController();
  final TextEditingController controllerNickName = TextEditingController();
  final TextEditingController controllerDateOfBirth = TextEditingController();
  final TextEditingController controllerAddress = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String? _selectedState;
  String errorMessage = '';
  double _progress = 0.0;

  @override
  void dispose() {
    controllerSurname.dispose();
    controllerGivenName.dispose();
    controllerNickName.dispose();
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
        showErrorSnackBar(context.l10n.enterSomething);
        return;
      }

      if (_selectedState == null) {
        showErrorSnackBar(context.l10n.pleaseSelectState);
        return;
      }

      // Update username (display name) - using email part as default
      await authService.updateUsername(
        username: currentUser.email?.split('@')[0] ?? 'New User',
      );

      final profile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email,
        displayName: controllerNickName.text,
        state: _selectedState,
        createdAt: DateTime.now(),
        surname: controllerSurname.text,
        givenName: controllerGivenName.text,
        dateOfBirth: _selectedDateOfBirth,
        address: controllerAddress.text,
      );

      await UserRepository.create().upsert(profile);

      AppData.isAuthConnected.value = true; // Signal that auth is connected

      // Try to upload a default profile picture from assets.
      try {
        // Load asset bytes
        final bytes = await rootBundle.load('assets/images/default_avatar.png');
        final Uint8List list = bytes.buffer.asUint8List();

        final xFile = XFile.fromData(
          list,
          name: 'default_avatar.png',
          mimeType: 'image/png',
        );

        // Upload using the service (updates Firestore and notifier internally)
        await ProfilePictureService.instance.uploadProfilePicture(
          currentUser.uid,
          xFile,
          onProgress: (p) {
            if (!mounted) return;
            if ((p - _progress).abs() > 0.01) setState(() => _progress = p);
          },
        );
      } catch (e, st) {
        // don't block registration for asset/upload failures — log for debugging
        debugPrint('Default avatar upload failed: $e\n$st');
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      setState(() {
        errorMessage = '${e.code}: ${e.message ?? 'Unknown error'}';
      });
      showErrorSnackBar(errorMessage);
    } on DatabaseException catch (e) {
      setState(() {
        errorMessage =
            'Database error (${e.code}): ${e.message ?? 'Unknown error'}';
      });
      debugPrintStack(
        label: 'saveUserDetails database error',
        stackTrace: StackTrace.current,
      );
      showErrorSnackBar(errorMessage);
    } catch (e, st) {
      setState(() {
        errorMessage = 'Unexpected error: $e';
      });
      debugPrintStack(label: 'saveUserDetails error', stackTrace: st);
      showErrorSnackBar(errorMessage);
    }
  }

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
                          return context.l10n.enterSomething;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('nickNameTextField'),
                      controller: controllerNickName,
                      decoration: InputDecoration(
                        labelText: context.l10n.displayName,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.enterSomething;
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
                          return context.l10n.enterSomething;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(_selectedState ?? context.l10n.state),
                    const SizedBox(height: 10),
                    GooglePlacesAddressWidget(
                      key: const Key('addressTextField'),
                      controller: _textController,
                      onStateChanged: (state) {
                        if (state != null) {
                          setState(() {
                            _selectedState = state;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            buttons: [
              ButtonWidget(
                key: const Key('saveButton'),
                isFilled: true,
                label: context.l10n.save,
                callback: () {
                  if (_textController.text.trim().isEmpty) {
                    showErrorSnackBar(context.l10n.enterSomething);
                    return;
                  }
                  if (!_formKey.currentState!.validate()) {
                    return;
                  } else {
                    // Update controllerAddress with _textController.text before saving
                    controllerAddress.text = _textController.text;
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
