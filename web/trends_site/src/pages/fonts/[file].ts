import fs from 'node:fs';
import path from 'node:path';
import type { APIRoute, GetStaticPaths } from 'astro';
import { WEB_ROOT } from '../../lib/site';

// Self-hosted Inter (OFL, Latin subset) from web/shared/fonts; no font CDN.
const FILES = ['Inter-Regular.woff2', 'Inter-Bold.woff2'];

export const getStaticPaths = (() => FILES.map((file) => ({ params: { file } }))) satisfies GetStaticPaths;

export const GET: APIRoute = ({ params }) =>
  new Response(fs.readFileSync(path.join(WEB_ROOT, 'shared', 'fonts', params.file as string)), {
    headers: { 'Content-Type': 'font/woff2' },
  });
