enum FormScopeType { global, eu, continent, country, stateOrRegion, city }

FormScopeType parseFormScopeType(String? raw) {
  switch (raw) {
    case 'global':
      return FormScopeType.global;
    case 'eu':
      return FormScopeType.eu;
    case 'continent':
      return FormScopeType.continent;
    case 'country':
      return FormScopeType.country;
    case 'stateOrRegion':
      return FormScopeType.stateOrRegion;
    case 'city':
    case 'town':
      return FormScopeType.city;
    default:
      return FormScopeType.global;
  }
}

String formScopeTypeToFirestore(FormScopeType scopeType) {
  switch (scopeType) {
    case FormScopeType.global:
      return 'global';
    case FormScopeType.eu:
      return 'eu';
    case FormScopeType.continent:
      return 'continent';
    case FormScopeType.country:
      return 'country';
    case FormScopeType.stateOrRegion:
      return 'stateOrRegion';
    case FormScopeType.city:
      return 'city';
  }
}
