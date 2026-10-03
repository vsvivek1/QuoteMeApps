/**
 * Translated marketing pages (brief 21.9 "hreflang between English and
 * Hindi/Spanish versions"). India gets Hindi (hi-IN) and the USA gets Spanish
 * (es-US) for the static pages in TRANSLATED only; price pages, guides, seller
 * profiles and legal pages stay English (no machine-translated thin pages).
 * Strings live in src/i18n/<locale>.json; missing keys fall back to en.json.
 *
 * Town and state pages (lib/towns.ts) also come in the state's main language on
 * the India site (Malayalam for Kerala, Tamil for Tamil Nadu, ...; Hindi for the
 * Hindi-speaking states) and in Spanish on the USA site. Those extra languages
 * (TOWN_LOCALES) have only the fixed template strings of those pages, the site
 * chrome and the town picker; their pages link to English everywhere else.
 */
import en from '../i18n/en.json';
import hi from '../i18n/hi-IN.json';
import es from '../i18n/es-US.json';
import ml from '../i18n/ml.json';
import ta from '../i18n/ta.json';
import te from '../i18n/te.json';
import kn from '../i18n/kn.json';
import mr from '../i18n/mr.json';
import bn from '../i18n/bn.json';
import gu from '../i18n/gu.json';
import pa from '../i18n/pa.json';
import or from '../i18n/or.json';
import as from '../i18n/as.json';
import ne from '../i18n/ne.json';
import { site } from './site';

export type LocaleCode = 'en' | 'hi-IN' | 'es-US' | 'ml' | 'ta' | 'te' | 'kn' | 'mr' | 'bn' | 'gu' | 'pa' | 'or' | 'as' | 'ne';

export interface Locale {
  code: LocaleCode;
  /** BCP 47 tag for <html lang> and hreflang. */
  hreflang: string;
  /** URL prefix: '' for English, '/hi' or '/es'. */
  prefix: string;
  /** Path segment for getStaticPaths ('hi' | 'es'); empty for English. */
  segment: string;
  /** Language name in that language, for the switcher. */
  name: string;
  /** Has the translated marketing pages (TRANSLATED); false for town-page-only languages. */
  pages: boolean;
}

type Dict = Record<string, unknown>;

const DICTS: Record<LocaleCode, Dict> = { en, 'hi-IN': hi, 'es-US': es, ml, ta, te, kn, mr, bn, gu, pa, or, as, ne };

/** Static marketing pages that have translations (English paths). */
export const TRANSLATED = ['/', '/sellers', '/waitlist', '/about'] as const;

const ENGLISH: Locale = { code: 'en', hreflang: site.locale, prefix: '', segment: '', name: en.language, pages: true };
const SECOND: Locale =
  site.country === 'india'
    ? { code: 'hi-IN', hreflang: 'hi-IN', prefix: '/hi', segment: 'hi', name: hi.language, pages: true }
    : { code: 'es-US', hreflang: 'es-US', prefix: '/es', segment: 'es', name: es.language, pages: true };

/** Locales of this country's site: English first. */
export const LOCALES: Locale[] = [ENGLISH, SECOND];
export const SECOND_LOCALE = SECOND;

/** India: the other state languages of town pages, keyed by URL segment (= ISO 639-1 code). */
const INDIC: Record<string, Dict> = { ml, ta, te, kn, mr, bn, gu, pa, or, as, ne };
export const TOWN_LOCALES: Locale[] =
  site.country === 'india'
    ? [
        SECOND,
        ...Object.entries(INDIC).map(([code, d]) => ({
          code: code as LocaleCode,
          hreflang: `${code}-IN`,
          prefix: `/${code}`,
          segment: code,
          name: String(d.language),
          pages: false,
        })),
      ]
    : [SECOND];

/** Second language of a state's town pages: 'hi', 'ml', ... (India) or 'es' (USA); null for English only. */
export function townLocale(segment: string | undefined | null): Locale | null {
  if (!segment) return null;
  return TOWN_LOCALES.find((l) => l.segment === segment) ?? null;
}

export function localeBySegment(segment: string | undefined): Locale {
  return LOCALES.find((l) => l.segment === (segment ?? '')) ?? ENGLISH;
}

/** URL of an English path in a locale ('/' -> '/hi', '/sellers' -> '/hi/sellers'). Town-only languages keep English paths. */
export function localePath(locale: Locale, p: string): string {
  if (!locale.prefix || !locale.pages) return p;
  return p === '/' ? locale.prefix : `${locale.prefix}${p}`;
}

/** Strips a locale prefix: '/hi/sellers' -> { locale: hi, base: '/sellers' }. */
export function splitLocale(p: string): { locale: Locale; base: string } {
  for (const l of LOCALES) {
    if (!l.prefix) continue;
    if (p === l.prefix) return { locale: l, base: '/' };
    if (p.startsWith(`${l.prefix}/`)) return { locale: l, base: p.slice(l.prefix.length) };
  }
  return { locale: ENGLISH, base: p };
}

export const isTranslated = (base: string) => (TRANSLATED as readonly string[]).includes(base);

/** hreflang alternates for a page path (empty when the page has no translation). */
export function alternates(p: string): { hreflang: string; path: string; locale: Locale }[] {
  const { base } = splitLocale(p);
  if (!isTranslated(base)) return [];
  return [
    ...LOCALES.map((l) => ({ hreflang: l.hreflang, path: localePath(l, base), locale: l })),
    { hreflang: 'x-default', path: base, locale: ENGLISH },
  ];
}

function lookup(d: Dict, key: string): unknown {
  return key.split('.').reduce<unknown>((o, k) => (o && typeof o === 'object' ? (o as Dict)[k] : undefined), d);
}

/** Facts used in {placeholders}: site.ts values, then en.json facts, then the locale's own facts. */
function facts(code: LocaleCode): Record<string, unknown> {
  const own = (lookup(DICTS[code], `facts.${site.country}`) ?? {}) as Dict;
  const base = (lookup(en, `facts.${site.country}`) ?? {}) as Dict;
  return {
    appName: site.appName,
    company: site.company,
    postalLabel: site.postalLabel,
    sellerIds: site.sellerIds,
    privacyLaw: site.privacyLaw,
    exampleRequests: site.exampleRequests,
    ...base,
    ...own,
  };
}

export function fill(s: string, vars: Record<string, unknown>): string {
  return s.replace(/\{(\w+)\}/g, (m, k) => (vars[k] == null ? m : String(vars[k])));
}

export interface Translator {
  locale: Locale;
  /** Fact value (postalLabel, exampleRequests, ...). */
  fact: <T = string>(key: string) => T;
  /** Plain string with {placeholders} filled. Falls back to English. */
  t: (key: string, vars?: Record<string, unknown>) => string;
  /** Raw value (arrays, objects), falling back to English. */
  raw: <T = unknown>(key: string) => T;
  /** String with **bold**, *italic* and [text](/path) rendered as escaped HTML. */
  rich: (key: string, vars?: Record<string, unknown>) => string;
}

const escHtml = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** Tiny, safe inline markup: input is escaped first; links only to site paths or mailto:. */
export function richText(s: string): string {
  return escHtml(s)
    .replace(/\[([^\]]+)\]\(((?:\/|mailto:)[^)\s]*)\)/g, (_m, text, href) => `<a href="${href}">${text}</a>`)
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>');
}

export function translator(locale: Locale): Translator {
  const vars = facts(locale.code);
  const raw = <T,>(key: string): T => {
    const v = lookup(DICTS[locale.code], key);
    const value = v === undefined || v === '' ? lookup(en, key) : v;
    if (value === undefined) throw new Error(`i18n: missing key "${key}"`);
    return value as T;
  };
  const t = (key: string, extra: Record<string, unknown> = {}) => fill(raw<string>(key), { ...vars, ...extra });
  // Links inside translated text point at English paths; keep them on translated pages when one exists.
  const localise = (html: string) =>
    html.replace(/href="(\/[^"]*)"/g, (m, p: string) => (isTranslated(p) && locale.pages ? `href="${localePath(locale, p)}"` : m));
  return {
    locale,
    fact: <T,>(key: string) => vars[key] as T,
    t,
    raw,
    rich: (key, extra) => localise(richText(t(key, extra))),
  };
}
