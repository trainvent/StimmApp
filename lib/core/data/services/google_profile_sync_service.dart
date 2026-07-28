import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';

class GoogleProfileSyncException implements Exception {
  const GoogleProfileSyncException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'GoogleProfileSyncException($code, $message)';
}

class GoogleProfileSyncService {
  GoogleProfileSyncService({
    AuthService? auth,
    UserRepository? users,
    TomTomSearchService? addresses,
  }) : _auth = auth ?? authService,
       _users = users ?? UserRepository.create(),
       _addresses = addresses ?? TomTomSearchService(IConst.tomTomSearchApiKey);

  final AuthService _auth;
  final UserRepository _users;
  final TomTomSearchService _addresses;

  Future<UserProfile> synchronize({
    required UserProfile profile,
    bool activate = false,
    bool promptIfNecessary = true,
  }) async {
    final google = await _auth.importGoogleProfileData(
      promptIfNecessary: promptIfNecessary,
    );
    _validate(google);

    final address = google.address!.trim();
    var town = profile.town;
    var state = profile.state;
    var countryCode = profile.countryCode;

    if (address != profile.address?.trim() ||
        town?.isNotEmpty != true ||
        countryCode?.isNotEmpty != true) {
      final resolved = await _addresses.resolveAddress(address);
      town = resolved.town;
      state = resolved.state;
      countryCode = resolved.countryCode?.toUpperCase();
      if (town?.isNotEmpty != true || countryCode?.isNotEmpty != true) {
        throw const GoogleProfileSyncException(
          'address-not-resolved',
          'The Google location could not be resolved to a town and country.',
        );
      }
      if (countryCode == 'DE' && state?.isNotEmpty != true) {
        throw const GoogleProfileSyncException(
          'state-not-resolved',
          'The German state could not be resolved from the Google location.',
        );
      }
    }

    final displayName = normalizeUsername(google.displayName!);
    final updated = profile.copyWith(
      givenName: _clampName(google.givenName!),
      surname: _clampName(google.surname!),
      displayName: displayName,
      dateOfBirth: google.dateOfBirth,
      address: address,
      town: town,
      state: countryCode == 'DE' ? state : null,
      countryCode: countryCode,
      isGoogleSyncActive: activate || profile.isGoogleSyncActive == true,
      googleSyncLastAt: DateTime.now(),
    );

    await _users.upsertWithUniqueUsername(updated);
    await _auth.updateUsername(username: displayName);
    return updated;
  }

  Future<void> setActive(UserProfile profile, bool active) async {
    await _users.upsert(profile.copyWith(isGoogleSyncActive: active));
  }

  void _validate(GoogleProfileData data) {
    if (!data.hasCompleteSyncData) {
      throw const GoogleProfileSyncException(
        'incomplete-google-profile',
        'Google must provide a full name, display name, birthday, and location.',
      );
    }
    if (data.dateOfBirth!.year < 1900) {
      throw const GoogleProfileSyncException(
        'invalid-birthday',
        'Google returned an unsupported birthday.',
      );
    }
    if (normalizeUsername(data.displayName!).isEmpty) {
      throw const GoogleProfileSyncException(
        'invalid-display-name',
        'Google returned an unsupported display name.',
      );
    }
  }

  String _clampName(String value) {
    final trimmed = value.trim();
    return trimmed.length <= AppLimits.maxPersonNameLength
        ? trimmed
        : trimmed.substring(0, AppLimits.maxPersonNameLength);
  }
}
