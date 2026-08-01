import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_preview.dart';
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

    final address = google.address?.trim() ?? '';
    var town = profile.town;
    var state = profile.state;
    var countryCode = profile.countryCode;

    Object? addressResolutionError;
    if (address.isNotEmpty &&
        (activate ||
            address != profile.address?.trim() ||
            town?.isNotEmpty != true ||
            countryCode?.isNotEmpty != true ||
            (countryCode?.toUpperCase() == 'DE' &&
                state?.isNotEmpty != true))) {
      try {
        final resolved = await _addresses.resolveAddress(address);
        town = resolved.town;
        state = resolved.state;
        countryCode = resolved.countryCode?.toUpperCase();
      } catch (error) {
        addressResolutionError = error;
        town = null;
        state = null;
        countryCode = null;
      }
    }
    final preview = GoogleProfileSyncPreview.fromGoogle(
      google: google,
      fallbackEmail: _auth.authenticatedEmail ?? profile.email,
      resolvedAddress: PlaceAddressInfo(
        town: town,
        state: state,
        countryCode: countryCode,
      ),
      addressResolutionFailed: addressResolutionError != null,
    );
    if (!preview.canSynchronize) {
      throw GoogleProfileSyncPreviewException(preview, addressResolutionError);
    }

    final updated = profile.copyWith(
      givenName: _clampName(preview.givenName!),
      surname: _clampName(preview.surname!),
      email: preview.email,
      dateOfBirth: preview.dateOfBirth,
      address: preview.address,
      town: preview.town,
      state: preview.countryCode == 'DE' ? preview.stateOrRegion : null,
      countryCode: preview.countryCode,
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
