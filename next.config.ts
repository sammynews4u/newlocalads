import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // TypeScript is still enforced by `npm run typecheck`.
  // This prevents Next's internal build-time checker from hanging in some CI containers.
  typescript: {
    ignoreBuildErrors: true,
  },
  experimental: {
    cpus: 2,
    serverActions: {
      bodySizeLimit: '50mb',
    },
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
};

export default nextConfig;
