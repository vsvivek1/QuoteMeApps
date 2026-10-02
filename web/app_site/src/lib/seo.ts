/**
 * SEO city x category price pages (brief Sections 21.6 and 21.9).
 *
 * Data comes from ONE JSON file per country, written nightly by a scheduled
 * job from aggregated, anonymised quote data (medians only, never single
 * quotes, never buyer identities). Sources, in order:
 *   1. SEO_DATA_URL  (public JSON produced by the nightly export), else
 *   2. SEO_DATA_FILE (path relative to web/app_site), else
 *   3. data/seo/<country>.json (committed default; ships with NO page stats).
 *
 * Quality gates decide for every city x category row whether it is:
 *   - "skip"      : not built at all (no data, blocked/restricted category, merged town)
 *   - "noindex"   : built for visitors but <meta robots=noindex> and left out of sitemaps
 *   - "indexable" : built, indexable and listed in the sitemap
 */
import fs from 'node:fs';
import path from 'node:path';
import { country, warnOnce } from './site';

export interface SeoCategory {
  slug: string;
  name: string;
  group: string;
  kind: 'product' | 'service';
  /** Only categories whose policy is "allowed" get public price pages. */
  policy: 'allowed' | 'restricted' | 'blocked';
  unit?: string;
}

export interface SeoCity {
  slug: string;
  name: string;
  state: string;
  population?: number;
  /** Small neighbouring town merged into a larger area page (no page of its own). */
  merge_into?: string | null;
}

export interface SeoPageData {
  city: string;
  category: string;
  quotes_window: number;
  sellers_window: number;
  local_sellers?: number;
  last_quote_at: string;
  period: { from: string; to: string };
  price?: { median: number; p25: number; p75: number } | null;
  median_response_hours?: number | null;
  median_delivery_days?: number | null;
  trend_pct_vs_last_month?: number | null;
  top_models?: { name: string; quotes: number }[];
  manual_noindex?: boolean;
}

export interface SeoData {
  country: string;
  generated_at: string;
  /** Sample / fixture data: every page is forced to noindex and shows a banner. */
  fixture?: boolean;
  thresholds?: Partial<Thresholds>;
  categories: SeoCategory[];
  cities: SeoCity[];
  pages: SeoPageData[];
}

export interface Thresholds {
  min_quotes: number;
  min_sellers: number;
  window_days: number;
  stale_days: number;
}

export const DEFAULT_THRESHOLDS: Thresholds = { min_quotes: 10, min_sellers: 3, window_days: 90, stale_days: 90 };

export type PageStatus = 'indexable' | 'noindex' | 'skip';

export interface SeoPage {
  data: SeoPageData;
  city: SeoCity;
  category: SeoCategory;
  status: PageStatus;
  reasons: string[];
  /** Enough data to show median/range (same bar as indexability, ignoring staleness). */
  showPrices: boolean;
  mergedTowns: SeoCity[];
  path: string;
}

let cache: Promise<{ data: SeoData; pages: SeoPage[]; thresholds: Thresholds }> | null = null;

async function loadRaw(): Promise<SeoData> {
  const url = (process.env.SEO_DATA_URL ?? '').trim();
  if (url) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(20_000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return (await res.json()) as SeoData;
    } catch (err) {
      if (process.env.SEO_DATA_REQUIRED === '1') throw new Error(`SEO_DATA_URL fetch failed: ${err}`);
      warnOnce(`SEO_DATA_URL fetch failed (${err}); falling back to the local data file.`);
    }
  }
  const file = path.resolve(process.cwd(), (process.env.SEO_DATA_FILE ?? '').trim() || `data/seo/${country}.json`);
  return JSON.parse(fs.readFileSync(file, 'utf8')) as SeoData;
}

function validate(d: SeoData): void {
  if (d.country !== country) throw new Error(`SEO data is for "${d.country}" but SITE_COUNTRY is "${country}"`);
  for (const key of ['categories', 'cities', 'pages'] as const) {
    if (!Array.isArray(d[key])) throw new Error(`SEO data: "${key}" must be an array`);
  }
  if (Number.isNaN(Date.parse(d.generated_at))) throw new Error('SEO data: generated_at must be an ISO date');
  const slug = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
  for (const c of [...d.categories, ...d.cities]) {
    if (!slug.test(c.slug)) throw new Error(`SEO data: bad slug "${c.slug}"`);
  }
}

const DAY = 86_400_000;

function evaluate(p: SeoPageData, d: SeoData, t: Thresholds, cities: Map<string, SeoCity>, cats: Map<string, SeoCategory>) {
  const reasons: string[] = [];
  const city = cities.get(p.city);
  const category = cats.get(p.category);
  if (!city || !category) return { status: 'skip' as PageStatus, reasons: ['unknown city or category'], showPrices: false };
  if (category.policy !== 'allowed') return { status: 'skip' as PageStatus, reasons: [`category policy ${category.policy}`], showPrices: false };
  if (city.merge_into) return { status: 'skip' as PageStatus, reasons: [`merged into ${city.merge_into}`], showPrices: false };
  if (!p.quotes_window || p.quotes_window <= 0) return { status: 'skip' as PageStatus, reasons: ['no quotes'], showPrices: false };

  const enough = p.quotes_window >= t.min_quotes && p.sellers_window >= t.min_sellers;
  const hasPrice = Boolean(p.price && p.price.median > 0 && p.price.p25 > 0 && p.price.p75 >= p.price.p25);
  const showPrices = enough && hasPrice;
  if (!enough) reasons.push(`below threshold (${p.quotes_window} quotes / ${p.sellers_window} sellers; need ${t.min_quotes} / ${t.min_sellers})`);
  if (!hasPrice) reasons.push('no median price');
  const age = Date.parse(d.generated_at) - Date.parse(p.last_quote_at);
  if (Number.isNaN(age) || age > t.stale_days * DAY) reasons.push(`stale (no quotes in ${t.stale_days} days)`);
  if (p.manual_noindex) reasons.push('manually set to noindex');
  if (d.fixture) reasons.push('fixture data');
  return { status: (reasons.length ? 'noindex' : 'indexable') as PageStatus, reasons, showPrices };
}

export function loadSeo() {
  cache ??= (async () => {
    const data = await loadRaw();
    validate(data);
    const thresholds = { ...DEFAULT_THRESHOLDS, ...(data.thresholds ?? {}) };
    const cities = new Map(data.cities.map((c) => [c.slug, c]));
    const cats = new Map(data.categories.map((c) => [c.slug, c]));
    const seen = new Set<string>();
    const pages: SeoPage[] = [];
    for (const row of data.pages) {
      const key = `${row.city}/${row.category}`;
      if (seen.has(key)) throw new Error(`SEO data: duplicate page ${key}`);
      seen.add(key);
      const r = evaluate(row, data, thresholds, cities, cats);
      if (r.status === 'skip') continue;
      const city = cities.get(row.city)!;
      pages.push({
        data: row,
        city,
        category: cats.get(row.category)!,
        ...r,
        mergedTowns: data.cities.filter((c) => c.merge_into === city.slug),
        path: `/quotes/${city.slug}/${row.category}`,
      });
    }
    const counts = pages.reduce<Record<string, number>>((acc, p) => ((acc[p.status] = (acc[p.status] ?? 0) + 1), acc), {});
    const fixturePass = pages.filter((p) => p.reasons.length === 1 && p.reasons[0] === 'fixture data').length;
    console.log(
      `[app_site:${country}] SEO pages: ${counts.indexable ?? 0} indexable, ${counts.noindex ?? 0} noindex, ` +
        `${data.pages.length - pages.length} skipped (data ${data.fixture ? `FIXTURE, ${fixturePass} would pass gates` : 'live'}, ${data.generated_at})`,
    );
    return { data, pages, thresholds };
  })();
  return cache;
}

export interface CityHub {
  city: SeoCity;
  pages: SeoPage[];
  indexable: boolean;
}

export async function cityHubs(): Promise<CityHub[]> {
  const { pages } = await loadSeo();
  const by = new Map<string, CityHub>();
  for (const p of pages) {
    const hub = by.get(p.city.slug) ?? { city: p.city, pages: [], indexable: false };
    hub.pages.push(p);
    if (p.status === 'indexable') hub.indexable = true;
    by.set(p.city.slug, hub);
  }
  return [...by.values()].sort((a, b) => (b.city.population ?? 0) - (a.city.population ?? 0));
}

export function monthRange(from: string, to: string, locale: string): string {
  const f = new Intl.DateTimeFormat(locale, { month: 'long' });
  const fy = new Intl.DateTimeFormat(locale, { month: 'long', year: 'numeric' });
  const a = new Date(from);
  const b = new Date(to);
  return a.getUTCFullYear() === b.getUTCFullYear() ? `${f.format(a)} to ${fy.format(b)}` : `${fy.format(a)} to ${fy.format(b)}`;
}
