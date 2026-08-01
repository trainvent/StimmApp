import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_preview.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

void main() {
  group('GoogleProfileSyncPreview', () {
    test('shows the authenticated email when the stored profile omits it', () {
      final preview = GoogleProfileSyncPreview.fromProfile(
        const UserProfile(uid: 'user'),
        fallbackEmail: 'linked@example.com',
      );

      expect(preview.email, 'linked@example.com');
    });

    test('accepts complete Google and resolved address data', () {
      final preview = GoogleProfileSyncPreview.fromGoogle(
        google: GoogleProfileData(
          givenName: 'Leon',
          surname: 'Marquardt',
          email: 'leon@example.com',
          dateOfBirth: DateTime(1992, 4, 3),
          address: 'Ravensberger Straße 42, Bielefeld',
        ),
        fallbackEmail: null,
        resolvedAddress: const PlaceAddressInfo(
          town: 'Bielefeld',
          state: 'Nordrhein-Westfalen',
          countryCode: 'DE',
        ),
      );

      expect(preview.canSynchronize, isTrue);
      expect(preview.warningFields, isEmpty);
    });

    test('marks every unavailable Google field', () {
      final preview = GoogleProfileSyncPreview.fromGoogle(
        google: const GoogleProfileData(),
        fallbackEmail: null,
      );

      expect(preview.canSynchronize, isFalse);
      expect(preview.warningFields, containsAll(GoogleProfileSyncField.values));
    });

    test('uses authenticated email when People API omits it', () {
      final preview = GoogleProfileSyncPreview.fromGoogle(
        google: GoogleProfileData(
          givenName: 'Leon',
          surname: 'Marquardt',
          dateOfBirth: DateTime(1992, 4, 3),
          address: 'Main Street 1, London',
        ),
        fallbackEmail: 'linked@example.com',
        resolvedAddress: const PlaceAddressInfo(
          town: 'London',
          countryCode: 'GB',
        ),
      );

      expect(preview.email, 'linked@example.com');
      expect(
        preview.warningFields,
        isNot(contains(GoogleProfileSyncField.email)),
      );
      expect(
        preview.warningFields,
        isNot(contains(GoogleProfileSyncField.stateOrRegion)),
      );
    });

    test('marks resolved location fields when address resolution fails', () {
      final preview = GoogleProfileSyncPreview.fromGoogle(
        google: GoogleProfileData(
          givenName: 'Leon',
          surname: 'Marquardt',
          email: 'leon@example.com',
          dateOfBirth: DateTime(1992, 4, 3),
          address: 'Unknown address',
        ),
        fallbackEmail: null,
        addressResolutionFailed: true,
      );

      expect(
        preview.warningFields,
        containsAll(const {
          GoogleProfileSyncField.town,
          GoogleProfileSyncField.stateOrRegion,
          GoogleProfileSyncField.country,
        }),
      );
      expect(
        preview.warningFields,
        isNot(contains(GoogleProfileSyncField.address)),
      );
    });
  });
}
