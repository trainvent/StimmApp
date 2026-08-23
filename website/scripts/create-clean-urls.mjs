import { copyFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const routes = [
  'datenschutzerklaerung',
  'datenschutzerklaerung_absturzdaten',
  'delete-account',
  'faq',
  'license',
  'marketing',
  'nutzungsbedingungen',
  'privacy-policy',
  'privacy_policy',
  'privacy_policy_crashdata',
  'support',
  'terms-of-service',
];

await Promise.all(
  routes.map(async (route) => {
    const legacyFile = path.join('out', `${route}.html`);
    const routeDirectory = path.join('out', route);
    await mkdir(routeDirectory, { recursive: true });
    await copyFile(legacyFile, path.join(routeDirectory, 'index.html'));
    await writeFile(
      legacyFile,
      `<!doctype html><meta charset="utf-8"><title>Redirecting…</title><script>location.replace('/${route}'+location.search+location.hash)</script><a href="/${route}">Continue</a>\n`,
    );
  }),
);
