import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

enum GoogleProfileSyncField {
  givenName,
  surname,
  email,
  dateOfBirth,
  address,
  town,
  stateOrRegion,
  country,
}

class GoogleProfileSyncPreview {
  const GoogleProfileSyncPreview({
    this.givenName,
    this.surname,
    this.email,
    this.dateOfBirth,
    this.address,
    this.town,
    this.stateOrRegion,
    this.countryCode,
    this.warningFields = const <GoogleProfileSyncField>{},
  });

  final String? givenName;
  final String? surname;
  final String? email;
  final DateTime? dateOfBirth;
  final String? address;
  final String? town;
  final String? stateOrRegion;
  final String? countryCode;
  final Set<GoogleProfileSyncField> warningFields;

  bool get canSynchronize => warningFields.isEmpty;

  factory GoogleProfileSyncPreview.fromProfile(
    UserProfile profile, {
    String? fallbackEmail,
  }) {
    return GoogleProfileSyncPreview(
      givenName: profile.givenName,
      surname: profile.surname,
      email: _nonEmpty(profile.email) ?? _nonEmpty(fallbackEmail),
      dateOfBirth: profile.dateOfBirth,
      address: profile.address,
      town: profile.town,
      stateOrRegion: profile.state,
      countryCode: profile.countryCode,
    );
  }

  factory GoogleProfileSyncPreview.fromGoogle({
    required GoogleProfileData google,
    required String? fallbackEmail,
    PlaceAddressInfo? resolvedAddress,
    bool addressResolutionFailed = false,
  }) {
    final email = _nonEmpty(google.email) ?? _nonEmpty(fallbackEmail);
    final countryCode = _nonEmpty(resolvedAddress?.countryCode)?.toUpperCase();
    final warnings = <GoogleProfileSyncField>{};

    if (_nonEmpty(google.givenName) == null) {
      warnings.add(GoogleProfileSyncField.givenName);
    }
    if (_nonEmpty(google.surname) == null) {
      warnings.add(GoogleProfileSyncField.surname);
    }
    if (email == null) warnings.add(GoogleProfileSyncField.email);
    final birthday = google.dateOfBirth;
    if (birthday == null ||
        birthday.year < 1900 ||
        birthday.isAfter(DateTime.now())) {
      warnings.add(GoogleProfileSyncField.dateOfBirth);
    }
    if (_nonEmpty(google.address) == null) {
      warnings.add(GoogleProfileSyncField.address);
    }

    if (addressResolutionFailed || _nonEmpty(google.address) == null) {
      warnings.addAll(const {
        GoogleProfileSyncField.town,
        GoogleProfileSyncField.stateOrRegion,
        GoogleProfileSyncField.country,
      });
    } else {
      if (_nonEmpty(resolvedAddress?.town) == null) {
        warnings.add(GoogleProfileSyncField.town);
      }
      if (countryCode == null) {
        warnings.add(GoogleProfileSyncField.country);
      }
      if (countryCode == 'DE' && _nonEmpty(resolvedAddress?.state) == null) {
        warnings.add(GoogleProfileSyncField.stateOrRegion);
      }
    }

    return GoogleProfileSyncPreview(
      givenName: _nonEmpty(google.givenName),
      surname: _nonEmpty(google.surname),
      email: email,
      dateOfBirth: birthday,
      address: _nonEmpty(google.address),
      town: _nonEmpty(resolvedAddress?.town),
      stateOrRegion: _nonEmpty(resolvedAddress?.state),
      countryCode: countryCode,
      warningFields: Set.unmodifiable(warnings),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed?.isNotEmpty == true ? trimmed : null;
  }
}

class GoogleProfileSyncPreviewException implements Exception {
  const GoogleProfileSyncPreviewException(this.preview, [this.cause]);

  final GoogleProfileSyncPreview preview;
  final Object? cause;

  @override
  String toString() =>
      'GoogleProfileSyncPreviewException(warnings: '
      '${preview.warningFields}, cause: $cause)';
}
