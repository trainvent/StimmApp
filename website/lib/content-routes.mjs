export const contentRoutes = {
  datenschutzerklaerung: { page: 'privacyPolicy', locale: 'de' },
  'datenschutzerklaerung-absturzdaten': {
    page: 'privacyPolicyCrashData',
    locale: 'de',
  },
  'delete-account': { page: 'deleteAccount' },
  faq: { page: 'faq' },
  license: { page: 'license' },
  marketing: { page: 'marketing' },
  nutzungsbedingungen: { page: 'termsOfService', locale: 'de' },
  'privacy-policy': { page: 'privacyPolicy', locale: 'en' },
  'privacy-policy-crash-data': {
    page: 'privacyPolicyCrashData',
    locale: 'en',
  },
  support: { page: 'support' },
  'terms-of-service': { page: 'termsOfService', locale: 'en' },
};

export const contentRouteSlugs = Object.keys(contentRoutes);

export const legacyRoutes = {
  datenschutzerklaerung_absturzdaten:
    'datenschutzerklaerung-absturzdaten',
  privacy_policy: 'privacy-policy',
  privacy_policy_crashdata: 'privacy-policy-crash-data',
};
