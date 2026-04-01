import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

class AdConsentService {
  AdConsentService._();

  static const Set<String> _consentRegionCountryCodes = {
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
    'IS',
    'IT',
    'LV',
    'LI',
    'LT',
    'LU',
    'MT',
    'NL',
    'NO',
    'PL',
    'PT',
    'RO',
    'SK',
    'SI',
    'ES',
    'SE',
    'GB',
    'CH',
  };

  static bool isInConsentRegion(UserProfile? profile) {
    final code = profile?.countryCode?.toUpperCase();
    if (code == null || code.isEmpty) return false;
    return _consentRegionCountryCodes.contains(code);
  }

  static bool requiresAdsConsent(UserProfile? profile) {
    if (kIsWeb) return false;
    if (profile?.isPro == true) return false;
    return isInConsentRegion(profile);
  }

  static bool hasResolvedAdsConsent(UserProfile? profile) {
    if (!requiresAdsConsent(profile)) return true;
    return profile?.adsConsentGranted != null;
  }

  static bool canShowAds(UserProfile? profile) {
    if (profile?.isPro == true) return false;
    if (!requiresAdsConsent(profile)) return true;
    return profile?.adsConsentGranted == true;
  }

  static bool shouldPromptForAdsConsent(UserProfile? profile) {
    if (profile == null) return false;
    if (!requiresAdsConsent(profile)) return false;
    return profile.adsConsentGranted == null;
  }
}
