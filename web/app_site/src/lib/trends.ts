/**
 * "What's happening" on town pages: headlines from the separate trends news site
 * (web/trends_site), at four levels: the town, its state, the country and the world.
 *
 * Read at build time with the trends site's own loader and gates
 * (trends_site/src/lib/articles.ts): committed articles in trends_site/data/articles and,
 * when TRENDS_DATA_URL is set, the pipeline's public bucket (downloaded by the prebuild
 * step scripts/fetch-trends.mjs into .trends-remote/). Only articles that the trends site
 * publishes as indexable are used; nothing is ever written here. Each item shows the
 * headline, one line per perspective (the first sentence of each side) and a link to the
 * full article on the trends site: no article text is copied beyond that.
 *
 * Levels: an article's `places` (level "metro" = a town, "state", "country") and the
 * optional `scope` field ("world" for world news; see supabase/API.md section 13).
 */
import fs from 'node:fs';
import path from 'node:path';
import { loadArticles, type Article } from '../../../trends_site/src/lib/articles';
import { country, warnOnce } from './site';
import type { StateInfo, Town } from './towns';

export interface NewsItem {
  slug: string;
  headline: string;
  url: string;
  publishedAt: string;
  sides: { label: string; line: string }[];
}

export interface TownNews {
  town: NewsItem[];
  state: NewsItem[];
  country: NewsItem[];
  world: NewsItem[];
}

const env = (k: string) => (process.env[k] ?? '').trim();
/** Public URL of the trends site (links only). */
export const TRENDS_SITE_URL = (env('TRENDS_SITE_URL') || 'https://iwant-trends-web.vercel.app').replace(/\/+$/, '');
const MAX_PER_LEVEL = 3;
const MAX_AGE_DAYS = 30;

const norm = (s: string) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]/g, '');

/** First sentence of a perspective, at most ~150 characters (cut at a word). */
export function oneLine(body: string): string {
  const text = body.replace(/\s+/g, ' ').trim();
  const m = text.match(/^(.+?[.!?])(\s|$)/);
  let s = m ? m[1] : text;
  if (s.length > 150) s = `${s.slice(0, 150).replace(/\s+\S*$/, '')}…`;
  return s;
}

function load(): Article[] {
  const root = process.cwd();
  const dataDir = path.resolve(root, env('TRENDS_DATA_DIR') || '../trends_site/data/articles');
  const remoteDir = path.resolve(root, '.trends-remote');
  const remote = env('TRENDS_DATA_URL') && fs.existsSync(path.join(remoteDir, 'settings.json')) ? env('TRENDS_DATA_URL') : '';
  if (env('TRENDS_DATA_URL') && !remote) warnOnce('TRENDS_DATA_URL is set but .trends-remote/ is missing (run `npm run build`, whose prebuild downloads it); using committed articles only');
  const now = env('BUILD_NOW') ? new Date(env('BUILD_NOW')) : new Date();
  const { built } = loadArticles({
    dataDir,
    remoteDataUrl: remote,
    remoteDir,
    configFile: path.resolve(root, '../trends_site/data/config.json'),
    now,
    log: `[app_site:${country}] trends:`,
  });
  const fixtures = env('TRENDS_INCLUDE_FIXTURES') === '1';
  const cutoff = now.getTime() - MAX_AGE_DAYS * 86_400_000;
  return built
    .filter((b) => b.indexable || (fixtures && b.noindexReasons.every((r) => r === 'fixture')))
    .map((b) => b.article)
    .filter((a) => a.country === country && Date.parse(a.published_at) >= cutoff);
}

let cache: Article[] | null = null;
const articles = () => (cache ??= load());

function item(a: Article): NewsItem {
  return {
    slug: a.slug,
    headline: a.headline,
    url: `${TRENDS_SITE_URL}/a/${a.slug}`,
    publishedAt: a.published_at,
    sides: [a.perspectives.a, a.perspectives.b].map((p) => ({ label: p.label, line: oneLine(p.body) })),
  };
}

const pick = (list: Article[]) => list.slice(0, MAX_PER_LEVEL).map(item);

/** Articles for a town page; every level is empty when there is nothing real to show. */
export function townNews(town: Town): TownNews {
  const all = articles();
  if (!all.length) return { town: [], state: [], country: [], world: [] };
  const used = new Set<string>();
  const take = (list: Article[]) => {
    const out = list.filter((a) => !used.has(a.slug));
    for (const a of out.slice(0, MAX_PER_LEVEL)) used.add(a.slug);
    return pick(out);
  };
  const names = new Set([town.slug, norm(town.name)]);
  const inState = (s: StateInfo, p: { slug: string; name: string }) => p.slug === s.slug || norm(p.name) === norm(s.name);
  const wide = (a: Article) => a.scope === 'world' || a.scope === 'country';
  const townLevel = all.filter((a) =>
    !wide(a) &&
    a.places.some((p) => p.level === 'metro' && (names.has(p.slug) || names.has(norm(p.name))) && (!p.state || norm(p.state) === norm(town.state.name))),
  );
  const stateLevel = all.filter((a) => !wide(a) && a.places.some((p) => p.level === 'state' && inState(town.state, p)));
  const countryLevel = all.filter((a) => a.scope === 'country' || (a.scope !== 'world' && a.places.some((p) => p.level === 'country')));
  const worldLevel = all.filter((a) => a.scope === 'world');
  return { town: take(townLevel), state: take(stateLevel), country: take(countryLevel), world: take(worldLevel) };
}

export const hasNews = (n: TownNews) => n.town.length + n.state.length + n.country.length + n.world.length > 0;
