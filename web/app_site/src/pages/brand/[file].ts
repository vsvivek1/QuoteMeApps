import fs from 'node:fs';
import path from 'node:path';
import type { APIRoute, GetStaticPaths } from 'astro';
import { REPO_ROOT, country } from '../../lib/site';

// Brand assets are copied from branding/<country>/ at build time (single source of truth).
const FILES: Record<string, string> = {
  'favicon.svg': 'web/favicon.svg',
  'favicon_32.png': 'web/favicon_32.png',
  'apple_touch_icon_180.png': 'web/apple_touch_icon_180.png',
  'og_image_1200x630.png': 'web/og_image_1200x630.png',
  'pwa_192.png': 'web/pwa_192.png',
  'pwa_512.png': 'web/pwa_512.png',
  'logo_mark.svg': 'logo/logo_mark.svg',
  'logo_full.svg': 'logo/logo_full.svg',
  'logo_full_dark.svg': 'logo/logo_full_dark.svg',
};

export const getStaticPaths = (() =>
  Object.entries(FILES).map(([file, src]) => ({ params: { file }, props: { src } }))) satisfies GetStaticPaths;

export const GET: APIRoute = ({ props }) => {
  const buf = fs.readFileSync(path.join(REPO_ROOT, 'branding', country, props.src as string));
  return new Response(buf);
};
