import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';

void main() {
  group('GoogleProfileData.fromPeopleApi', () {
    test('uses the primary full birthday and formatted address', () {
      final data = GoogleProfileData.fromPeopleApi({
        'birthdays': [
          {
            'date': {'month': 5, 'day': 8},
          },
          {
            'metadata': {'primary': true},
            'date': {'year': 1992, 'month': 4, 'day': 3},
          },
        ],
        'addresses': [
          {'formattedValue': 'Work address'},
          {
            'metadata': {'primary': true},
            'formattedValue': 'Ravensberger Straße 42, 33602 Bielefeld',
          },
        ],
      });

      expect(data.dateOfBirth, DateTime(1992, 4, 3));
      expect(
        data.address,
        'Ravensberger Straße 42, 33602 Bielefeld',
      );
    });

    test('ignores partial birthdays and builds a structured address', () {
      final data = GoogleProfileData.fromPeopleApi({
        'birthdays': [
          {
            'date': {'month': 5, 'day': 8},
          },
        ],
        'addresses': [
          {
            'streetAddress': 'Main Street 1',
            'postalCode': '10115',
            'city': 'Berlin',
            'country': 'Germany',
          },
        ],
      });

      expect(data.dateOfBirth, isNull);
      expect(data.address, 'Main Street 1, 10115 Berlin, Germany');
    });

    test('returns empty data when Google has neither field', () {
      final data = GoogleProfileData.fromPeopleApi(const {});

      expect(data.isEmpty, isTrue);
    });
  });
}
