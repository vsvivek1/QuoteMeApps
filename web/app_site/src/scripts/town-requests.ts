// "Recent requests" on town pages (components/pages/TownPage.astro). The section is in the
// HTML only when the site is built with REQUESTS_FEED_URL, and stays hidden until the feed
// for this town returns at least one item. Feed (public JSON, written by the backend; the
// CSP allows it only from this site or *.supabase.co):
//   { "items": [{ "title": "Split AC service, 2 units", "category": "AC repair", "area": "Kakkanad", "created_at": "2026-10-01T10:00:00Z" }] }
// Text is only ever set with textContent. Any error leaves the section hidden.

interface FeedItem {
  title?: unknown;
  category?: unknown;
  area?: unknown;
  created_at?: unknown;
}

const str = (v: unknown, max: number) => (typeof v === 'string' ? v.replace(/\s+/g, ' ').trim().slice(0, max) : '');

async function load(section: HTMLElement): Promise<void> {
  const url = section.dataset.requestsFeed;
  const list = section.querySelector<HTMLUListElement>('[data-requests-list]');
  if (!url || !list) return;
  const res = await fetch(url, { credentials: 'omit', headers: { Accept: 'application/json' } });
  if (!res.ok) return;
  const body = (await res.json()) as { items?: FeedItem[] };
  const lang = document.documentElement.lang || undefined;
  const fmt = new Intl.DateTimeFormat(lang, { day: 'numeric', month: 'short' });
  const items = (Array.isArray(body.items) ? body.items : []).slice(0, 6).filter((i) => str(i.title, 140));
  if (!items.length) return;
  for (const i of items) {
    const li = document.createElement('li');
    li.className = 'bubble';
    const p = document.createElement('p');
    p.textContent = str(i.title, 140);
    li.append(p);
    const at = typeof i.created_at === 'string' ? new Date(i.created_at) : null;
    const meta = [str(i.category, 60), str(i.area, 60), at && !Number.isNaN(at.getTime()) ? fmt.format(at) : ''].filter(Boolean);
    if (meta.length) {
      const small = document.createElement('small');
      small.textContent = meta.join(' · ');
      li.append(small);
    }
    list.append(li);
  }
  section.hidden = false;
}

for (const section of document.querySelectorAll<HTMLElement>('[data-requests-feed]')) {
  load(section).catch(() => {
    // Feed missing or invalid: the section stays hidden.
  });
}
