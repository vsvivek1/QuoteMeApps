import type { APIRoute } from 'astro';
import { towns } from '../lib/towns';

// PIN/ZIP code -> town ("state/town") for the town picker, fetched only when someone types digits.
// A code shared by several towns maps to the most populous one.
export const GET: APIRoute = () => {
  const out: Record<string, string> = {};
  for (const t of [...towns].sort((a, b) => (b.population ?? 0) - (a.population ?? 0))) {
    for (const z of t.postal) out[z] ??= `${t.state.slug}/${t.slug}`;
  }
  return new Response(JSON.stringify(out), { headers: { 'Content-Type': 'application/json; charset=utf-8' } });
};
