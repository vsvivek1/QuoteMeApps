import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { urlset } from '../lib/sitemap';
import { loadGuides } from '../lib/seo';

// Only published guides reviewed within the last six months (Section 21.9).
export const GET: APIRoute = async () => {
  const guides = (await loadGuides()).filter((g) => g.status === 'indexable');
  const entries = guides.map((g) => ({ loc: abs(g.path), lastmod: g.data.updated_at ?? g.data.reviewed_at }));
  if (entries.length) entries.unshift({ loc: abs('/guides'), lastmod: entries[0].lastmod });
  return urlset(entries);
};
