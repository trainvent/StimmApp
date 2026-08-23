import { copyFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const canonicalRoutes = [
  'datenschutzerklaerung',
  'datenschutzerklaerung-absturzdaten',
  'delete-account',
  'faq',
  'license',
  'marketing',
  'nutzungsbedingungen',
  'privacy-policy',
  'privacy-policy-crash-data',
  'support',
  'terms-of-service',
];
const legacyRoutes = {
  datenschutzerklaerung_absturzdaten:
    'datenschutzerklaerung-absturzdaten',
  privacy_policy: 'privacy-policy',
  privacy_policy_crashdata: 'privacy-policy-crash-data',
};

const redirectDocument = (destination) =>
  `<!doctype html><meta charset="utf-8"><title>Redirecting…</title><script>location.replace('/${destination}'+location.search+location.hash)</script><a href="/${destination}">Continue</a>\n`;

await Promise.all(
  canonicalRoutes.map(async (route) => {
    const legacyFile = path.join('out', `${route}.html`);
    const routeDirectory = path.join('out', route);
    await mkdir(routeDirectory, { recursive: true });
    await copyFile(legacyFile, path.join(routeDirectory, 'index.html'));
    await writeFile(legacyFile, redirectDocument(route));
  }),
);

await Promise.all(
  Object.entries(legacyRoutes).map(async ([legacyRoute, canonicalRoute]) => {
    const redirect = redirectDocument(canonicalRoute);
    const routeDirectory = path.join('out', legacyRoute);
    await mkdir(routeDirectory, { recursive: true });
    await Promise.all([
      writeFile(path.join(routeDirectory, 'index.html'), redirect),
      writeFile(path.join('out', `${legacyRoute}.html`), redirect),
    ]);
  }),
);
