// Community feed page (pages/community.astro). Reads the public projection of requests the
// buyers chose to share (no buyer id, contact details, exact location or hidden budget)
// through anon-executable RPCs; the CSP allows fetches to *.supabase.co only. Text is only
// ever set with textContent. Errors leave a short message in the status line.

interface Tier {
  min_qty?: unknown;
  unit_price_minor?: unknown;
}
interface Group {
  unit?: unknown;
  total_qty?: unknown;
  members?: unknown;
  ladder?: Tier[];
  current_unit_price_minor?: unknown;
  next_min_qty?: unknown;
  next_unit_price_minor?: unknown;
  qty_to_next?: unknown;
}
interface Post {
  request_id?: unknown;
  title?: unknown;
  description?: unknown;
  author_name?: unknown;
  locality?: unknown;
  city?: unknown;
  status?: unknown;
  published_at?: unknown;
  budget_min_minor?: unknown;
  budget_max_minor?: unknown;
  comment_count?: unknown;
  like_count?: unknown;
  quote_count?: unknown;
  category_names?: unknown;
  group_buy?: unknown;
  group?: Group | null;
}
interface Comment {
  parent_id?: unknown;
  body?: unknown;
  author_name?: unknown;
  as_seller?: unknown;
  is_post_author?: unknown;
  created_at?: unknown;
}

const str = (v: unknown, max = 400) => (typeof v === 'string' ? v.replace(/\s+/g, ' ').trim().slice(0, max) : '');
const num = (v: unknown) => (typeof v === 'number' ? v : typeof v === 'string' && v.trim() !== '' ? Number(v) : NaN);
const qty = (v: unknown) => {
  const n = num(v);
  return Number.isFinite(n) ? String(Math.round(n * 1000) / 1000) : '0';
};
const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;
const uuid = /^[0-9a-f-]{36}$/i;

function setup(root: HTMLElement): void {
  const base = root.dataset.supabaseUrl ?? '';
  const key = root.dataset.anonKey ?? '';
  const locale = root.dataset.locale || undefined;
  const lang = (document.documentElement.lang || 'en').split('-')[0];
  const currency = root.dataset.currency || 'USD';
  const money = new Intl.NumberFormat(locale, { style: 'currency', currency });
  const whole = new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 0 });
  const date = new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short' });
  const price = (minor: unknown) => {
    const n = num(minor);
    if (!Number.isFinite(n)) return '';
    return (n % 100 === 0 ? whole : money).format(n / 100);
  };
  const feed = root.querySelector<HTMLOListElement>('[data-feed]')!;
  const status = root.querySelector<HTMLElement>('[data-status]')!;
  const more = root.querySelector<HTMLButtonElement>('[data-more]')!;
  const tpl = root.querySelector<HTMLTemplateElement>('[data-post-template]')!;
  let filter = 'all';
  let cursor: { published_at: string; id: string } | null = null;

  async function rpc<T>(fn: string, body: object): Promise<T> {
    const res = await fetch(`${base}/rest/v1/rpc/${fn}`, {
      method: 'POST',
      credentials: 'omit',
      headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`${fn}: ${res.status}`);
    return (await res.json()) as T;
  }

  function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = '', cls = ''): HTMLElementTagNameMap[K] {
    const e = document.createElement(tag);
    if (text) e.textContent = text;
    if (cls) e.className = cls;
    return e;
  }

  function renderGroup(node: HTMLElement, g: Group): void {
    const box = node.querySelector<HTMLElement>('[data-group]')!;
    const unit = str(g.unit, 24) || 'units';
    const members = num(g.members) || 0;
    box.hidden = false;
    node.querySelector('[data-group-tag]')!.removeAttribute('hidden');
    node.querySelector('[data-group-summary]')!.textContent = `${plural(members, 'person', 'people')} · ${qty(g.total_qty)} ${unit}`;
    const now = price(g.current_unit_price_minor);
    node.querySelector('[data-group-price]')!.textContent = now ? `${now} each` : '';
    const next = node.querySelector<HTMLElement>('[data-group-next]')!;
    const nextQty = num(g.next_min_qty);
    if (Number.isFinite(nextQty) && nextQty > 0) {
      const meter = node.querySelector<HTMLElement>('[data-meter]')!;
      meter.hidden = false;
      const pct = Math.max(0, Math.min(100, ((num(g.total_qty) || 0) / nextQty) * 100));
      node.querySelector<HTMLElement>('[data-meter-fill]')!.style.width = `${pct}%`;
      next.textContent = `${qty(g.qty_to_next)} more ${unit} unlocks ${price(g.next_unit_price_minor)} each`;
    } else {
      next.textContent = now ? '' : "Waiting for sellers' bulk offers";
    }
    const ladder = node.querySelector<HTMLOListElement>('[data-ladder]')!;
    const total = num(g.total_qty) || 0;
    const tiers = Array.isArray(g.ladder) ? g.ladder.slice(0, 8) : [];
    tiers.forEach((t, i) => {
      const li = el('li');
      const from = num(t.min_qty);
      const upTo = i + 1 < tiers.length ? num(tiers[i + 1].min_qty) : Infinity;
      if (total >= from && total < upTo) li.className = 'current';
      li.append(el('span', `${qty(t.min_qty)}+ ${unit}`), el('strong', `${price(t.unit_price_minor)} each`));
      ladder.append(li);
    });
  }

  async function loadComments(node: HTMLElement, id: string, button: HTMLButtonElement): Promise<void> {
    const list = node.querySelector<HTMLOListElement>('[data-comments]')!;
    if (!list.hidden) {
      list.hidden = true;
      button.textContent = 'Show comments';
      return;
    }
    button.disabled = true;
    try {
      const rows = await rpc<Comment[]>('get_feed_comments', { p_request_id: id, p_limit: 100 });
      list.replaceChildren();
      if (!rows.length) list.append(el('li', 'No comments yet. Start the conversation in the app.', 'muted'));
      for (const c of rows) {
        const li = el('li', '', c.parent_id ? 'reply' : '');
        const who = el('strong', str(c.author_name, 80));
        const tags = [c.as_seller === true ? 'Business' : '', c.is_post_author === true ? 'Author' : ''].filter(Boolean);
        const at = typeof c.created_at === 'string' ? new Date(c.created_at) : null;
        const meta = el('span', [...tags, at && !Number.isNaN(at.getTime()) ? date.format(at) : ''].filter(Boolean).join(' · '), 'muted small');
        li.append(who, ' ', meta, el('p', str(c.body, 1000)));
        list.append(li);
      }
      list.hidden = false;
      button.textContent = 'Hide comments';
    } catch {
      button.textContent = 'Comments are not available right now';
    } finally {
      button.disabled = false;
    }
  }

  function render(p: Post): HTMLElement | null {
    const id = str(p.request_id, 40);
    if (!uuid.test(id)) return null;
    const node = tpl.content.firstElementChild!.cloneNode(true) as HTMLElement;
    const names = (p.category_names ?? {}) as Record<string, unknown>;
    const category = str(names[lang], 60) || str(names.en, 60);
    const at = typeof p.published_at === 'string' ? new Date(p.published_at) : null;
    const place = [...new Set([str(p.locality, 60), str(p.city, 60)].filter(Boolean))].join(', ');
    node.querySelector('[data-author]')!.textContent = str(p.author_name, 80);
    node.querySelector('[data-meta]')!.textContent = [category, place, at && !Number.isNaN(at.getTime()) ? date.format(at) : '']
      .filter(Boolean)
      .map((s) => ` · ${s}`)
      .join('');
    node.querySelector('[data-title]')!.textContent = str(p.title, 140);
    const desc = str(p.description, 600);
    const descEl = node.querySelector<HTMLElement>('[data-desc]')!;
    if (desc && desc !== str(p.title, 140)) descEl.textContent = desc;
    else descEl.remove();
    const lo = price(p.budget_min_minor);
    const hi = price(p.budget_max_minor);
    if (lo || hi) {
      const b = node.querySelector<HTMLElement>('[data-budget]')!;
      b.hidden = false;
      b.textContent = `Budget: ${lo && hi ? `${lo} to ${hi}` : lo || `up to ${hi}`}`;
    }
    if (p.group_buy === true && p.group) renderGroup(node, p.group);
    const status = str(p.status, 20);
    node.querySelector('[data-stats]')!.textContent = [
      plural(num(p.like_count) || 0, 'like', 'likes'),
      plural(num(p.comment_count) || 0, 'comment', 'comments'),
      plural(num(p.quote_count) || 0, 'quote', 'quotes'),
      status && status !== 'open' ? (status === 'awarded' ? 'Seller chosen' : 'Closed') : '',
    ]
      .filter(Boolean)
      .join(' · ');
    const open = node.querySelector<HTMLAnchorElement>('[data-open]')!;
    open.href = `/r/${id}`;
    const show = node.querySelector<HTMLButtonElement>('[data-show-comments]')!;
    show.addEventListener('click', () => void loadComments(node, id, show));
    return node;
  }

  async function load(reset: boolean): Promise<void> {
    if (reset) {
      cursor = null;
      feed.replaceChildren();
    }
    status.textContent = 'Loading posts…';
    more.hidden = true;
    const filters = filter === 'group' ? { group_buy_only: true } : filter === 'open' ? { open_only: true } : {};
    try {
      const rows = await rpc<Post[]>('get_community_feed', { p_filters: filters, p_cursor: cursor, p_limit: 20 });
      for (const p of rows) {
        const node = render(p);
        if (node) feed.append(node);
      }
      const last = rows.at(-1);
      cursor = last && typeof last.published_at === 'string' ? { published_at: last.published_at, id: str(last.request_id, 40) } : null;
      more.hidden = rows.length < 20;
      status.textContent = feed.children.length ? '' : 'Nothing here yet. Post what you need in the app and share it with your neighbours.';
    } catch {
      status.textContent = 'The feed is not available right now. Please try again later.';
    }
  }

  for (const b of root.querySelectorAll<HTMLButtonElement>('[data-filter]')) {
    b.addEventListener('click', () => {
      filter = b.dataset.filter ?? 'all';
      for (const o of root.querySelectorAll<HTMLButtonElement>('[data-filter]')) o.setAttribute('aria-pressed', String(o === b));
      void load(true);
    });
  }
  more.addEventListener('click', () => void load(false));
  void load(true);
}

for (const root of document.querySelectorAll<HTMLElement>('[data-community]')) setup(root);
