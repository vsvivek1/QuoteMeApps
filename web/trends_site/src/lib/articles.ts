/**
 * Loads article JSON files and applies the publishing gates from brief Section 21.10.
 *
 * The upstream pipeline (trend detection, Claude drafting, second-pass fact and
 * balance checks) writes one JSON file per article into TRENDS_DATA_DIR and
 * records its check results. This build is the LAST line of defence: it re-checks
 * what it can locally and refuses to build anything that fails.
 *
 * Gate order:
 *   0 schema       required fields present and well-formed
 *   1 sources      >= min_sources independent publishers (distinct domains)
 *   2 sensitive    sensitive topics need a recorded human approval
 *   3 originality  upstream similarity check passed AND local n-gram overlap with
 *                  every source snippet <= max_similarity; no long quotes
 *   4 facts        upstream fact-consistency pass, no conflicting sources
 *   5 value        >= min_words of real content incl. local angle and what to watch
 *   5b balance     two neutral, similar-length perspectives; no partisan labels
 *   6 caps         kill switch, per-country daily cap (ramp level), max per hour
 * Articles failing 0-6 are NOT built. Built articles become noindex when
 * superseded, flagged, fixture data, or when traffic died after the trend ended.
 *
 * Sources: TRENDS_DATA_DIR (default data/articles) and, when TRENDS_DATA_URL is set, the
 * pipeline bucket downloaded by scripts/fetch-trends-data.mjs into .trends-remote/. Remote
 * articles go through exactly the same gates; the remote index may only tighten the kill
 * switch and the daily caps of data/config.json, never loosen them.
 */
import fs from 'node:fs';
import path from 'node:path';
import { site, warnOnce } from './site';

export type Country = 'usa' | 'india';

export interface Source {
  publisher: string;
  url: string;
  title?: string;
  snippet?: string;
}

export interface Article {
  id: string;
  slug: string;
  country: Country;
  places: { slug: string; name: string; state?: string; level: 'country' | 'state' | 'metro' }[];
  headline: string;
  summary: string[];
  perspectives: { framing: string; a: { label: string; body: string }; b: { label: string; body: string } };
  agree: string;
  local_angle: string;
  context?: string;
  watch_next: string;
  updates?: { at: string; text: string }[];
  corrections?: { at: string; text: string }[];
  sources: Source[];
  topic_tags: string[];
  sensitive?: boolean;
  review?: { approved_by?: string | null; approved_at?: string | null };
  checks: {
    originality?: { passed?: boolean; max_similarity?: number };
    fact_consistency?: { passed?: boolean; conflicts?: boolean; unsupported_claims_removed?: number };
    balance?: { passed?: boolean };
  };
  published_at: string;
  updated_at?: string;
  trend_ended_at?: string | null;
  traffic?: { visits_14d_after_end?: number | null };
  superseded_by?: string | null;
  noindex?: boolean;
  fixture?: boolean;
  app_link?: { label: string; url: string } | null;
  velocity?: number;
}

export interface Config {
  publishing: { paused: boolean; paused_at: string | null };
  caps: {
    per_day: Record<Country, number>;
    ramp_levels: number[];
    hard_max_per_day: number;
    max_per_hour: number;
    timezones: Record<Country, string>;
  };
  gates: {
    min_sources: number;
    max_similarity: number;
    shingle_words: number;
    max_quote_words: number;
    min_words: number;
    min_section_words: number;
    max_perspective_ratio: number;
    noindex_min_visits_14d: number;
  };
  sensitive_tags: string[];
  sensitive_keywords: string[];
  banned_perspective_terms: string[];
}

export interface Built {
  article: Article;
  indexable: boolean;
  noindexReasons: string[];
  canonical: string;
  appLink: { label: string; url: string } | null;
  words: number;
}

export interface GateResult {
  file: string;
  slug: string;
  gate: string;
  reason: string;
}

const words = (s = '') => (s.match(/[\p{L}\p{N}][\p{L}\p{N}'’-]*/gu) ?? []).length;
const tokens = (s = '') => (s.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? []);

function shingles(s: string, n: number): Set<string> {
  const t = tokens(s);
  const out = new Set<string>();
  for (let i = 0; i + n <= t.length; i++) out.add(t.slice(i, i + n).join(' '));
  return out;
}

/** Share of a source snippet's n-grams that reappear in the draft (containment). */
function containment(draft: Set<string>, snippet: string, n: number): number {
  const s = shingles(snippet, n);
  if (s.size === 0) return 0;
  let hit = 0;
  for (const g of s) if (draft.has(g)) hit++;
  return hit / s.size;
}

const hostOf = (u: string) => {
  try {
    return new URL(u).hostname.replace(/^www\./, '').toLowerCase();
  } catch {
    return '';
  }
};

function wordRe(list: string[]): RegExp | null {
  if (!list.length) return null;
  const esc = list.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+'));
  return new RegExp(`\\b(${esc.join('|')})\\b`, 'i');
}

function bodyText(a: Article): string {
  return [
    ...a.summary,
    a.perspectives.a.body,
    a.perspectives.b.body,
    a.agree,
    a.local_angle,
    a.context ?? '',
    a.watch_next,
    ...(a.updates ?? []).map((u) => u.text),
  ].join('\n');
}

function checkSchema(a: Article): string | null {
  const slug = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
  if (!a || typeof a !== 'object') return 'not an object';
  if (!slug.test(a.slug ?? '')) return 'bad or missing slug';
  if (a.country !== 'usa' && a.country !== 'india') return 'country must be usa or india';
  if (!a.headline?.trim()) return 'missing headline';
  if (!Array.isArray(a.summary) || a.summary.length < 1 || a.summary.length > 3) return 'summary must have 1 to 3 lines';
  if (!a.perspectives?.a?.body || !a.perspectives?.b?.body) return 'missing perspectives';
  if (!Array.isArray(a.places) || !a.places.length || a.places.some((p) => !slug.test(p.slug))) return 'missing or bad places';
  if (!Array.isArray(a.sources)) return 'missing sources';
  if (Number.isNaN(Date.parse(a.published_at))) return 'bad published_at';
  if (!a.checks) return 'missing checks';
  return null;
}

function contentGates(a: Article, c: Config): { gate: string; reason: string } | null {
  const g = c.gates;
  // 1. Independent sources
  const domains = new Set(a.sources.map((s) => hostOf(s.url)).filter(Boolean));
  if (domains.size < g.min_sources) return { gate: 'sources', reason: `${domains.size} independent source domain(s), need ${g.min_sources}` };

  // 2. Sensitive topics: never auto-publish; only with a recorded human approval
  const tagHit = a.topic_tags.find((t) => c.sensitive_tags.includes(t.toLowerCase()));
  const kw = wordRe(c.sensitive_keywords);
  const kwHit = kw?.exec(`${a.headline}\n${a.summary.join('\n')}`)?.[0];
  if (a.sensitive || tagHit || kwHit) {
    const approved = a.review?.approved_by && a.review?.approved_at && !Number.isNaN(Date.parse(a.review.approved_at));
    if (!approved) {
      return { gate: 'sensitive', reason: `sensitive (${a.sensitive ? 'flagged' : tagHit ? `tag "${tagHit}"` : `keyword "${kwHit}"`}) without human approval` };
    }
  }

  // 3. Originality
  const o = a.checks.originality;
  if (!o?.passed || typeof o.max_similarity !== 'number' || o.max_similarity > g.max_similarity) {
    return { gate: 'originality', reason: `upstream originality check missing or failed (${o?.max_similarity ?? 'n/a'})` };
  }
  const text = bodyText(a);
  const draft = shingles(text, g.shingle_words);
  for (const s of a.sources) {
    const sim = containment(draft, `${s.title ?? ''} ${s.snippet ?? ''}`, g.shingle_words);
    if (sim > g.max_similarity) return { gate: 'originality', reason: `${Math.round(sim * 100)}% overlap with ${hostOf(s.url)}` };
  }
  const quotes = text.match(/[“"]([^”"]+)[”"]/g) ?? [];
  const long = quotes.find((q) => words(q) > g.max_quote_words);
  if (long) return { gate: 'originality', reason: `quote longer than ${g.max_quote_words} words` };

  // 4. Fact consistency (second model pass upstream)
  const f = a.checks.fact_consistency;
  if (!f?.passed || f.conflicts) return { gate: 'facts', reason: f?.conflicts ? 'sources conflict on key facts' : 'fact-consistency check missing or failed' };

  // 5. Value: real content, local angle, what to watch
  const total = words(bodyText(a));
  if (total < g.min_words) return { gate: 'value', reason: `${total} words, need ${g.min_words}` };
  for (const [name, val] of [['local_angle', a.local_angle], ['watch_next', a.watch_next], ['agree', a.agree]] as const) {
    if (words(val) < g.min_section_words) return { gate: 'value', reason: `section "${name}" too short` };
  }

  // 5b. Balance: neutral labels, similar length, upstream balance pass
  const { a: pa, b: pb } = a.perspectives;
  const banned = wordRe(c.banned_perspective_terms);
  const label = `${a.perspectives.framing} ${pa.label} ${pb.label}`;
  if (banned?.test(label)) return { gate: 'balance', reason: `partisan or ideological perspective label ("${banned.exec(label)?.[0]}")` };
  if (pa.label.trim().toLowerCase() === pb.label.trim().toLowerCase()) return { gate: 'balance', reason: 'perspective labels are identical' };
  const wa = words(pa.body);
  const wb = words(pb.body);
  if (Math.max(wa, wb) / Math.max(1, Math.min(wa, wb)) > g.max_perspective_ratio) return { gate: 'balance', reason: `perspectives unbalanced (${wa} vs ${wb} words)` };
  if (!a.checks.balance?.passed) return { gate: 'balance', reason: 'balance check missing or failed' };
  return null;
}

function validateConfig(c: Config): void {
  for (const country of ['usa', 'india'] as const) {
    const cap = c.caps.per_day[country];
    if (!c.caps.ramp_levels.includes(cap)) throw new Error(`config: caps.per_day.${country}=${cap} is not a ramp level ${c.caps.ramp_levels}`);
    if (cap > c.caps.hard_max_per_day) throw new Error(`config: caps.per_day.${country} exceeds hard_max_per_day`);
  }
  if (c.publishing.paused && Number.isNaN(Date.parse(c.publishing.paused_at ?? ''))) {
    throw new Error('config: publishing.paused=true needs publishing.paused_at (ISO date)');
  }
}

const localDay = (iso: string, tz: string) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(iso));

let cache: { built: Built[]; rejected: GateResult[]; config: Config } | null = null;

/** Article sources: local files first (they win on duplicate slugs), then the remote bucket copy. */
function articleFiles(): { file: string; full: string }[] {
  const list = (dir: string, prefix: string) =>
    fs.existsSync(dir)
      ? fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort().map((f) => ({ file: `${prefix}${f}`, full: path.join(dir, f) }))
      : [];
  const out = list(site.dataDir, '');
  if (site.remoteDataUrl) {
    const dir = path.join(site.remoteDir, 'articles');
    if (!fs.existsSync(path.join(site.remoteDir, 'settings.json'))) {
      throw new Error('TRENDS_DATA_URL is set but .trends-remote/ is missing: build with `npm run build` (its prebuild step downloads the data)');
    }
    out.push(...list(dir, 'remote:'));
  }
  return out;
}

/** The remote index can pause publishing or lower a daily cap (to another ramp level), never the reverse. */
function applyRemoteSettings(config: Config): void {
  if (!site.remoteDataUrl) return;
  const f = path.join(site.remoteDir, 'settings.json');
  if (!fs.existsSync(f)) return;
  const r = JSON.parse(fs.readFileSync(f, 'utf8')) as { paused?: boolean; paused_at?: string | null; per_day?: Partial<Record<Country, number | null>> };
  if (r.paused === true) {
    const at = r.paused_at && !Number.isNaN(Date.parse(r.paused_at)) ? r.paused_at : site.now.toISOString();
    const localAt = config.publishing.paused ? Date.parse(config.publishing.paused_at ?? '') : Infinity;
    if (!(Date.parse(at) >= localAt)) config.publishing = { paused: true, paused_at: at };
    console.log(`[trends_site] remote kill switch: publishing paused at ${config.publishing.paused_at}`);
  }
  for (const country of ['usa', 'india'] as const) {
    const n = r.per_day?.[country];
    if (typeof n === 'number' && config.caps.ramp_levels.includes(n) && n < config.caps.per_day[country]) {
      console.log(`[trends_site] remote ramp: ${country} daily cap ${config.caps.per_day[country]} -> ${n}`);
      config.caps.per_day[country] = n;
    }
  }
}

export function loadArticles() {
  if (cache) return cache;
  const config = JSON.parse(fs.readFileSync(site.configFile, 'utf8')) as Config;
  applyRemoteSettings(config);
  validateConfig(config);
  const rejected: GateResult[] = [];
  const passed: { file: string; a: Article }[] = [];
  const files = articleFiles();
  const slugs = new Set<string>();

  for (const { file, full } of files) {
    let a: Article;
    try {
      a = JSON.parse(fs.readFileSync(full, 'utf8'));
    } catch (e) {
      rejected.push({ file, slug: '?', gate: 'schema', reason: `invalid JSON: ${e}` });
      continue;
    }
    const schemaErr = checkSchema(a);
    if (schemaErr) {
      rejected.push({ file, slug: a?.slug ?? '?', gate: 'schema', reason: schemaErr });
      continue;
    }
    if (slugs.has(a.slug)) {
      rejected.push({ file, slug: a.slug, gate: 'schema', reason: 'duplicate slug' });
      continue;
    }
    slugs.add(a.slug);
    const fail = contentGates(a, config);
    if (fail) {
      rejected.push({ file, slug: a.slug, ...fail });
      continue;
    }
    passed.push({ file, a });
  }

  // 6. Kill switch and rate caps (per country, per local day, per rolling hour), oldest first.
  passed.sort((x, y) => Date.parse(x.a.published_at) - Date.parse(y.a.published_at));
  const kept: Article[] = [];
  const perDay = new Map<string, number>();
  const pausedAt = config.publishing.paused ? Date.parse(config.publishing.paused_at!) : Infinity;
  for (const { file, a } of passed) {
    const t = Date.parse(a.published_at);
    if (t >= pausedAt) {
      rejected.push({ file, slug: a.slug, gate: 'caps', reason: 'publishing paused (kill switch)' });
      continue;
    }
    if (t > site.now.getTime() + 5 * 60_000) {
      rejected.push({ file, slug: a.slug, gate: 'caps', reason: 'published_at is in the future' });
      continue;
    }
    const key = `${a.country}:${localDay(a.published_at, config.caps.timezones[a.country])}`;
    if ((perDay.get(key) ?? 0) >= config.caps.per_day[a.country]) {
      rejected.push({ file, slug: a.slug, gate: 'caps', reason: `daily cap ${config.caps.per_day[a.country]} reached for ${key}` });
      continue;
    }
    const lastHour = kept.filter((k) => k.country === a.country && t - Date.parse(k.published_at) < 3_600_000 && t >= Date.parse(k.published_at));
    if (lastHour.length >= config.caps.max_per_hour) {
      rejected.push({ file, slug: a.slug, gate: 'caps', reason: `more than ${config.caps.max_per_hour} in one hour` });
      continue;
    }
    perDay.set(key, (perDay.get(key) ?? 0) + 1);
    kept.push(a);
  }

  const keptSlugs = new Set(kept.map((a) => a.slug));
  const built: Built[] = kept.map((a) => {
    const reasons: string[] = [];
    let canonical = `/a/${a.slug}`;
    if (a.fixture) reasons.push('fixture');
    if (a.noindex) reasons.push('manual');
    if (a.superseded_by) {
      reasons.push(`superseded by ${a.superseded_by}`);
      if (keptSlugs.has(a.superseded_by)) canonical = `/a/${a.superseded_by}`;
    }
    const ended = a.trend_ended_at ? Date.parse(a.trend_ended_at) : NaN;
    const visits = a.traffic?.visits_14d_after_end;
    if (!Number.isNaN(ended) && site.now.getTime() - ended >= 14 * 86_400_000 && typeof visits === 'number' && visits < config.gates.noindex_min_visits_14d) {
      reasons.push(`traffic died (${visits} visits in 14 days after the trend)`);
    }
    let appLink: Built['appLink'] = null;
    if (a.app_link?.url) {
      try {
        const u = new URL(a.app_link.url);
        if (u.protocol === 'https:' && site.appLinkHosts.includes(u.hostname)) {
          u.searchParams.set('utm_source', 'trends');
          u.searchParams.set('utm_medium', 'article');
          u.searchParams.set('utm_campaign', a.slug);
          appLink = { label: a.app_link.label, url: u.toString() };
        } else warnOnce(`${a.slug}: app_link host ${u.hostname} not in APP_LINK_HOSTS; link dropped`);
      } catch {
        warnOnce(`${a.slug}: invalid app_link URL; link dropped`);
      }
    }
    return { article: a, indexable: reasons.length === 0, noindexReasons: reasons, canonical, appLink, words: words(bodyText(a)) };
  });
  built.sort((x, y) => Date.parse(y.article.published_at) - Date.parse(x.article.published_at));

  console.log(`[trends_site] ${files.length} article file(s): ${built.length} built (${built.filter((b) => b.indexable).length} indexable), ${rejected.length} not built`);
  for (const r of rejected) console.log(`[trends_site]   not built: ${r.file} [${r.gate}] ${r.reason}`);
  for (const b of built.filter((x) => !x.indexable)) console.log(`[trends_site]   noindex: ${b.article.slug} (${b.noindexReasons.join(', ')})`);

  cache = { built, rejected, config };
  return cache;
}

export function placesIndex(built: Built[]) {
  const map = new Map<string, { country: Country; slug: string; name: string; state?: string; items: Built[] }>();
  for (const b of built) {
    for (const p of b.article.places) {
      const key = `${b.article.country}/${p.slug}`;
      const e = map.get(key) ?? { country: b.article.country, slug: p.slug, name: p.name, state: p.state, items: [] };
      e.items.push(b);
      map.set(key, e);
    }
  }
  return [...map.values()];
}
