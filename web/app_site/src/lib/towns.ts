/**
 * Town pages (/in/<slug>) and the town picker. One hand-curated list per
 * country in data/towns/<country>.json: name, state, approximate centre
 * coordinates, well-known neighbourhoods and the first digits of the postal
 * codes. Nothing here is a statistic: prices and seller counts only ever come
 * from the nightly SEO export (lib/seo.ts), and a town page links to those
 * price pages when they exist for the same slug.
 */
import path from 'node:path';
import { country, readJson } from './site';
import { cityHubs, sellerCities, type CityHub, type SellerCity } from './seo';
import { haversineKm, roundDistance } from '../scripts/town-core';

export interface Town {
  slug: string;
  name: string;
  /** Other names people search for (Calicut, Bangalore, NYC). */
  aka: string[];
  state: string;
  lat: number;
  lng: number;
  areas: string[];
  /** First three digits of the town's PIN / ZIP codes. */
  postal_prefixes: string[];
}

export interface TownPage {
  town: Town;
  path: string;
  /** Enough real, town-specific facts to be worth indexing. */
  indexable: boolean;
  /** Other towns on the list, nearest first (straight-line distance). */
  nearby: { town: Town; distance: number }[];
  /** Price hub for the same slug in the SEO export, if one was built. */
  hub: CityHub | null;
  sellers: SellerCity | null;
}

/** Thin-page bar: below this a town page is built with noindex and left out of the sitemap. */
export const MIN_AREAS = 5;

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function validate(towns: Town[]): Town[] {
  const seen = new Set<string>();
  for (const t of towns) {
    if (!SLUG.test(t.slug)) throw new Error(`towns: bad slug "${t.slug}"`);
    if (seen.has(t.slug)) throw new Error(`towns: duplicate slug "${t.slug}"`);
    seen.add(t.slug);
    if (!t.name || !t.state) throw new Error(`towns: ${t.slug} needs name and state`);
    if (!(Math.abs(t.lat) <= 90 && Math.abs(t.lng) <= 180)) throw new Error(`towns: ${t.slug} has bad coordinates`);
    if (!Array.isArray(t.areas) || !Array.isArray(t.postal_prefixes)) throw new Error(`towns: ${t.slug} needs areas and postal_prefixes arrays`);
    if (t.postal_prefixes.some((p) => !/^\d{3}$/.test(p))) throw new Error(`towns: ${t.slug} postal prefixes must be 3 digits`);
    t.aka ??= [];
  }
  return towns;
}

export const towns: Town[] = validate(
  readJson<{ country: string; towns: Town[] }>(path.resolve(process.cwd(), 'data', 'towns', `${country}.json`)).towns,
);

export { haversineKm };

/** "about 70 km" (India) / "about 45 miles" (USA); same rounding as the picker. */
export function distanceText(km: number): string {
  const unit = country === 'usa' ? 'mi' : 'km';
  return `about ${roundDistance(km, unit)} ${unit === 'mi' ? 'miles' : 'km'}`;
}

let cache: Promise<TownPage[]> | null = null;

export function townPages(): Promise<TownPage[]> {
  cache ??= (async () => {
    const hubs = await cityHubs();
    const dirs = await sellerCities();
    const out = towns.map((town) => ({
      town,
      path: `/in/${town.slug}`,
      indexable: town.areas.length >= MIN_AREAS && town.postal_prefixes.length > 0,
      nearby: towns
        .filter((o) => o.slug !== town.slug)
        .map((o) => ({ town: o, distance: haversineKm(town.lat, town.lng, o.lat, o.lng) }))
        .sort((a, b) => a.distance - b.distance)
        .slice(0, 3),
      hub: hubs.find((h) => h.city.slug === town.slug) ?? null,
      sellers: dirs.find((d) => d.slug === town.slug) ?? null,
    }));
    const idx = out.filter((p) => p.indexable).length;
    console.log(`[app_site:${country}] town pages: ${idx} indexable, ${out.length - idx} noindex (fewer than ${MIN_AREAS} areas)`);
    return out;
  })();
  return cache;
}

/** Towns sorted by name, for lists and the picker. */
export const townsByName = () => [...towns].sort((a, b) => a.name.localeCompare(b.name));

/** "682" -> "682xxx" (PIN, 6 digits) / "752" -> "752xx" (ZIP, 5 digits). */
export const postalPattern = (prefix: string) => prefix + 'x'.repeat(country === 'usa' ? 2 : 3);

/** "A, B and C". */
export function joinList(items: string[], and = 'and'): string {
  if (items.length <= 1) return items.join('');
  return `${items.slice(0, -1).join(', ')} ${and} ${items[items.length - 1]}`;
}
