import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';

void main() {
  group('GoogleProfileData.fromPeopleApi', () {
    test('uses the primary full birthday and current location', () {
      final data = GoogleProfileData.fromPeopleApi({
        'names': [
          {
            'metadata': {'primary': true},
            'givenName': 'Leon',
            'familyName': 'Marquardt',
            'displayName': 'Leon Marquardt',
          },
        ],
        'birthdays': [
          {
            'date': {'month': 5, 'day': 8},
          },
          {
            'metadata': {'primary': true},
            'date': {'year': 1992, 'month': 4, 'day': 3},
          },
        ],
        'locations': [
          {
            'metadata': {'primary': true},
            'value': 'Former location',
          },
          {'current': true, 'value': 'Ravensberger Straße 42, 33602 Bielefeld'},
        ],
      });

      expect(data.givenName, 'Leon');
      expect(data.surname, 'Marquardt');
      expect(data.displayName, 'Leon Marquardt');
      expect(data.dateOfBirth, DateTime(1992, 4, 3));
      expect(data.address, 'Ravensberger Straße 42, 33602 Bielefeld');
      expect(data.hasCompleteSyncData, isTrue);
    });

    test('ignores partial birthdays and uses the location value', () {
      final data = GoogleProfileData.fromPeopleApi({
        'birthdays': [
          {
            'date': {'month': 5, 'day': 8},
          },
        ],
        'locations': [
          {'value': 'Main Street 1, 10115 Berlin, Germany'},
        ],
      });

      expect(data.dateOfBirth, isNull);
      expect(data.address, 'Main Street 1, 10115 Berlin, Germany');
      expect(data.hasCompleteSyncData, isFalse);
    });

    test('returns empty data when Google has neither field', () {
      final data = GoogleProfileData.fromPeopleApi(const {});

      expect(data.isEmpty, isTrue);
    });
  });
}
