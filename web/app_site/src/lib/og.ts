/**
 * Per-page Open Graph images (brief 21.9 "Open Graph images generated per page
 * from the branding/ templates"). One 1200x630 PNG per page that people share:
 * home and the other translated marketing pages (every locale), price pages,
 * city hubs, buying guides and seller directory pages. Rendered at build time
 * by src/pages/og/[...key].png.ts with web/shared/og.mjs; brand colours and the
 * logo come from branding/<country>/. Pages not listed here (legal, contact,
 * noindex rows of live data) use branding/<country>/web/og_image_1200x630.png.
 *
 * Base.astro looks the page path up with ogImageFor(), so a page gets its own
 * image exactly when one is generated.
 */
import fs from 'node:fs';
import path from 'node:path';
import { Resvg } from '@resvg/resvg-js';
import * as hb from 'harfbuzzjs';
import { createOgRenderer } from '../../../shared/og.mjs';
import { REPO_ROOT, WEB_ROOT, brandColors, country, money, site } from './site';
import { cityHubs, loadGuides, loadSellers, loadSeo, responseTimeText, sellerCities } from './seo';
import { LOCALES, TRANSLATED, localePath, translator } from './i18n';
import { joinList, statePath, statesWithTowns, townPages, townsInState } from './towns';

export interface OgSpec {
  kicker?: string;
  title: string;
  detail?: string;
  footerRight: string;
}

const DEFAULT_OG = '/brand/og_image_1200x630.png';

/** '/' -> 'home', '/quotes/dallas' -> 'quotes/dallas'. */
const keyOf = (p: string) => (p === '/' ? 'home' : p.replace(/^\/+/, ''));
export const ogPath = (key: string) => `/og/${key}.png`;

const lc = (s: string) => (/^[A-Z]{2}/.test(s) ? s : s.charAt(0).toLowerCase() + s.slice(1));
const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

let cache: Promise<Map<string, OgSpec>> | null = null;

/** Every page that gets its own OG image, keyed by image key. */
export function ogEntries(): Promise<Map<string, OgSpec>> {
  cache ??= (async () => {
    const out = new Map<string, OgSpec>();
    const add = (pagePath: string, spec: OgSpec) => out.set(keyOf(pagePath), spec);
    const en = translator(LOCALES[0]);
    const cta = en.t('layout.ogCta');

    for (const locale of LOCALES) {
      const tr = translator(locale);
      const footerRight = tr.t('layout.ogCta');
      const page = (base: (typeof TRANSLATED)[number], key: string, title: string) =>
        add(localePath(locale, base), { kicker: tr.t(`${key}.og.kicker`), title, detail: tr.t(`${key}.og.detail`), footerRight });
      page('/', 'home', tr.raw<string[]>('home.h1').join(' '));
      page('/sellers', 'sellers', tr.t('sellers.h1'));
      page('/waitlist', 'waitlist', tr.t('waitlist.h1'));
      page('/about', 'about', tr.t('about.h1'));
    }

    // Town pages: one image per state (shared by its town pages and its state page), plus
    // their own image for the hand-curated towns. Not one per town: ~24,000 PNGs would not fit the build.
    const pages = await townPages();
    for (const st of statesWithTowns()) {
      const n = townsInState(st).length;
      add(statePath(st), {
        kicker: `${st.name}, ${en.fact<string>('countryShort')}`,
        title: `Post what you want in ${st.name}`,
        detail: `Local sellers in ${plural(n, 'town', 'towns')} send you quotes. Free for buyers.`,
        footerRight: cta,
      });
    }
    for (const tp of pages.values()) {
      if (!tp.town.curated || !tp.indexable) continue;
      add(tp.path, {
        kicker: `${tp.town.name}, ${tp.town.state.name}`,
        title: `Post what you want in ${tp.town.name}`,
        detail: tp.town.areas.length >= 3
          ? `Local sellers in ${joinList(tp.town.areas.slice(0, 3))} and more send you quotes. Free for buyers.`
          : `Local sellers in ${tp.town.name} send you quotes. Free for buyers.`,
        footerRight: cta,
      });
    }

    // Live data: only pages people can find (indexable). Fixture builds: every page, to exercise the template.
    const { data } = await loadSeo();
    const show = (status: string) => status === 'indexable' || Boolean(data.fixture);

    for (const hub of await cityHubs()) {
      if (!hub.indexable && !data.fixture) continue;
      const shown = hub.pages.filter((p) => show(p.status));
      add(`/quotes/${hub.city.slug}`, {
        kicker: `Local prices · ${hub.city.name}, ${hub.city.state}`,
        title: `Prices and quotes in ${hub.city.name}`,
        detail: `${plural(shown.length, 'category', 'categories')} with real quotes from local sellers on ${site.appName}.`,
        footerRight: cta,
      });
      for (const p of hub.pages) {
        if (!show(p.status)) continue;
        const cat = lc(p.category.name);
        const price = p.showPrices && p.data.price ? p.data.price : null;
        const unit = p.category.unit ? ` ${p.category.unit}` : '';
        add(p.path, {
          kicker: `Local prices · ${p.city.name}, ${p.city.state}`,
          title: p.category.kind === 'service' ? `Quotes for ${cat} in ${p.city.name}` : `Prices for ${cat} in ${p.city.name}`,
          detail: price
            ? `Median quote ${money(price.median)}${unit} · typical range ${money(price.p25)} to ${money(price.p75)} · ${plural(p.data.quotes_window, 'quote', 'quotes')} from ${plural(p.data.sellers_window, 'seller', 'sellers')}`
            : `Get quotes for ${cat} from local sellers in ${p.city.name}.`,
          footerRight: cta,
        });
      }
    }

    for (const g of await loadGuides()) {
      if (!show(g.status)) continue;
      const price = g.pricePage?.data.price;
      add(g.path, {
        kicker: `Buying guide · ${g.category.name}`,
        title: g.data.title,
        detail: price && g.city ? `Median quote in ${g.city.name}: ${money(price.median)}, from real quotes on ${site.appName}.` : g.data.description || undefined,
        footerRight: cta,
      });
    }

    for (const c of await sellerCities()) {
      if (c.indexable || data.fixture) {
        add(c.path, {
          kicker: 'Local sellers',
          title: `Local sellers in ${c.name}`,
          detail: `${plural(c.sellers.length, 'business', 'businesses')} on ${site.appName}: what they sell, ratings and response times.`,
          footerRight: cta,
        });
      }
    }
    for (const s of await loadSellers()) {
      if (!show(s.status)) continue;
      const d = s.data;
      const facts = [
        s.categories.slice(0, 3).map((c) => c.name).join(', '),
        d.rating != null && d.rating_count ? `Rated ${d.rating.toFixed(1)} from ${plural(d.rating_count, 'review', 'reviews')}` : '',
        responseTimeText(d.median_response_hours) ? `Typical reply: ${responseTimeText(d.median_response_hours)!.toLowerCase()}` : '',
      ].filter(Boolean);
      add(s.path, {
        kicker: `${d.verified ? 'Verified seller' : 'Local seller'} · ${s.cityName}`,
        title: d.name,
        detail: facts.join(' · ') || undefined,
        footerRight: `Get a quote from ${d.name}`,
      });
    }
    return out;
  })();
  return cache;
}

/** Absolute-path og:image for a page, or the default branding image. */
export async function ogImageFor(pagePath: string): Promise<{ src: string; generated: boolean }> {
  const key = keyOf(pagePath);
  return (await ogEntries()).has(key) ? { src: ogPath(key), generated: true } : { src: DEFAULT_OG, generated: false };
}

let renderer: ReturnType<typeof createOgRenderer> | null = null;

export function renderOg(spec: OgSpec): Buffer {
  renderer ??= createOgRenderer({ hb, Resvg, fontDir: path.join(WEB_ROOT, 'shared', 'fonts') });
  const { light } = brandColors();
  return renderer.png({
    colors: {
      bg: light.surface,
      fg: light.onSurface,
      muted: light.onSurfaceVariant,
      accent: light.primary,
      accentSoft: light.primaryContainer,
      band: light.primary,
      bandFg: light.onPrimary,
    },
    brand: site.appName,
    logoSvg: fs.readFileSync(path.join(REPO_ROOT, 'branding', country, 'logo', 'logo_mark.svg'), 'utf8'),
    footer: site.domain,
    ...spec,
  });
}
