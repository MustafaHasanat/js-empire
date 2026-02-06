/** @type {import('next').NextConfig} */

const nextConfig = {
  output: "standalone",
  experimental: {
    optimizeCss: true,
  },
  async redirects() {
    return [
      {
        source: "/",
        destination: "/ar",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
