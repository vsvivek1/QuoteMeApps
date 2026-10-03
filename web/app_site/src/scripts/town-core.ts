// Shared by the build (lib/towns.ts) and the browser (town picker): no DOM or Node APIs
// at module level, so both can import it.

export interface PickTown {
  /** "<state>/<town>". */
  path: string;
  name: string;
  lat: number;
  lng: number;
}

export const STORAGE_KEY = 'iwant.town';

/** Great-circle distance in km. */
export function haversineKm(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const r = (d: number) => (d * Math.PI) / 180;
  const dLat = r(bLat - aLat);
  const dLng = r(bLng - aLng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(r(aLat)) * Math.cos(r(bLat)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Rounded so a straight-line distance never reads as precise: 5s under 100, then 10s. */
export function roundDistance(km: number, unit: 'km' | 'mi'): number {
  const v = unit === 'mi' ? km / 1.609344 : km;
  return Math.max(5, v < 100 ? Math.round(v / 5) * 5 : Math.round(v / 10) * 10);
}

export function nearestTown<T extends PickTown>(towns: T[], lat: number, lng: number): { town: T; km: number } {
  let best = towns[0];
  let bestKm = Infinity;
  for (const t of towns) {
    const km = haversineKm(lat, lng, t.lat, t.lng);
    if (km < bestKm) {
      best = t;
      bestKm = km;
    }
  }
  return { town: best, km: bestKm };
}

/**
 * The remembered town, or null (private mode, blocked storage, nothing chosen yet).
 * `path` is "<state>/<town>". Towns remembered before state paths existed have only a slug;
 * their link goes to /in/<slug>, which redirects (vercel.json) to the new page.
 */
export function readTown(): { path: string; name: string } | null {
  try {
    const v = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? 'null');
    if (!v || typeof v.name !== 'string') return null;
    const name = v.name.slice(0, 64);
    if (typeof v.path === 'string' && /^[a-z0-9-]{1,64}\/[a-z0-9-]{1,64}$/.test(v.path)) return { path: v.path, name };
    if (typeof v.slug === 'string' && /^[a-z0-9-]{1,64}$/.test(v.slug)) return { path: `in/${v.slug}`, name };
    return null;
  } catch {
    return null;
  }
}

export function saveTown(town: { path: string; name: string }): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ path: town.path, name: town.name }));
  } catch {
    // Storage unavailable: the choice just is not remembered.
  }
}
