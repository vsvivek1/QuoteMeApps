import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { urlset } from '../lib/sitemap';
import { townPages } from '../lib/towns';

// Town pages (/in/<slug>): indexable ones only. English only, so no hreflang alternates (same as price pages).
export const GET: APIRoute = async () => urlset((await townPages()).filter((p) => p.indexable).map((p) => ({ loc: abs(p.path) })));
