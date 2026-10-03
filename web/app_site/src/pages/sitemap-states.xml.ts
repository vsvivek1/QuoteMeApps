import type { APIRoute } from 'astro';
import { urlset } from '../lib/sitemap';
import { LOCALES } from '../lib/i18n';
import { stateSitemapEntries } from '../lib/town-sitemap';

// State pages (/<state> and its language version).
export const GET: APIRoute = () => urlset(stateSitemapEntries(LOCALES[0].hreflang));
