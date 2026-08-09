import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/country_union_memberships.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';

void main() {
  group('country-union membership', () {
    test('contains the official full-member counts', () {
      expect(euMemberCountryCodes, hasLength(27));
      expect(unMemberCountryCodes, hasLength(193));
    });

    test('a German profile belongs to both EU and UN', () {
      expect(countryUnionsForCountry('de'), {CountryUnion.eu, CountryUnion.un});
    });

    test('a US profile belongs to UN but not EU', () {
      expect(countryUnionsForCountry('US'), {CountryUnion.un});
    });

    test('UN observers and non-members are excluded', () {
      expect(unMemberCountryCodes, isNot(contains('PS')));
      expect(unMemberCountryCodes, isNot(contains('VA')));
      expect(unMemberCountryCodes, isNot(contains('TW')));
      expect(unMemberCountryCodes, isNot(contains('XK')));
    });
  });

  group('FormScope Firestore serialization', () {
    test('writes a normalized UN country-union scope', () {
      const scope = FormScope.countryUnion(CountryUnion.un);

      expect(scope.toFirestoreFields(), {
        'scopeType': 'countryUnion',
        'scopeUnionCode': 'UN',
        'continentCode': null,
        'countryCode': null,
        'stateOrRegion': null,
        'state': null,
        'town': null,
        'city': null,
        'scopeKey': 'countryUnion:UN',
      });
    });

    test('reads legacy EU scope documents as a country union', () {
      final scope = FormScope.fromFirestore({
        'scopeType': 'eu',
        'continentCode': 'EU',
      });

      expect(scope, const FormScope.countryUnion(CountryUnion.eu));
      expect(scope.firestoreType, 'countryUnion');
    });
  });

  group('matchesFormScopeFilter', () {
    test('an empty union sub-selection includes every union', () {
      expect(
        matchesFormScopeFilter(
          scope: const FormScope.countryUnion(CountryUnion.eu),
          selectedTypes: {FormScopeType.countryUnion},
          selectedCountryUnions: const {},
        ),
        isTrue,
      );
      expect(
        matchesFormScopeFilter(
          scope: const FormScope.countryUnion(CountryUnion.un),
          selectedTypes: {FormScopeType.countryUnion},
          selectedCountryUnions: const {},
        ),
        isTrue,
      );
    });

    test('a union sub-selection narrows the category', () {
      expect(
        matchesFormScopeFilter(
          scope: const FormScope.countryUnion(CountryUnion.eu),
          selectedTypes: {FormScopeType.countryUnion},
          selectedCountryUnions: {CountryUnion.un},
        ),
        isFalse,
      );
      expect(
        matchesFormScopeFilter(
          scope: const FormScope.countryUnion(CountryUnion.un),
          selectedTypes: {FormScopeType.countryUnion},
          selectedCountryUnions: {CountryUnion.un},
        ),
        isTrue,
      );
    });
  });
}
