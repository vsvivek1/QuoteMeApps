/**
 * Open Graph image renderer shared by app_site and trends_site (brief 21.9 / 21.10).
 *
 * Builds a 1200x630 SVG from a template (brand colours, optional logo, the
 * page's own text; no photos) and renders it to PNG with @resvg/resvg-js at
 * build time. Text is shaped with HarfBuzz (harfbuzzjs) and drawn as glyph
 * outlines, because resvg's own text layout breaks Devanagari (Hindi) clusters;
 * this also gives exact widths for line wrapping. Only the OFL fonts in
 * web/shared/fonts are used, so output does not depend on the build machine.
 *
 * The site passes in the two libraries (they live in each site's node_modules,
 * not in web/shared) and the font folder (this module gets bundled, so it cannot
 * find it itself): createOgRenderer({ hb, Resvg, fontDir: '<repo>/web/shared/fonts' }).
 */
import fs from 'node:fs';
import path from 'node:path';

export const OG_WIDTH = 1200;
export const OG_HEIGHT = 630;

const FONTS = {
  latin: { regular: 'Inter-Regular.ttf', bold: 'Inter-Bold.ttf' },
  deva: { regular: 'NotoSansDevanagari-Regular.ttf', bold: 'NotoSansDevanagari-Bold.ttf' },
};

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const num = (n) => (Math.round(n * 100) / 100).toString();
const DEVA = /[ऀ-ॿ᳐-᳿꣠-ꣿ‌‍]/;

/**
 * @param {{ hb: typeof import('harfbuzzjs'), Resvg: typeof import('@resvg/resvg-js').Resvg, fontDir: string }} libs
 */
export function createOgRenderer({ hb, Resvg, fontDir }) {
  const fonts = {};
  for (const [script, weights] of Object.entries(FONTS)) {
    for (const [weight, file] of Object.entries(weights)) {
      const buf = fs.readFileSync(path.join(fontDir, file));
      const face = new hb.Face(new hb.Blob(buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength)));
      fonts[`${script}-${weight}`] = { font: new hb.Font(face), upem: face.upem, paths: new Map() };
    }
  }

  /** Splits text into runs of one script (Devanagari vs everything else). */
  function runs(text) {
    const out = [];
    for (const ch of text) {
      const script = DEVA.test(ch) ? 'deva' : 'latin';
      const last = out[out.length - 1];
      if (last && last.script === script) last.text += ch;
      else out.push({ script, text: ch });
    }
    return out;
  }

  /** Shapes one line: glyphs with x positions in px (relative to the line start) and total width. */
  function shapeLine(text, size, weight) {
    const glyphs = [];
    let x = 0;
    for (const run of runs(text)) {
      const f = fonts[`${run.script}-${weight}`];
      const scale = size / f.upem;
      const buffer = new hb.Buffer();
      buffer.addText(run.text);
      buffer.guessSegmentProperties();
      hb.shape(f.font, buffer);
      const infos = buffer.getGlyphInfos();
      const pos = buffer.getGlyphPositions();
      infos.forEach((g, i) => {
        glyphs.push({ f, gid: g.codepoint, x: x + pos[i].xOffset * scale, y: -pos[i].yOffset * scale, scale });
        x += pos[i].xAdvance * scale;
      });
    }
    return { glyphs, width: x };
  }

  const measure = (text, size, weight) => shapeLine(text, size, weight).width;

  /** Greedy word wrap with real advances; the last line ends in an ellipsis when cut. */
  function wrap(text, size, weight, maxWidth, maxLines) {
    const words = String(text).replace(/\s+/g, ' ').trim().split(' ').filter(Boolean);
    const lines = [];
    let cur = '';
    let used = 0;
    for (const w of words) {
      const next = cur ? `${cur} ${w}` : w;
      if (!cur || measure(next, size, weight) <= maxWidth) {
        cur = next;
        used++;
        continue;
      }
      lines.push(cur);
      cur = '';
      if (lines.length === maxLines) break;
      cur = w;
      used++;
    }
    if (cur) lines.push(cur);
    const cut = used < words.length;
    let last = lines[lines.length - 1] ?? '';
    if (cut || measure(last, size, weight) > maxWidth) {
      while (last && measure(`${last}…`, size, weight) > maxWidth) last = [...last].slice(0, -1).join('');
      lines[lines.length - 1] = `${last.replace(/[\s,.:;·|–-]+$/u, '')}…`;
    }
    return lines;
  }

  /** SVG for one line of text as glyph outlines. anchor: 'start' | 'end'. */
  function textSvg(text, { x, y, size, weight = 'regular', fill, anchor = 'start' }) {
    const { glyphs, width } = shapeLine(text, size, weight);
    const x0 = anchor === 'end' ? x - width : x;
    const parts = glyphs.map((g) => {
      let d = g.f.paths.get(g.gid);
      if (d === undefined) {
        d = g.f.font.glyphToPath(g.gid);
        g.f.paths.set(g.gid, d);
      }
      if (!d) return '';
      return `<path transform="translate(${num(x0 + g.x)} ${num(y + g.y)}) scale(${g.scale.toFixed(6)} ${(-g.scale).toFixed(6)})" d="${d}"/>`;
    });
    return `<g fill="${fill}" aria-label="${esc(text)}">${parts.join('')}</g>`;
  }

  /**
   * @param {object} o
   * @param {{bg:string, fg:string, muted:string, accent:string, accentSoft:string, band:string, bandFg:string}} o.colors
   * @param {string} o.brand          Name next to the logo (app name or trends site name).
   * @param {string} [o.logoSvg]      Logo mark as SVG source (embedded as a data URI), optional.
   * @param {string} [o.kicker]       Small line above the title (section, city, ...).
   * @param {string} o.title          Main text, wrapped to at most 3 lines.
   * @param {string} [o.detail]       Supporting text under the title, at most 2 lines.
   * @param {string} o.footer         Left text in the bottom band (usually the domain).
   * @param {string} [o.footerRight]  Right text in the bottom band (call to action).
   */
  function svg(o) {
    const c = o.colors;
    const x = 72;
    const width = OG_WIDTH - 2 * x;
    let y = 64;
    const parts = [
      `<rect width="${OG_WIDTH}" height="${OG_HEIGHT}" fill="${c.bg}"/>`,
      `<circle cx="1150" cy="10" r="210" fill="${c.accentSoft}"/>`,
      `<rect x="0" y="0" width="16" height="${OG_HEIGHT}" fill="${c.accent}"/>`,
    ];

    let brandX = x;
    if (o.logoSvg) {
      const uri = `data:image/svg+xml;base64,${Buffer.from(o.logoSvg).toString('base64')}`;
      parts.push(`<image href="${uri}" x="${x}" y="${y - 6}" width="76" height="76"/>`);
      brandX = x + 92;
    }
    parts.push(textSvg(o.brand, { x: brandX, y: y + 46, size: 36, weight: 'bold', fill: c.fg }));
    y += 140;

    if (o.kicker) {
      const [k] = wrap(o.kicker, 30, 'bold', width - 140, 1);
      parts.push(textSvg(k, { x, y, size: 30, weight: 'bold', fill: c.accent }));
      y += 26;
    }

    let size = 62;
    let lines = wrap(o.title, size, 'bold', width, 3);
    if (lines.length === 3) {
      size = 54;
      lines = wrap(o.title, size, 'bold', width, 3);
    }
    const deva = DEVA.test(o.title);
    const lh = Math.round(size * (deva ? 1.36 : 1.18));
    y += lh - 6;
    for (const line of lines) {
      parts.push(textSvg(line, { x, y, size, weight: 'bold', fill: c.fg }));
      y += lh;
    }

    if (o.detail) {
      y += 6;
      // Baselines must stay ~20px above the bottom band (descenders).
      const room = Math.max(1, Math.min(2, Math.floor((OG_HEIGHT - 84 - 20 - y) / 44) + 1));
      for (const line of wrap(o.detail, 30, 'regular', width, room)) {
        parts.push(textSvg(line, { x, y, size: 30, fill: c.muted }));
        y += 44;
      }
    }

    const bandY = OG_HEIGHT - 84;
    parts.push(`<rect x="0" y="${bandY}" width="${OG_WIDTH}" height="84" fill="${c.band}"/>`);
    parts.push(textSvg(o.footer, { x, y: bandY + 53, size: 30, weight: 'bold', fill: c.bandFg }));
    if (o.footerRight) {
      const room = OG_WIDTH - 2 * x - measure(o.footer, 30, 'bold') - 48;
      const [r] = wrap(o.footerRight, 28, 'regular', room, 1);
      parts.push(textSvg(r, { x: OG_WIDTH - x, y: bandY + 53, size: 28, fill: c.bandFg, anchor: 'end' }));
    }
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${OG_WIDTH}" height="${OG_HEIGHT}" viewBox="0 0 ${OG_WIDTH} ${OG_HEIGHT}">${parts.join('')}</svg>`;
  }

  /** Renders the template to a PNG buffer. */
  function png(o) {
    const resvg = new Resvg(svg(o), {
      fitTo: { mode: 'width', value: OG_WIDTH },
      // Only for text inside an embedded logo SVG; template text is already outlines.
      font: { fontFiles: [path.join(fontDir, FONTS.latin.bold), path.join(fontDir, FONTS.latin.regular)], loadSystemFonts: false, defaultFontFamily: 'Inter' },
    });
    return resvg.render().asPng();
  }

  return { svg, png, wrap, measure };
}
