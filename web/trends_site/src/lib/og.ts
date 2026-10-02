/**
 * Open Graph images for the trends site (brief 21.10: "Open Graph image
 * generated from a template (no copied photos)"). Own neutral look, no app
 * branding: site name, the article headline and its place, rendered to a
 * 1200x630 PNG at build time with web/shared/og.mjs. Every article that is
 * built gets one; home and the country pages too; other pages use /og/site.png.
 */
import path from 'node:path';
import { Resvg } from '@resvg/resvg-js';
import * as hb from 'harfbuzzjs';
import { createOgRenderer } from '../../../shared/og.mjs';
import { loadArticles } from './articles';
import { COUNTRY_LABEL, WEB_ROOT, site } from './site';

export interface OgSpec {
  kicker?: string;
  title: string;
  detail?: string;
}

const keyOf = (p: string) => (p === '/' ? 'home' : p.replace(/^\/+/, ''));
const ogPath = (key: string) => `/og/${key}.png`;
const TAGLINE = 'Two sides, every source linked';

let cache: Map<string, OgSpec> | null = null;

export function ogEntries(): Map<string, OgSpec> {
  if (cache) return cache;
  const out = new Map<string, OgSpec>();
  out.set('site', { title: site.name, detail: 'Local stories trending in Indian and US cities, explained from two neutral perspectives.' });
  out.set('home', { kicker: 'India and the United States', title: "What's happening near you", detail: 'Local stories trending right now, explained from two neutral perspectives.' });
  for (const country of ['india', 'usa'] as const) {
    out.set(country, { kicker: COUNTRY_LABEL[country], title: `Trending in ${COUNTRY_LABEL[country]}`, detail: 'Local stories trending right now, explained from two neutral perspectives.' });
  }
  for (const { article: a } of loadArticles().built) {
    const place = a.places.find((p) => p.level !== 'country') ?? a.places[0];
    const where = place ? [place.name, place.level === 'country' ? null : COUNTRY_LABEL[a.country]].filter(Boolean).join(', ') : COUNTRY_LABEL[a.country];
    out.set(`a/${a.slug}`, {
      kicker: `Trending in ${where}`,
      title: a.headline,
      detail: `${a.sources.length} independent sources, both perspectives side by side.`,
    });
  }
  cache = out;
  return out;
}

export function ogImageFor(pagePath: string): string {
  const key = keyOf(pagePath);
  return ogPath(ogEntries().has(key) ? key : 'site');
}

let renderer: ReturnType<typeof createOgRenderer> | null = null;

export function renderOg(spec: OgSpec): Buffer {
  renderer ??= createOgRenderer({ hb, Resvg, fontDir: path.join(WEB_ROOT, 'shared', 'fonts') });
  return renderer.png({
    // Same colours as src/styles/global.css (light theme).
    colors: { bg: '#ffffff', fg: '#111827', muted: '#4b5563', accent: '#0f766e', accentSoft: '#ccfbf1', band: '#0f766e', bandFg: '#ffffff' },
    brand: site.name,
    footer: site.domain,
    footerRight: TAGLINE,
    ...spec,
  });
}
