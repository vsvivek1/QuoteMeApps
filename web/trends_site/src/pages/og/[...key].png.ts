import type { APIRoute, GetStaticPaths } from 'astro';
import { ogEntries, renderOg, type OgSpec } from '../../lib/og';

// Open Graph images (1200x630 PNG), rendered once at build time. See lib/og.ts.
export const getStaticPaths = (() =>
  [...ogEntries()].map(([key, spec]) => ({ params: { key }, props: { spec } }))) satisfies GetStaticPaths;

export const GET: APIRoute = ({ props }) =>
  new Response(new Uint8Array(renderOg(props.spec as OgSpec)), { headers: { 'Content-Type': 'image/png' } });
