import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/functions/form_scope_eligibility.dart';

Petition _petition({
  required String scopeType,
  String? countryCode,
  String? stateOrRegion,
  String? town,
}) {
  return Petition(
    id: 'petition',
    title: 'Title',
    description: 'Description',
    tags: const [],
    signatureCount: 0,
    createdBy: 'creator',
    createdAt: DateTime(2026),
    expiresAt: DateTime(2027),
    scopeType: scopeType,
    countryCode: countryCode,
    stateOrRegion: stateOrRegion,
    town: town,
  );
}

void main() {
  group('isHomeItemInUserZone', () {
    test('global items are always in zone', () {
      expect(
        isHomeItemInUserZone(
          item: _petition(scopeType: 'global'),
          userProfile: null,
        ),
        isTrue,
      );
    });

    test('country scope requires the same country', () {
      final item = _petition(scopeType: 'country', countryCode: 'DE');

      expect(
        isHomeItemInUserZone(
          item: item,
          userProfile: const UserProfile(uid: 'de', countryCode: 'DE'),
        ),
        isTrue,
      );
      expect(
        isHomeItemInUserZone(
          item: item,
          userProfile: const UserProfile(uid: 'us', countryCode: 'US'),
        ),
        isFalse,
      );
    });

    test('city scope compares country, state, and town', () {
      final item = _petition(
        scopeType: 'city',
        countryCode: 'DE',
        stateOrRegion: 'Bayern',
        town: 'München',
      );

      expect(
        isHomeItemInUserZone(
          item: item,
          userProfile: const UserProfile(
            uid: 'munich',
            countryCode: 'DE',
            state: 'Bayern',
            town: 'münchen',
          ),
        ),
        isTrue,
      );
      expect(
        isHomeItemInUserZone(
          item: item,
          userProfile: const UserProfile(
            uid: 'berlin',
            countryCode: 'DE',
            state: 'Berlin',
            town: 'Berlin',
          ),
        ),
        isFalse,
      );
    });
  });
}
