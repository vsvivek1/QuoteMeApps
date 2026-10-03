import type { APIRoute, GetStaticPaths } from 'astro';
import { TOWN_SITEMAP_SIZE, urlset } from '../lib/sitemap';
import { LOCALES } from '../lib/i18n';
import { townSitemapEntries } from '../lib/town-sitemap';

// Town pages, split into files of TOWN_SITEMAP_SIZE URLs: sitemap-towns-1.xml, -2, ...
export const getStaticPaths = (async () => {
  const all = await townSitemapEntries(LOCALES[0].hreflang);
  const files = Math.max(1, Math.ceil(all.length / TOWN_SITEMAP_SIZE));
  return Array.from({ length: files }, (_, i) => ({ params: { n: String(i + 1) }, props: { entries: all.slice(i * TOWN_SITEMAP_SIZE, (i + 1) * TOWN_SITEMAP_SIZE) } }));
}) satisfies GetStaticPaths;

export const GET: APIRoute = ({ props }) => urlset(props.entries);
