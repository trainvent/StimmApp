import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { contentRouteSlugs, legacyRoutes } from '../lib/content-routes.mjs';

const redirectDocument = (destination) =>
  `<!doctype html><meta charset="utf-8"><title>Redirecting…</title><script>location.replace('/${destination}'+location.search+location.hash)</script><a href="/${destination}">Continue</a>\n`;

await Promise.all(
  contentRouteSlugs.map((route) =>
    writeFile(path.join('out', `${route}.html`), redirectDocument(route)),
  ),
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
