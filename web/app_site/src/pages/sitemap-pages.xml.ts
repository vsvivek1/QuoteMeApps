import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { legalPages } from '../lib/legal';
import { urlset } from '../lib/sitemap';

export const GET: APIRoute = async () => {
  const fixed = ['/', '/sellers', '/waitlist', '/contact', '/about', '/editorial-policy', '/quotes', '/legal', '/legal/open-source'];
  const legal = (await legalPages()).map((p) => ({ loc: abs(`/legal/${p.data.slug}`), lastmod: p.data.last_updated.toISOString() }));
  return urlset([...fixed.map((p) => ({ loc: abs(p) })), ...legal]);
};
