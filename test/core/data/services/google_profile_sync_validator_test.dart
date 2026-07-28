import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_validator.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

void main() {
  group('GoogleProfileSyncValidator', () {
    final completeGoogleData = GoogleProfileData(
      givenName: 'Leon',
      surname: 'Marquardt',
      dateOfBirth: DateTime(1992, 4, 3),
      address: 'Ravensberger Straße 42, 33602 Bielefeld',
    );

    test('accepts complete Google identity data', () {
      expect(
        () => GoogleProfileSyncValidator.validateGoogleData(completeGoogleData),
        returnsNormally,
      );
    });

    test('rejects each missing required Google field', () {
      final cases = <String, GoogleProfileData>{
        'missing-given-name': GoogleProfileData(
          surname: completeGoogleData.surname,
          dateOfBirth: completeGoogleData.dateOfBirth,
          address: completeGoogleData.address,
        ),
        'missing-surname': GoogleProfileData(
          givenName: completeGoogleData.givenName,
          dateOfBirth: completeGoogleData.dateOfBirth,
          address: completeGoogleData.address,
        ),
        'missing-birthday': GoogleProfileData(
          givenName: completeGoogleData.givenName,
          surname: completeGoogleData.surname,
          address: completeGoogleData.address,
        ),
        'missing-address': GoogleProfileData(
          givenName: completeGoogleData.givenName,
          surname: completeGoogleData.surname,
          dateOfBirth: completeGoogleData.dateOfBirth,
        ),
      };

      for (final entry in cases.entries) {
        expect(
          () => GoogleProfileSyncValidator.validateGoogleData(entry.value),
          throwsA(
            isA<GoogleProfileSyncException>().having(
              (error) => error.code,
              'code',
              entry.key,
            ),
          ),
        );
      }
    });

    test('rejects a location TomTom cannot resolve', () {
      expect(
        () => GoogleProfileSyncValidator.validateResolvedAddress(
          const PlaceAddressInfo(),
        ),
        throwsA(
          isA<GoogleProfileSyncException>().having(
            (error) => error.code,
            'code',
            'address-not-resolved',
          ),
        ),
      );
    });

    test('requires a state for German addresses', () {
      expect(
        () => GoogleProfileSyncValidator.validateResolvedAddress(
          const PlaceAddressInfo(town: 'Bielefeld', countryCode: 'DE'),
        ),
        throwsA(
          isA<GoogleProfileSyncException>().having(
            (error) => error.code,
            'code',
            'state-not-resolved',
          ),
        ),
      );
    });

    test('accepts a complete TomTom result', () {
      expect(
        () => GoogleProfileSyncValidator.validateResolvedAddress(
          const PlaceAddressInfo(
            town: 'Bielefeld',
            state: 'Nordrhein-Westfalen',
            countryCode: 'DE',
          ),
        ),
        returnsNormally,
      );
    });
  });
}
