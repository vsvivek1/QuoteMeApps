#!/usr/bin/env node
/**
 * Post-build check for a built site (run from the site folder after `npm run build`):
 *   node ../shared/check-dist.mjs [dist]
 *
 * - every og:image / twitter:image on the site's own domain exists in dist and is a 1200x630 PNG;
 * - every hreflang alternate exists, lists the same set of alternates back
 *   (reciprocal), has exactly one x-default, and is not noindex.
 * Exits 1 with a list of problems. No dependencies.
 */
import fs from 'node:fs';
import path from 'node:path';

const dist = path.resolve(process.argv[2] ?? 'dist');
const problems = [];

function htmlFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) return e.name.startsWith('.') ? [] : htmlFiles(p);
    return e.name.endsWith('.html') ? [p] : [];
  });
}

/** URL path -> file in dist (Vercel cleanUrls: /a -> a.html, / -> index.html). */
function fileFor(urlPath) {
  const p = decodeURIComponent(urlPath).replace(/\/+$/, '') || '/';
  const candidates = p === '/' ? ['index.html'] : [p.slice(1), `${p.slice(1)}.html`, `${p.slice(1)}/index.html`];
  return candidates.map((c) => path.join(dist, c)).find((f) => fs.existsSync(f) && fs.statSync(f).isFile()) ?? null;
}

const attr = (tag, name) => (tag.match(new RegExp(`${name}="([^"]*)"`)) ?? [])[1];
const pages = new Map();
let host = null;

for (const file of htmlFiles(dist)) {
  const html = fs.readFileSync(file, 'utf8');
  const head = html.split('</head>')[0];
  const tags = head.match(/<(meta|link)\b[^>]*>/g) ?? [];
  const canonical = tags.filter((t) => /rel="canonical"/.test(t)).map((t) => attr(t, 'href'))[0];
  const rel = path.relative(dist, file);
  if (canonical && !host) host = new URL(canonical).host;
  pages.set(rel, {
    canonical,
    noindex: /<meta name="robots" content="noindex/.test(head),
    images: tags.filter((t) => /property="og:image"|name="twitter:image"/.test(t)).map((t) => attr(t, 'content')),
    alternates: tags.filter((t) => /rel="alternate"/.test(t) && /hreflang=/.test(t)).map((t) => ({ hreflang: attr(t, 'hreflang'), href: attr(t, 'href') })),
  });
}

const local = (u) => {
  const url = new URL(u);
  return url.host === host ? url.pathname : null;
};

const pngSize = (f) => {
  const b = fs.readFileSync(f);
  if (b.readUInt32BE(0) !== 0x89504e47) return null;
  return [b.readUInt32BE(16), b.readUInt32BE(20)];
};

let images = 0;
let alternateSets = 0;
for (const [rel, p] of pages) {
  for (const img of new Set(p.images)) {
    const pth = local(img);
    if (!pth) continue;
    const f = fileFor(pth);
    if (!f) problems.push(`${rel}: og image ${img} is not in dist`);
    else if (pth.endsWith('.png')) {
      const size = pngSize(f);
      if (!size || size[0] !== 1200 || size[1] !== 630) problems.push(`${rel}: og image ${img} is ${size ? size.join('x') : 'not a PNG'}, expected 1200x630`);
      else images++;
    }
  }
  if (!p.alternates.length) continue;
  alternateSets++;
  const set = (alts) => alts.map((a) => `${a.hreflang} ${a.href}`).sort().join('|');
  if (p.alternates.filter((a) => a.hreflang === 'x-default').length !== 1) problems.push(`${rel}: needs exactly one x-default alternate`);
  if (!p.alternates.some((a) => a.href === p.canonical)) problems.push(`${rel}: alternates do not include the page itself (${p.canonical})`);
  for (const a of p.alternates) {
    const pth = local(a.href);
    const f = pth && fileFor(pth);
    if (!f) {
      problems.push(`${rel}: hreflang ${a.hreflang} -> ${a.href} is not in dist`);
      continue;
    }
    const other = pages.get(path.relative(dist, f));
    if (other?.noindex) problems.push(`${rel}: hreflang ${a.hreflang} -> ${a.href} is noindex`);
    if (other && set(other.alternates) !== set(p.alternates)) problems.push(`${rel}: hreflang ${a.hreflang} -> ${a.href} does not link back with the same alternates`);
  }
}

if (problems.length) {
  console.error(`check-dist: ${problems.length} problem(s) in ${dist}\n  ${problems.join('\n  ')}`);
  process.exit(1);
}
console.log(`check-dist: OK (${pages.size} pages, ${images} generated og:image PNGs checked (1200x630), ${alternateSets} pages with hreflang alternates)`);
