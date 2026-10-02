/**
 * Minimal, safe Markdown -> HTML for reviewed buying guides (no dependency).
 * Supported: headings (# is demoted to h2: the page owns the h1), paragraphs,
 * - / * / 1. lists, > quotes, **bold**, *italic*, `code`, [links](url).
 * Raw HTML is always escaped; links are limited to https, http, mailto and
 * site-relative paths, and external links get rel="nofollow noopener".
 */
const esc = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');

function safeHref(url: string): string | null {
  const u = url.trim();
  if (/^\/(?!\/)/.test(u) || /^#[\w-]*$/.test(u)) return u;
  if (/^(https?:\/\/|mailto:)[^\s]+$/i.test(u)) return u;
  return null;
}

export function inline(text: string): string {
  // Code spans first (their content is not formatted further).
  const parts = text.split(/(`[^`]+`)/g);
  return parts
    .map((part) => {
      if (/^`[^`]+`$/.test(part)) return `<code>${esc(part.slice(1, -1))}</code>`;
      let s = esc(part);
      s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_m, label: string, href: string) => {
        const h = safeHref(href.replace(/&amp;/g, '&'));
        if (!h) return label;
        const external = /^(https?:)?\/\//i.test(h);
        return `<a href="${esc(h)}"${external ? ' rel="nofollow noopener"' : ''}>${label}</a>`;
      });
      s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
      s = s.replace(/(^|[^*])\*([^*\s][^*]*)\*/g, '$1<em>$2</em>');
      return s;
    })
    .join('');
}

export function renderMarkdown(md: string): string {
  const lines = md.replace(/\r\n?/g, '\n').split('\n');
  const out: string[] = [];
  let para: string[] = [];
  let list: { tag: 'ul' | 'ol'; items: string[] } | null = null;
  let quote: string[] = [];

  const flushPara = () => {
    if (para.length) out.push(`<p>${inline(para.join(' '))}</p>`);
    para = [];
  };
  const flushList = () => {
    if (list) out.push(`<${list.tag}>${list.items.map((i) => `<li>${inline(i)}</li>`).join('')}</${list.tag}>`);
    list = null;
  };
  const flushQuote = () => {
    if (quote.length) out.push(`<blockquote><p>${inline(quote.join(' '))}</p></blockquote>`);
    quote = [];
  };
  const flushAll = () => {
    flushPara();
    flushList();
    flushQuote();
  };

  for (const raw of lines) {
    const line = raw.trimEnd();
    if (!line.trim()) {
      flushAll();
      continue;
    }
    const h = /^(#{1,4})\s+(.+)$/.exec(line);
    if (h) {
      flushAll();
      const level = Math.min(Math.max(h[1].length, 2), 4);
      out.push(`<h${level}>${inline(h[2].trim())}</h${level}>`);
      continue;
    }
    const ul = /^\s*[-*]\s+(.+)$/.exec(line);
    const ol = /^\s*\d+[.)]\s+(.+)$/.exec(line);
    if (ul || ol) {
      flushPara();
      flushQuote();
      const tag = ul ? 'ul' : 'ol';
      if (!list || list.tag !== tag) {
        flushList();
        list = { tag, items: [] };
      }
      list.items.push((ul ?? ol)![1]);
      continue;
    }
    const q = /^>\s?(.*)$/.exec(line);
    if (q) {
      flushPara();
      flushList();
      quote.push(q[1]);
      continue;
    }
    flushList();
    flushQuote();
    para.push(line.trim());
  }
  flushAll();
  return out.join('\n');
}

/** Plain-text word count (for Article schema). */
export function wordCount(md: string): number {
  return md.replace(/[#*>`[\]()_-]/g, ' ').split(/\s+/).filter(Boolean).length;
}
