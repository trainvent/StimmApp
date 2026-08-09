enum FormScopeType {
  global,
  countryUnion,
  continent,
  country,
  stateOrRegion,
  city,
}

enum CountryUnion { eu, un }

FormScopeType parseFormScopeType(String? raw) {
  switch (raw) {
    case 'countryUnion':
    case 'eu':
      return FormScopeType.countryUnion;
    case 'continent':
      return FormScopeType.continent;
    case 'country':
      return FormScopeType.country;
    case 'stateOrRegion':
      return FormScopeType.stateOrRegion;
    case 'city':
    case 'town':
      return FormScopeType.city;
    case 'global':
    default:
      return FormScopeType.global;
  }
}

String formScopeTypeToFirestore(FormScopeType scopeType) => scopeType.name;

CountryUnion? parseCountryUnion(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'EU':
      return CountryUnion.eu;
    case 'UN':
      return CountryUnion.un;
    default:
      return null;
  }
}

extension CountryUnionCode on CountryUnion {
  String get code => name.toUpperCase();
}

bool matchesFormScopeFilter({
  required FormScope scope,
  required Set<FormScopeType> selectedTypes,
  required Set<CountryUnion> selectedCountryUnions,
}) {
  if (selectedTypes.isEmpty) return true;
  if (!selectedTypes.contains(scope.type)) return false;
  if (scope.type != FormScopeType.countryUnion ||
      selectedCountryUnions.isEmpty) {
    return true;
  }
  return selectedCountryUnions.contains(scope.countryUnion);
}

class FormScope {
  const FormScope._({
    required this.type,
    this.countryUnion,
    this.continentCode,
    this.countryCode,
    this.stateOrRegion,
    this.town,
  });

  const FormScope.global() : this._(type: FormScopeType.global);

  const FormScope.countryUnion(CountryUnion union)
    : this._(type: FormScopeType.countryUnion, countryUnion: union);

  const FormScope.continent(String code)
    : this._(type: FormScopeType.continent, continentCode: code);

  const FormScope.country(String code)
    : this._(type: FormScopeType.country, countryCode: code);

  const FormScope.stateOrRegion({
    required String countryCode,
    required String stateOrRegion,
  }) : this._(
         type: FormScopeType.stateOrRegion,
         countryCode: countryCode,
         stateOrRegion: stateOrRegion,
       );

  const FormScope.city({
    required String countryCode,
    String? stateOrRegion,
    required String town,
  }) : this._(
         type: FormScopeType.city,
         countryCode: countryCode,
         stateOrRegion: stateOrRegion,
         town: town,
       );

  final FormScopeType type;
  final CountryUnion? countryUnion;
  final String? continentCode;
  final String? countryCode;
  final String? stateOrRegion;
  final String? town;

  String get firestoreType => formScopeTypeToFirestore(type);

  String get scopeKey {
    switch (type) {
      case FormScopeType.global:
        return 'global';
      case FormScopeType.countryUnion:
        return 'countryUnion:${countryUnion?.code ?? 'unknown'}';
      case FormScopeType.continent:
        return 'continent:${_normalizedCode(continentCode) ?? 'unknown'}';
      case FormScopeType.country:
        return 'country:${_normalizedCode(countryCode) ?? 'unknown'}';
      case FormScopeType.stateOrRegion:
        return 'state:${_normalizedCode(countryCode) ?? 'unknown'}:'
            '${_normalizedText(stateOrRegion) ?? 'unknown'}';
      case FormScopeType.city:
        return 'city:${_normalizedCode(countryCode) ?? 'unknown'}:'
            '${_normalizedText(stateOrRegion) ?? '-'}:'
            '${_normalizedText(town) ?? 'unknown'}';
    }
  }

  factory FormScope.fromFirestore(Map<String, dynamic> data) {
    final rawType = data['scopeType'] as String?;
    final countryCode = _normalizedCode(data['countryCode'] as String?);
    final stateOrRegion = _trimmed(
      data['stateOrRegion'] as String? ?? data['state'] as String?,
    );
    final town = _trimmed(data['town'] as String? ?? data['city'] as String?);
    final continentCode = _normalizedCode(data['continentCode'] as String?);

    // Existing EU documents used either scopeType=eu or continentCode=EU.
    if (rawType == 'eu' || (rawType == 'continent' && continentCode == 'EU')) {
      return const FormScope.countryUnion(CountryUnion.eu);
    }

    final type = rawType == null || rawType.isEmpty
        ? _inferLegacyType(
            countryCode: countryCode,
            stateOrRegion: stateOrRegion,
            town: town,
          )
        : parseFormScopeType(rawType);

    switch (type) {
      case FormScopeType.global:
        return const FormScope.global();
      case FormScopeType.countryUnion:
        return FormScope.countryUnion(
          parseCountryUnion(data['scopeUnionCode'] as String?) ??
              CountryUnion.eu,
        );
      case FormScopeType.continent:
        return FormScope.continent(continentCode ?? '');
      case FormScopeType.country:
        return FormScope.country(countryCode ?? '');
      case FormScopeType.stateOrRegion:
        return FormScope.stateOrRegion(
          countryCode: countryCode ?? '',
          stateOrRegion: stateOrRegion ?? '',
        );
      case FormScopeType.city:
        return FormScope.city(
          countryCode: countryCode ?? '',
          stateOrRegion: stateOrRegion,
          town: town ?? '',
        );
    }
  }

  Map<String, Object?> toFirestoreFields() => {
    'scopeType': firestoreType,
    'scopeUnionCode': countryUnion?.code,
    'continentCode': _normalizedCode(continentCode),
    'countryCode': _normalizedCode(countryCode),
    'stateOrRegion': stateOrRegion,
    'state': stateOrRegion,
    'town': town,
    'city': town,
    'scopeKey': scopeKey,
  };

  static FormScopeType _inferLegacyType({
    required String? countryCode,
    required String? stateOrRegion,
    required String? town,
  }) {
    if (town != null && town.isNotEmpty) return FormScopeType.city;
    if (stateOrRegion != null && stateOrRegion.isNotEmpty) {
      return FormScopeType.stateOrRegion;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      return FormScopeType.country;
    }
    return FormScopeType.global;
  }

  static String? _normalizedCode(String? value) =>
      _trimmed(value)?.toUpperCase();

  static String? _normalizedText(String? value) =>
      _trimmed(value)?.toLowerCase();

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormScope &&
          type == other.type &&
          countryUnion == other.countryUnion &&
          continentCode == other.continentCode &&
          countryCode == other.countryCode &&
          stateOrRegion == other.stateOrRegion &&
          town == other.town;

  @override
  int get hashCode => Object.hash(
    type,
    countryUnion,
    continentCode,
    countryCode,
    stateOrRegion,
    town,
  );
}
