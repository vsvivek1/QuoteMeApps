// Prebuild step (runs before `npm run build`): when TRENDS_DATA_URL is set, downloads the
// trends pipeline output (Supabase public bucket `trends-public`: index.json + articles/<slug>.json)
// into .trends-remote/. The build then reads those files IN ADDITION to data/articles/ and runs
// every build-time gate on them exactly as on local files (src/lib/articles.ts); the remote index
// can only tighten the kill switch and the daily caps, never loosen them.
//
// TRENDS_DATA_URL: the bucket's public base URL or its index.json, e.g.
//   https://<ref>.supabase.co/storage/v1/object/public/trends-public/
// Unset: nothing is downloaded and only data/articles/ is built.
// The build fails if the index cannot be fetched or is malformed (the previous deploy stays live).
import fs from 'node:fs';
import path from 'node:path';

const OUT = path.resolve(process.cwd(), '.trends-remote');
const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAX_INDEX_BYTES = 5 * 1024 * 1024;
const MAX_ARTICLE_BYTES = 1024 * 1024;
const MAX_ARTICLES = 5000;

const raw = (process.env.TRENDS_DATA_URL ?? '').trim();
fs.rmSync(OUT, { recursive: true, force: true });
if (!raw) {
  console.log('[trends_site] TRENDS_DATA_URL not set: building data/articles only');
  process.exit(0);
}

function fail(msg) {
  console.error(`[trends_site] ERROR TRENDS_DATA_URL: ${msg}`);
  process.exit(1);
}

let indexUrl;
try {
  const u = new URL(raw);
  const local = u.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(u.hostname);
  if (u.protocol !== 'https:' && !local) fail('must be https');
  if (u.username || u.password) fail('must not contain credentials');
  indexUrl = u.pathname.endsWith('.json') ? u : new URL('index.json', u.href.endsWith('/') ? u.href : `${u.href}/`);
} catch (e) {
  fail(`invalid URL (${e.message})`);
}
const base = new URL('.', indexUrl);

async function get(url, max) {
  const res = await fetch(url, { signal: AbortSignal.timeout(20_000), headers: { accept: 'application/json' } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const text = await res.text();
  if (Buffer.byteLength(text) > max) throw new Error('too large');
  return text;
}

let index;
try {
  index = JSON.parse(await get(indexUrl, MAX_INDEX_BYTES));
} catch (e) {
  fail(`could not load ${indexUrl.href}: ${e.message}`);
}
if (!index || index.version !== 1 || !Array.isArray(index.articles)) fail('index.json must be {version: 1, articles: [...]}');
if (index.articles.length > MAX_ARTICLES) fail(`more than ${MAX_ARTICLES} articles`);

const entries = [];
const seen = new Set();
for (const e of index.articles) {
  const slug = e?.slug;
  if (typeof slug !== 'string' || !SLUG.test(slug) || seen.has(slug)) {
    console.warn(`[trends_site] WARNING remote index: skipped entry with bad or duplicate slug ${JSON.stringify(slug)}`);
    continue;
  }
  if (e.path !== `articles/${slug}.json`) {
    console.warn(`[trends_site] WARNING remote index: ${slug} has unexpected path ${JSON.stringify(e.path)}; skipped`);
    continue;
  }
  const url = new URL(e.path, base);
  if (url.origin !== base.origin || !url.href.startsWith(base.href)) continue;
  seen.add(slug);
  entries.push({ slug, url });
}

fs.mkdirSync(path.join(OUT, 'articles'), { recursive: true });
let ok = 0;
let i = 0;
await Promise.all(Array.from({ length: Math.min(8, entries.length) }, async () => {
  while (i < entries.length) {
    const { slug, url } = entries[i++];
    try {
      // Written as fetched: invalid JSON or failing articles are rejected by the build gates.
      fs.writeFileSync(path.join(OUT, 'articles', `${slug}.json`), await get(url, MAX_ARTICLE_BYTES));
      ok++;
    } catch (e) {
      console.warn(`[trends_site] WARNING remote article ${slug}: ${e.message}; skipped`);
    }
  }
}));

const s = index.settings ?? {};
fs.writeFileSync(path.join(OUT, 'settings.json'), JSON.stringify({
  paused: s.paused === true,
  paused_at: typeof s.paused_at === 'string' ? s.paused_at : null,
  per_day: { usa: s.per_day?.usa ?? null, india: s.per_day?.india ?? null },
  source: indexUrl.href,
  generated_at: index.generated_at ?? null,
}, null, 2));
console.log(`[trends_site] remote data: ${ok}/${entries.length} article file(s) from ${indexUrl.href}`);
