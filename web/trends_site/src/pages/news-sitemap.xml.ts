import type { APIRoute } from 'astro';
import { loadArticles } from '../lib/articles';
import { abs, site } from '../lib/site';

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Google News sitemap: only enable (NEWS_SITEMAP=1) once the site qualifies.
// Lists indexable articles from the last 48 hours, as Google requires.
export const GET: APIRoute = () => {
  const { built } = loadArticles();
  const cutoff = site.now.getTime() - 48 * 3_600_000;
  const items = site.newsSitemap
    ? built.filter((b) => b.indexable && Date.parse(b.article.published_at) >= cutoff)
    : [];
  const body = items
    .map(
      (b) =>
        `  <url><loc>${esc(abs(`/a/${b.article.slug}`))}</loc><news:news><news:publication><news:name>${esc(site.name)}</news:name><news:language>en</news:language></news:publication><news:publication_date>${b.article.published_at}</news:publication_date><news:title>${esc(b.article.headline)}</news:title></news:news></url>`,
    )
    .join('\n');
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:news="http://www.google.com/schemas/sitemap-news/0.9">\n${body}\n</urlset>\n`,
    { headers: { 'Content-Type': 'application/xml; charset=utf-8' } },
  );
};
