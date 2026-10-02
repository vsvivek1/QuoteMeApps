import type { APIRoute } from 'astro';
import { loadArticles, placesIndex } from '../lib/articles';
import { abs } from '../lib/site';

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

// Lists only indexable articles and pages (Section 21.10 "Keeping the site clean").
export const GET: APIRoute = () => {
  const { built } = loadArticles();
  const live = built.filter((b) => b.indexable);
  const urls: { loc: string; lastmod?: string }[] = [
    { loc: abs('/') },
    ...['/about', '/editorial-policy', '/corrections-policy', '/ai-policy', '/contact'].map((p) => ({ loc: abs(p) })),
    ...(['india', 'usa'] as const).filter((c) => live.some((b) => b.article.country === c)).map((c) => ({ loc: abs(`/${c}`) })),
    ...placesIndex(live).map((p) => ({ loc: abs(`/place/${p.country}/${p.slug}`) })),
    ...live.map((b) => ({ loc: abs(`/a/${b.article.slug}`), lastmod: b.article.updated_at ?? b.article.published_at })),
  ];
  const body = urls.map((u) => `  <url><loc>${esc(u.loc)}</loc>${u.lastmod ? `<lastmod>${u.lastmod}</lastmod>` : ''}</url>`).join('\n');
  return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</urlset>\n`, {
    headers: { 'Content-Type': 'application/xml; charset=utf-8' },
  });
};
