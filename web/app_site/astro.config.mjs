// @ts-check
import { defineConfig } from 'astro/config';
import { site } from './src/lib/site.ts';

// One codebase, two sites: SITE_COUNTRY=usa|india picks the country at build time.
export default defineConfig({
  site: site.url,
  output: 'static',
  trailingSlash: 'never',
  build: {
    // legal/privacy-policy.html, served at /legal/privacy-policy by Vercel cleanUrls.
    format: 'file',
    // Keep CSS and JS in external files so the CSP needs no 'unsafe-inline'.
    inlineStylesheets: 'never',
  },
  vite: { build: { assetsInlineLimit: 0 } },
  devToolbar: { enabled: false },
});
