import path from 'node:path';

const basePath = process.env.PAGES_BASE_PATH || '';

/** @type {import('next').NextConfig} */
const nextConfig = {
  assetPrefix: basePath,
  basePath,
  images: {
    unoptimized: true,
  },
  output: 'export',
  outputFileTracingRoot: path.join(process.cwd(), '..'),
};

export default nextConfig;
