/**
 * SEO city x category price pages (brief Sections 21.6 and 21.9).
 *
 * Data comes from ONE JSON file per country, written nightly by a scheduled
 * job from aggregated, anonymised quote data (medians only, never single
 * quotes, never buyer identities). Sources, in order:
 *   1. SEO_DATA_URL  (public JSON produced by the nightly export: the
 *      Supabase `seo-export` Edge Function uploads it to
 *      https://<ref>.supabase.co/storage/v1/object/public/public-data/seo/<country>.json), else
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

/** Buying guide (Section 21.9): only approved (noindex) or published (indexable) guides are exported. */
export interface SeoGuideData {
  slug: string;
  title: string;
  description?: string;
  /** Area city slug (after the small-town merge), if the guide is about one city. */
  city?: string | null;
  city_name?: string | null;
  category: string;
  status: 'approved' | 'published';
  ai_assisted?: boolean;
  body_md: string;
  reviewed_at: string;
  published_at?: string | null;
  updated_at?: string;
}

/** Seller directory entry: only sellers who opted in; never contact details or quotes. */
export interface SeoSellerData {
  slug: string;
  name: string;
  description?: string;
  city?: string | null;
  city_name?: string | null;
  categories: string[];
  verified?: boolean;
  years_in_business?: number;
  rating?: number;
  rating_count?: number;
  median_response_hours?: number;
}

export interface SeoData {
  country: string;
  generated_at: string;
  /** "supabase:seo_export" for the nightly export. */
  source?: string;
  /** Sample / fixture data: every page is forced to noindex and shows a banner. */
  fixture?: boolean;
  thresholds?: Partial<Thresholds>;
  categories: SeoCategory[];
  cities: SeoCity[];
  pages: SeoPageData[];
  guides?: SeoGuideData[];
  sellers?: SeoSellerData[];
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

/**
 * Adds a cache-busting query parameter to plain public URLs (e.g. the Supabase
 * Storage public object URL, which sits behind a CDN) so a rebuild triggered
 * right after the nightly upload never reads yesterday's copy. URLs that
 * already carry a query string (signed URLs) are left alone.
 */
export function seoDataFetchUrl(url: string, now = Date.now()): string {
  return url.includes('?') ? url : `${url}?v=${Math.floor(now / 60_000)}`;
}

async function loadRaw(): Promise<SeoData> {
  const url = (process.env.SEO_DATA_URL ?? '').trim();
  if (url) {
    try {
      const res = await fetch(seoDataFetchUrl(url), {
        signal: AbortSignal.timeout(20_000),
        headers: { Accept: 'application/json' },
        cache: 'no-store',
      });
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
  for (const key of ['guides', 'sellers'] as const) {
    if (d[key] != null && !Array.isArray(d[key])) throw new Error(`SEO data: "${key}" must be an array when present`);
  }
  if (Number.isNaN(Date.parse(d.generated_at))) throw new Error('SEO data: generated_at must be an ISO date');
  const slug = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
  for (const c of [...d.categories, ...d.cities, ...(d.guides ?? [])]) {
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

/** Guides must be re-reviewed at least twice a year (Section 21.9) to stay indexable. */
export const GUIDE_REVIEW_MAX_DAYS = 184;

export interface SeoGuide {
  data: SeoGuideData;
  category: SeoCategory;
  /** Area city (after the merge), when the guide is about one city and the city is in the data. */
  city: SeoCity | null;
  status: 'indexable' | 'noindex';
  reasons: string[];
  /** Price page for the same city x category with prices shown, if any. */
  pricePage: SeoPage | null;
  /** Other price pages for the category with prices shown (for city-less guides). */
  categoryPages: SeoPage[];
  path: string;
}

let guideCache: Promise<SeoGuide[]> | null = null;

/**
 * Guide pages: every exported guide is built; it is indexable only when
 * published, reviewed within GUIDE_REVIEW_MAX_DAYS and not fixture data.
 * Approved-but-unpublished guides are built with noindex (preview link for
 * reviewers) and are not listed anywhere.
 */
export function loadGuides(): Promise<SeoGuide[]> {
  guideCache ??= (async () => {
    const { data, pages } = await loadSeo();
    const cats = new Map(data.categories.map((c) => [c.slug, c]));
    const cities = new Map(data.cities.map((c) => [c.slug, c]));
    const seen = new Set<string>();
    const out: SeoGuide[] = [];
    for (const g of data.guides ?? []) {
      if (seen.has(g.slug)) throw new Error(`SEO data: duplicate guide ${g.slug}`);
      seen.add(g.slug);
      const category = cats.get(g.category);
      if (!category || category.policy === 'blocked' || (g.status !== 'approved' && g.status !== 'published')) {
        console.log(`[app_site:${country}] guide ${g.slug} skipped (${!category ? 'unknown category' : `status ${g.status} / policy ${category.policy}`})`);
        continue;
      }
      const reasons: string[] = [];
      if (g.status !== 'published') reasons.push('not published');
      const reviewedAge = Date.parse(data.generated_at) - Date.parse(g.reviewed_at);
      if (Number.isNaN(reviewedAge)) reasons.push('no review date');
      else if (reviewedAge > GUIDE_REVIEW_MAX_DAYS * DAY) reasons.push(`review older than ${GUIDE_REVIEW_MAX_DAYS} days`);
      if (data.fixture) reasons.push('fixture data');
      const city = g.city ? cities.get(g.city) ?? null : null;
      const priced = pages.filter((p) => p.category.slug === g.category && p.showPrices && (p.status === 'indexable' || data.fixture));
      out.push({
        data: g,
        category,
        city,
        status: reasons.length ? 'noindex' : 'indexable',
        reasons,
        pricePage: city ? priced.find((p) => p.city.slug === city.slug) ?? null : null,
        categoryPages: priced.sort((a, b) => b.data.quotes_window - a.data.quotes_window).slice(0, 6),
        path: `/guides/${g.slug}`,
      });
    }
    const idx = out.filter((g) => g.status === 'indexable').length;
    console.log(`[app_site:${country}] guides: ${idx} indexable, ${out.length - idx} noindex`);
    return out;
  })();
  return guideCache;
}
