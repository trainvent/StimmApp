import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/google_places_address_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

class ChangeLivingAddressPage extends StatefulWidget {
  const ChangeLivingAddressPage({super.key});

  @override
  State<ChangeLivingAddressPage> createState() =>
      _ChangeLivingAddressPageState();
}

class _ChangeLivingAddressPageState extends State<ChangeLivingAddressPage>
    with WidgetsBindingObserver {
  String? _selectedState;
  String? _selectedCountryCode;
  String? _selectedTown;
  final TextEditingController _controllerAddress = TextEditingController();
  String errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  bool get _requiresStateScope => _selectedCountryCode == 'DE';

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _controllerAddress.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final userProfile = await UserRepository.currentUser();
    if (userProfile != null) {
      setState(() {
        _selectedState = userProfile.state;
        _selectedCountryCode = userProfile.countryCode;
        _selectedTown = userProfile.town;
        _controllerAddress.text = userProfile.address ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomBarButtons(
      appBar: AppBar(title: Text(context.l10n.updateLivingAddress)),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                const Text('✏️', style: AppTextStyles.icons),
                const SizedBox(height: 50),
                Form(
                  key: _formKey,
                  child: Center(
                    child: Column(
                      children: [
                        GooglePlacesAddressWidget(
                          controller: _controllerAddress,
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
                        ),
                        if (_requiresStateScope && _selectedState != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Detected state: $_selectedState',
                              style: AppTextStyles.m,
                            ),
                          ),
                        ],
                        Text(
                          errorMessage,
                          style: AppTextStyles.m.copyWith(
                            color: Colors.redAccent,
                          ),
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
        ButtonWidget(
          isFilled: true,
          label: context.l10n.confirm,
          callback: () async {
            if (_controllerAddress.text.trim().isEmpty) {
              showErrorSnackBar(context.l10n.enterSomething);
              return;
            }
            if (_selectedTown == null || _selectedTown!.trim().isEmpty) {
              showErrorSnackBar('Please select an address with a town');
              return;
            }
            if (_requiresStateScope && _selectedState == null) {
              showErrorSnackBar(
                context.l10n.weFailedToGetYourStatePleaseProofreadYourLivingaddress,
              );
              return;
            }
            if (_formKey.currentState!.validate()) {
              final successMessage = context.l10n.addressUpdatedSuccessfully;
              try {
                final userRepository = UserRepository.create();
                final uid = authService.currentUser!.uid;
                final userProfile = await userRepository.getById(uid);
                final updatedProfile = (userProfile ?? UserProfile(uid: uid))
                    .copyWith(
                      state: _requiresStateScope ? _selectedState : null,
                      countryCode: _selectedCountryCode,
                      address: _controllerAddress.text,
                      town: _selectedTown,
                    );
                await userRepository.upsert(updatedProfile);
              } catch (e) {
                showErrorSnackBar(e.toString());
                return;
              }
              showSuccessSnackBar(successMessage);
            }
          },
        ),
      ],
    );
  }
}
