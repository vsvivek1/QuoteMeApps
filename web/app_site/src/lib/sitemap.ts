export interface UrlEntry {
  loc: string;
  lastmod?: string;
}

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const day = (d: string | Date) => new Date(d).toISOString().slice(0, 10);

export function urlset(entries: UrlEntry[]): Response {
  const body = entries
    .map((e) => `  <url><loc>${esc(e.loc)}</loc>${e.lastmod ? `<lastmod>${day(e.lastmod)}</lastmod>` : ''}</url>`)
    .join('\n');
  return xml(`<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</urlset>`);
}

export function sitemapIndex(locs: UrlEntry[]): Response {
  const body = locs
    .map((e) => `  <sitemap><loc>${esc(e.loc)}</loc>${e.lastmod ? `<lastmod>${day(e.lastmod)}</lastmod>` : ''}</sitemap>`)
    .join('\n');
  return xml(`<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</sitemapindex>`);
}

function xml(s: string): Response {
  return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n${s}\n`, {
    headers: { 'Content-Type': 'application/xml; charset=utf-8' },
  });
}
