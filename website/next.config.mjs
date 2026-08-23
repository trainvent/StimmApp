import path from 'node:path';
import { PHASE_DEVELOPMENT_SERVER } from 'next/constants.js';

const basePath = process.env.PAGES_BASE_PATH || '';
const staticHtmlRoutes = [
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
const legacyHtmlRoutes = {
  '/datenschutzerklaerung_absturzdaten':
    '/datenschutzerklaerung-absturzdaten',
  '/privacy_policy': '/privacy-policy',
  '/privacy_policy_crashdata': '/privacy-policy-crash-data',
};

/** @type {import('next').NextConfig} */
const nextConfig = (phase) => ({
  assetPrefix: basePath,
  basePath,
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  outputFileTracingRoot: path.join(process.cwd(), '..'),
  ...(phase === PHASE_DEVELOPMENT_SERVER
    ? {
        rewrites: async () =>
          staticHtmlRoutes.map((route) => ({
            source: `/${route}`,
            destination: `/${route}.html`,
          })),
        redirects: async () =>
          Object.entries(legacyHtmlRoutes).map(([source, destination]) => ({
            source,
            destination,
            permanent: true,
          })),
      }
    : { output: 'export' }),
});

export default nextConfig;
