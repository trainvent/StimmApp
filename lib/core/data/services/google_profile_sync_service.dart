import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_validator.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

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
    GoogleProfileSyncValidator.validateGoogleData(google);

    final address = google.address!.trim();
    var town = profile.town;
    var state = profile.state;
    var countryCode = profile.countryCode;

    if (activate ||
        address != profile.address?.trim() ||
        town?.isNotEmpty != true ||
        countryCode?.isNotEmpty != true ||
        (countryCode?.toUpperCase() == 'DE' && state?.isNotEmpty != true)) {
      final resolved = await _addresses.resolveAddress(address);
      town = resolved.town;
      state = resolved.state;
      countryCode = resolved.countryCode?.toUpperCase();
    }
    GoogleProfileSyncValidator.validateResolvedAddress(
      PlaceAddressInfo(town: town, state: state, countryCode: countryCode),
    );

    final updated = profile.copyWith(
      givenName: _clampName(google.givenName!),
      surname: _clampName(google.surname!),
      email: google.email ?? _auth.currentUser?.email ?? profile.email,
      dateOfBirth: google.dateOfBirth,
      address: address,
      town: town,
      state: countryCode == 'DE' ? state : null,
      countryCode: countryCode,
      isGoogleSyncActive: activate || profile.isGoogleSyncActive == true,
      googleSyncLastAt: DateTime.now(),
    );

    await _users.upsertWithUniqueUsername(updated);
    return updated;
  }

  Future<void> setActive(UserProfile profile, bool active) async {
    await _users.upsert(profile.copyWith(isGoogleSyncActive: active));
  }

  String _clampName(String value) {
    final trimmed = value.trim();
    return trimmed.length <= AppLimits.maxPersonNameLength
        ? trimmed
        : trimmed.substring(0, AppLimits.maxPersonNameLength);
  }
}
