import type { APIRoute } from 'astro';
import { abs } from '../lib/site';
import { legalPages } from '../lib/legal';
import { urlset } from '../lib/sitemap';
import { LOCALES, TRANSLATED, alternates, localePath } from '../lib/i18n';

export const GET: APIRoute = async () => {
  const fixed = ['/', '/sellers', '/waitlist', '/contact', '/about', '/editorial-policy', '/quotes', '/in', '/legal', '/legal/open-source'];
  const legal = (await legalPages()).map((p) => ({ loc: abs(`/legal/${p.data.slug}`), lastmod: p.data.last_updated.toISOString() }));
  // Every language version of a translated page lists all versions (hreflang), including itself.
  const withAlts = (p: string) => {
    const alts = alternates(p).map((a) => ({ hreflang: a.hreflang, href: abs(a.path) }));
    return { loc: abs(p), ...(alts.length ? { alternates: alts } : {}) };
  };
  const translated = LOCALES.slice(1).flatMap((l) => TRANSLATED.map((p) => localePath(l, p)));
  return urlset([...fixed.map(withAlts), ...translated.map(withAlts), ...legal]);
};
