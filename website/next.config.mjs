import path from 'node:path';
import { PHASE_DEVELOPMENT_SERVER } from 'next/constants.js';

const basePath = process.env.PAGES_BASE_PATH || '';
const staticHtmlRoutes = [
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
      }
    : { output: 'export' }),
});

export default nextConfig;
