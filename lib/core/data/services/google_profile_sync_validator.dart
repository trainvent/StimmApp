import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

class GoogleProfileSyncException implements Exception {
  const GoogleProfileSyncException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'GoogleProfileSyncException($code, $message)';
}

class GoogleProfileSyncValidator {
  const GoogleProfileSyncValidator._();

  static void validateGoogleData(GoogleProfileData data) {
    if (data.givenName?.trim().isNotEmpty != true) {
      throw const GoogleProfileSyncException(
        'missing-given-name',
        'Google did not provide a given name.',
      );
    }
    if (data.surname?.trim().isNotEmpty != true) {
      throw const GoogleProfileSyncException(
        'missing-surname',
        'Google did not provide a surname.',
      );
    }

    final birthday = data.dateOfBirth;
    if (birthday == null) {
      throw const GoogleProfileSyncException(
        'missing-birthday',
        'Google did not provide a complete birthday.',
      );
    }
    if (birthday.year < 1900 || birthday.isAfter(DateTime.now())) {
      throw const GoogleProfileSyncException(
        'invalid-birthday',
        'Google returned an unsupported birthday.',
      );
    }

    if (data.address?.trim().isNotEmpty != true) {
      throw const GoogleProfileSyncException(
        'missing-address',
        'Google did not provide a current address.',
      );
    }
  }

  static void validateResolvedAddress(PlaceAddressInfo address) {
    if (address.town?.trim().isNotEmpty != true ||
        address.countryCode?.trim().isNotEmpty != true) {
      throw const GoogleProfileSyncException(
        'address-not-resolved',
        'The Google address could not be resolved to a town and country.',
      );
    }
    if (address.countryCode?.trim().toUpperCase() == 'DE' &&
        address.state?.trim().isNotEmpty != true) {
      throw const GoogleProfileSyncException(
        'state-not-resolved',
        'The German state could not be resolved from the Google address.',
      );
    }
  }
}
