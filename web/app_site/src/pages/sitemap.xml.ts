import type { APIRoute } from 'astro';
import { abs, site } from '../lib/site';
import { sitemapIndex } from '../lib/sitemap';
import { loadGuides, loadSellers, loadSeo } from '../lib/seo';
import { TOWN_SITEMAP_SIZE } from '../lib/sitemap';
import { LOCALES } from '../lib/i18n';
import { stateSitemapEntries, townSitemapEntries } from '../lib/town-sitemap';

// Sitemaps are split by type and list only indexable pages (Section 21.9).
export const GET: APIRoute = async () => {
  const { data, pages } = await loadSeo();
  const list = [{ loc: abs('/sitemap-pages.xml'), lastmod: site.buildTime.toISOString() }];
  if (stateSitemapEntries(LOCALES[0].hreflang).length) list.push({ loc: abs('/sitemap-states.xml'), lastmod: site.buildTime.toISOString() });
  const towns = (await townSitemapEntries(LOCALES[0].hreflang)).length;
  for (let i = 1; i <= Math.ceil(towns / TOWN_SITEMAP_SIZE); i++) list.push({ loc: abs(`/sitemap-towns-${i}.xml`), lastmod: site.buildTime.toISOString() });
  if (pages.some((p) => p.status === 'indexable')) list.push({ loc: abs('/sitemap-prices.xml'), lastmod: data.generated_at });
  if ((await loadGuides()).some((g) => g.status === 'indexable')) list.push({ loc: abs('/sitemap-guides.xml'), lastmod: data.generated_at });
  if ((await loadSellers()).some((s) => s.status === 'indexable')) list.push({ loc: abs('/sitemap-sellers.xml'), lastmod: data.generated_at });
  return sitemapIndex(list);
};
