import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { urlset } from '../lib/sitemap';
import { loadSeo, loadSellers, sellerCities } from '../lib/seo';

// Seller directory: only sellers that pass the quality bar in lib/seo.ts.
export const GET: APIRoute = async () => {
  const { data } = await loadSeo();
  const dirs = (await sellerCities()).filter((c) => c.indexable).map((c) => ({ loc: abs(c.path), lastmod: data.generated_at }));
  const sellers = (await loadSellers()).filter((s) => s.status === 'indexable').map((s) => ({ loc: abs(s.path), lastmod: data.generated_at }));
  return urlset([...dirs, ...sellers]);
};
