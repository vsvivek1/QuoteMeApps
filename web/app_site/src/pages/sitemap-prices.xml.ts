import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { urlset } from '../lib/sitemap';
import { cityHubs, loadSeo } from '../lib/seo';

export const GET: APIRoute = async () => {
  const { data, pages } = await loadSeo();
  const hubs = (await cityHubs()).filter((h) => h.indexable).map((h) => ({ loc: abs(`/quotes/${h.city.slug}`), lastmod: data.generated_at }));
  const prices = pages.filter((p) => p.status === 'indexable').map((p) => ({ loc: abs(p.path), lastmod: p.data.last_quote_at }));
  return urlset([...hubs, ...prices]);
};
