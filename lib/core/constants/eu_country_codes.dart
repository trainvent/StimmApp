const Set<String> euCountryCodes = <String>{
  'AT',
  'BE',
  'BG',
  'HR',
  'CY',
  'CZ',
  'DK',
  'EE',
  'FI',
  'FR',
  'DE',
  'GR',
  'HU',
  'IE',
  'IT',
  'LV',
  'LT',
  'LU',
  'MT',
  'NL',
  'PL',
  'PT',
  'RO',
  'SK',
  'SI',
  'ES',
  'SE',
};

bool isEuCountryCode(String? countryCode) {
  if (countryCode == null) return false;
  return euCountryCodes.contains(countryCode.toUpperCase());
}
