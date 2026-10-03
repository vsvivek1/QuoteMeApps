/**
 * Town pages (/<state>/<town>, plus the local-language version under /<lang>/...),
 * state pages (/<state>), the towns directory (/in) and the town picker.
 *
 * Data: data/towns/generated/<country>.json.gz, built by tool/data/build_towns.py from
 * GeoNames (CC BY 4.0: populated places, districts/counties, population, native-script
 * names, PIN/ZIP codes) with the hand-curated towns in data/towns/<country>.json merged in
 * (they keep their slug, areas and aliases). Nothing here is a statistic about the app:
 * prices and seller counts only ever come from the nightly SEO export (lib/seo.ts).
 *
 * TOWNS_LIMIT=<n> keeps only the curated towns plus the n most populous others, for quick
 * local builds (CI and Vercel build every town; see web/README.md).
 */
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { country, readJson } from './site';
import { cityHubs, sellerCities, type CityHub, type SellerCity } from './seo';
import { LOCALES, townLocale, type Locale } from './i18n';
import { haversineKm, roundDistance } from '../scripts/town-core';

export interface StateInfo {
  slug: string;
  name: string;
  /** USPS code (USA) or ISO 3166-2:IN suffix (India). */
  code: string;
  /** Second page language for this state's towns (India: state's main language; USA: Spanish). */
  locale: Locale | null;
}

export interface Town {
  slug: string;
  name: string;
  /** Name in the state's script (GeoNames alternate names, or the curated list). */
  native?: string;
  state: StateInfo;
  /** District (India) or county (USA). */
  district?: string;
  lat: number;
  lng: number;
  /** GeoNames population figure; shown only as a rounded band. */
  population?: number;
  /** PIN / ZIP codes. */
  postal: string[];
  /** How the codes were found: post office / USPS place name, or nearest post office (within 5 km). */
  postalMode: 'name' | 'near' | null;
  /** Localities (post offices, GeoNames neighbourhoods, or the curated list). */
  areas: string[];
  aka: string[];
  curated: boolean;
  geonameId?: number;
}

export interface Nearby {
  town: Town;
  km: number;
}

export interface TownPage {
  town: Town;
  /** English path, e.g. /kerala/kochi. */
  path: string;
  /** Local-language path, e.g. /ml/kerala/kochi (null when the state has no second language). */
  localPath: string | null;
  /** Some town-specific fact beyond its name (postal codes, district, areas, population). */
  indexable: boolean;
  /** Other towns, nearest first (straight-line distance between centres). */
  nearby: Nearby[];
  /** Price hub for the same town in the SEO export, if one was built. */
  hub: CityHub | null;
  sellers: SellerCity | null;
}

interface Raw {
  version: number;
  sources: { title: string; licence: string; url: string }[];
  states: { slug: string; name: string; code: string; lang?: string }[];
  towns: {
    s: string; n: string; nn?: string; st: string; d?: string; la: number; lo: number; p?: number;
    z?: string[]; zm?: 'name' | 'near'; a?: string[]; aka?: string[]; c?: 1; g?: number;
  }[];
}

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const FILE = path.resolve(process.cwd(), 'data', 'towns', 'generated', `${country}.json.gz`);
const raw = JSON.parse(zlib.gunzipSync(fs.readFileSync(FILE)).toString('utf8')) as Raw;
if (raw.version !== 1) throw new Error(`towns: ${FILE} has unknown version ${raw.version}`);

/** GeoNames attribution lines for the credits page. */
export const townSources = raw.sources;

export const states: StateInfo[] = raw.states.map((s) => {
  if (!SLUG.test(s.slug)) throw new Error(`towns: bad state slug "${s.slug}"`);
  return { slug: s.slug, name: s.name, code: s.code, locale: townLocale(country === 'usa' ? 'es' : s.lang) };
});
const stateBySlug = new Map(states.map((s) => [s.slug, s]));

function load(): Town[] {
  const all: Town[] = raw.towns.map((r) => {
    const state = stateBySlug.get(r.st);
    if (!state) throw new Error(`towns: ${r.s} has unknown state ${r.st}`);
    if (!SLUG.test(r.s)) throw new Error(`towns: bad slug "${r.s}"`);
    return {
      slug: r.s,
      name: r.n,
      native: r.nn,
      state,
      district: r.d,
      lat: r.la,
      lng: r.lo,
      population: r.p,
      postal: r.z ?? [],
      postalMode: r.zm ?? null,
      areas: r.a ?? [],
      aka: r.aka ?? [],
      curated: r.c === 1,
      geonameId: r.g,
    };
  });
  const seen = new Set<string>();
  for (const t of all) {
    const key = `${t.state.slug}/${t.slug}`;
    if (seen.has(key)) throw new Error(`towns: duplicate ${key}`);
    seen.add(key);
  }
  const limit = Number.parseInt(process.env.TOWNS_LIMIT ?? '', 10);
  if (!(limit >= 0)) return all;
  const rest = all.filter((t) => !t.curated).sort((a, b) => (b.population ?? 0) - (a.population ?? 0)).slice(0, limit);
  const keep = new Set([...all.filter((t) => t.curated), ...rest]);
  console.log(`[app_site:${country}] TOWNS_LIMIT=${limit}: building ${keep.size} of ${all.length} towns`);
  return all.filter((t) => keep.has(t));
}

export const towns: Town[] = load();

/** Curated-list check kept from the old data file (fails the build when the generator dropped one). */
{
  const curated = readJson<{ towns: { slug: string }[] }>(path.resolve(process.cwd(), 'data', 'towns', `${country}.json`)).towns;
  const have = new Set(towns.filter((t) => t.curated).map((t) => t.slug));
  const missing = curated.filter((c) => !have.has(c.slug)).map((c) => c.slug);
  if (missing.length) throw new Error(`towns: curated towns missing from the generated data (re-run tool/data/build_towns.py): ${missing.join(', ')}`);
}

export const townsInState = (s: StateInfo) => towns.filter((t) => t.state === s);
export const statesWithTowns = () => states.filter((s) => towns.some((t) => t.state === s));

export { haversineKm };

const prefix = (l: Locale | null | undefined) => (l && l.prefix ? l.prefix : '');
export const townPath = (t: Town, l?: Locale | null) => `${prefix(l)}/${t.state.slug}/${t.slug}`;
export const statePath = (s: StateInfo, l?: Locale | null) => `${prefix(l)}/${s.slug}`;
export const TOWNS_INDEX_PATH = '/in';

/** Rounded straight-line distance number in the site's unit (km in India, miles in the USA). */
export const distanceUnit: 'km' | 'mi' = country === 'usa' ? 'mi' : 'km';
export const roundedDistance = (km: number) => roundDistance(km, distanceUnit);

/** 0.5 degree buckets: nearest-town queries stay fast with 20,000 towns. */
const CELL = 0.5;
const grid = new Map<string, Town[]>();
for (const t of towns) {
  const k = `${Math.floor(t.lat / CELL)},${Math.floor(t.lng / CELL)}`;
  grid.get(k)?.push(t) ?? grid.set(k, [t]);
}

/** The n nearest other towns (searches outwards ring by ring). */
export function nearestTowns(town: Town, n = 5): Nearby[] {
  const ci = Math.floor(town.lat / CELL);
  const cj = Math.floor(town.lng / CELL);
  const found: Nearby[] = [];
  for (let r = 0; r <= 40; r++) {
    for (let i = ci - r; i <= ci + r; i++) {
      for (let j = cj - r; j <= cj + r; j++) {
        if (Math.max(Math.abs(i - ci), Math.abs(j - cj)) !== r) continue;
        for (const o of grid.get(`${i},${j}`) ?? []) {
          if (o !== town) found.push({ town: o, km: haversineKm(town.lat, town.lng, o.lat, o.lng) });
        }
      }
    }
    // Everything within r cells (at least r * 0.5 degrees of latitude, ~55 km) has been seen.
    if (found.length >= n && r >= 1) {
      found.sort((a, b) => a.km - b.km);
      if (found[n - 1].km <= r * CELL * 111 * Math.cos((Math.min(80, Math.abs(town.lat) + r * CELL) * Math.PI) / 180)) break;
    }
  }
  return found.sort((a, b) => a.km - b.km).slice(0, n);
}

let cache: Promise<Map<string, TownPage>> | null = null;

/** Every town page keyed by "<state>/<town>". */
export function townPages(): Promise<Map<string, TownPage>> {
  cache ??= (async () => {
    const hubs = await cityHubs();
    const dirs = await sellerCities();
    const sameCity = (slug: string, state: string | undefined, t: Town) => slug === t.slug && (!state || state === t.state.name);
    const out = new Map<string, TownPage>();
    for (const town of towns) {
      const hub = hubs.find((h) => sameCity(h.city.slug, h.city.state, town)) ?? null;
      const sellers = dirs.find((d) => sameCity(d.slug, d.city?.state, town)) ?? null;
      out.set(`${town.state.slug}/${town.slug}`, {
        town,
        path: townPath(town),
        localPath: town.state.locale ? townPath(town, town.state.locale) : null,
        indexable: town.postal.length > 0 || town.areas.length > 0 || Boolean(town.district) || Boolean(town.population),
        nearby: nearestTowns(town),
        hub,
        sellers,
      });
    }
    const idx = [...out.values()].filter((p) => p.indexable).length;
    const local = [...out.values()].filter((p) => p.localPath).length;
    console.log(`[app_site:${country}] town pages: ${out.size} towns (${idx} indexable, ${out.size - idx} noindex: no town-specific facts), ${local} with a ${LOCALES[1].name}/local-language version`);
    return out;
  })();
  return cache;
}

export async function townPage(t: Town): Promise<TownPage> {
  return (await townPages()).get(`${t.state.slug}/${t.slug}`)!;
}

/** Population as a rounded band ("100,000 to 250,000"), never the exact figure. */
const BANDS = [0, 5_000, 10_000, 25_000, 50_000, 100_000, 250_000, 500_000, 1_000_000, 2_500_000, 5_000_000, 10_000_000];
export function populationBand(p: number | undefined): { from: number; to: number | null } | null {
  if (!p || p <= 0) return null;
  for (let i = BANDS.length - 1; i >= 0; i--) if (p >= BANDS[i]) return { from: BANDS[i], to: BANDS[i + 1] ?? null };
  return null;
}

/** "682xxx" style prefix list for the meta description: unique first 3 digits. */
export const postalPrefixes = (t: Town) => [...new Set(t.postal.map((z) => z.slice(0, 3)))];

/** "A, B and C" in English; translated pages pass their own conjunction. */
export function joinList(items: string[], and = 'and'): string {
  if (items.length <= 1) return items.join('');
  return `${items.slice(0, -1).join(', ')} ${and} ${items[items.length - 1]}`;
}

/** Larger towns (or curated): listed first on state pages, shown as dots on the picker map. */
export const isMajor = (t: Town) => t.curated || (t.population ?? 0) >= 100_000;
