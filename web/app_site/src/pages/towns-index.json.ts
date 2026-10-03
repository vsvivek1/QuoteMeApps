import type { APIRoute } from 'astro';
import { isMajor, states, towns } from '../lib/towns';

// Compact town list for the town picker (scripts/town-picker.ts), fetched only when the picker
// is opened. Largest towns first, so search results lead with them.
//   states: [slug, name, localeSegment]   towns: [slug, name, stateIndex, lat, lng, major (0|1), extra search terms]
export const GET: APIRoute = () => {
  const idx = new Map(states.map((s, i) => [s, i]));
  const rows = [...towns]
    .sort((a, b) => (b.population ?? 0) - (a.population ?? 0) || a.name.localeCompare(b.name, 'en'))
    .map((t) => {
      const extra = [...new Set([t.native ?? '', ...t.aka].filter((x) => x && x !== t.name))].join('|');
      return [t.slug, t.name, idx.get(t.state)!, Math.round(t.lat * 1e3) / 1e3, Math.round(t.lng * 1e3) / 1e3, isMajor(t) ? 1 : 0, ...(extra ? [extra] : [])];
    });
  const body = { v: 1, states: states.map((s) => [s.slug, s.name, s.locale?.segment ?? '']), towns: rows };
  return new Response(JSON.stringify(body), { headers: { 'Content-Type': 'application/json; charset=utf-8' } });
};
