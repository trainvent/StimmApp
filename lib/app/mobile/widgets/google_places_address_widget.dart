import 'package:flutter/material.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/services/google_places_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GooglePlacesAddressWidget extends StatelessWidget {
  const GooglePlacesAddressWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
    this.onCountryCodeChanged,
    this.countries,
    this.validator,
  });

  final TextEditingController controller;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?>? onCountryCodeChanged;
  final List<String>? countries;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return GooglePlacesAutoCompleteTextFormField(
      config: GoogleApiConfig(
        apiKey: IConst.googlePlacesApiKey,
        countries: countries ?? const <String>[],
        debounceTime: 400,
      ),
      textEditingController: controller,
      decoration: InputDecoration(
        hintText: context.l10n.enterYourAddress,
        labelText: context.l10n.address,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter some text';
            }
            return null;
          },
      maxLines: 1,
      onSuggestionClicked: (Prediction prediction) async {
        controller.text = prediction.description!;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description!.length),
        );
        if (prediction.placeId != null) {
          final service = GooglePlacesService(IConst.googlePlacesApiKey);
          final info = await service.getAddressInfoFromPlaceId(
            prediction.placeId!,
          );
          onStateChanged(info.state);
          onCountryCodeChanged?.call(info.countryCode);
        }
      },
      minInputLength: 2,
    );
  }
}
