/**
 * Build-time site configuration. Everything country-specific comes from
 * SITE_COUNTRY (usa | india) plus optional env overrides. No secrets live here:
 * every value is public (it ends up in HTML or /.well-known files).
 *
 * Read with process.env because the site is fully static: pages are rendered
 * once in Node at build time, never in the browser.
 */
import fs from 'node:fs';
import path from 'node:path';

export type CountryCode = 'usa' | 'india';

interface CountryFacts {
  appName: string;
  company: string;
  defaultDomain: string;
  packageId: string;
  bundleId: string;
  currency: string;
  locale: string;
  postalLabel: string;
  postalExample: string;
  storeRegion: string;
  appStoreSlug: string;
  exampleRequests: string[];
  privacyLaw: string;
  sellerIds: string;
  smsOptIn: 'whatsapp' | 'none';
  timezone: string;
}

const COUNTRIES: Record<CountryCode, CountryFacts> = {
  usa: {
    appName: 'I Want USA',
    company: 'Calecute Technologies LLC',
    defaultDomain: 'iwantusa.app',
    packageId: 'com.calecute.iwant.usa',
    bundleId: 'com.calecute.iwant.usa',
    currency: 'USD',
    locale: 'en-US',
    postalLabel: 'ZIP code',
    postalExample: '75201',
    storeRegion: 'us',
    appStoreSlug: 'i-want-usa',
    exampleRequests: [
      'Samsung 28 cu ft French-door refrigerator, delivered to 75201 by Friday',
      'AC tune-up for 2 units in Dallas this week',
      '100 printed T-shirts for a company event',
    ],
    privacyLaw: 'CCPA/CPRA',
    sellerIds: 'EIN or state licence',
    smsOptIn: 'none',
    timezone: 'America/New_York',
  },
  india: {
    appName: 'I Want India',
    company: 'Calecute Technologies (OPC) Private Limited',
    defaultDomain: 'iwantindia.app',
    packageId: 'com.calecute.iwant.india',
    bundleId: 'com.calecute.iwant.india',
    currency: 'INR',
    locale: 'en-IN',
    postalLabel: 'PIN code',
    postalExample: '560034',
    storeRegion: 'in',
    appStoreSlug: 'i-want-india',
    exampleRequests: [
      'Samsung 300L double-door refrigerator, delivered to 560034 by Friday',
      'AC repair, 2 split units in Koramangala',
      '100 printed T-shirts for a college fest',
    ],
    privacyLaw: 'DPDP Act 2023',
    sellerIds: 'GSTIN (Udyam optional)',
    smsOptIn: 'whatsapp',
    timezone: 'Asia/Kolkata',
  },
};

const env = (key: string): string => (process.env[key] ?? '').trim();
const list = (key: string): string[] =>
  env(key)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

function resolveCountry(): CountryCode {
  const raw = env('SITE_COUNTRY').toLowerCase();
  if (raw === 'usa' || raw === 'india') return raw;
  throw new Error(
    `SITE_COUNTRY must be "usa" or "india" (got "${raw || 'unset'}"). ` +
      'Use `npm run build:usa` / `npm run build:india` locally; set it per Vercel project.',
  );
}

export const PLACEHOLDER = {
  sha256: 'REPLACE_WITH_SHA256_CERT_FINGERPRINT',
  teamId: 'REPLACE_WITH_APPLE_TEAM_ID',
  turnstile: '',
  formsEndpoint: '',
};

export const country: CountryCode = resolveCountry();
const facts = COUNTRIES[country];

/** Repo root: the build runs from web/app_site, so it is two levels up. */
export const REPO_ROOT = env('REPO_ROOT') || path.resolve(process.cwd(), '../..');
export const WEB_ROOT = path.join(REPO_ROOT, 'web');

const siteUrl = (env('SITE_URL') || `https://${facts.defaultDomain}`).replace(/\/+$/, '');
const androidPackage = env('ANDROID_PACKAGE') || facts.packageId;
const iosBundle = env('IOS_BUNDLE_ID') || facts.bundleId;
const appleAppId = env('APPLE_APP_ID'); // numeric App Store id, empty until the app is live

export const site = {
  country,
  ...facts,
  url: siteUrl,
  domain: new URL(siteUrl).host,
  android: {
    packages: [androidPackage, ...list('ANDROID_EXTRA_PACKAGES')],
    sha256: list('ANDROID_SHA256_FINGERPRINTS'),
  },
  ios: {
    bundleIds: [iosBundle, ...list('IOS_EXTRA_BUNDLE_IDS')],
    teamId: env('APPLE_TEAM_ID'),
    appId: /^\d+$/.test(appleAppId) ? appleAppId : '',
  },
  playStoreUrl:
    env('PLAY_STORE_URL') || `https://play.google.com/store/apps/details?id=${androidPackage}`,
  appStoreUrl:
    env('APP_STORE_URL') ||
    `https://apps.apple.com/${facts.storeRegion}/app/${facts.appStoreSlug}/id${appleAppId || '0000000000'}`,
  appStoreLive: Boolean(env('APP_STORE_URL') || /^\d+$/.test(appleAppId)),
  playStoreLive: env('PLAY_STORE_LIVE') === '1',
  turnstileSiteKey: env('PUBLIC_TURNSTILE_SITE_KEY'),
  formsEndpoint: env('FORMS_ENDPOINT'),
  supportEmail: env('SUPPORT_EMAIL'),
  legalStrict: env('LEGAL_STRICT') === '1',
  buildTime: new Date(),
};

export const formsEnabled = Boolean(site.turnstileSiteKey && /^https:\/\//.test(site.formsEndpoint));

/** Play Store link carrying an install referrer (Play Install Referrer API reads it). */
export function playLink(campaign: string, source = 'website', medium = 'web'): string {
  const ref = `utm_source=${source}&utm_medium=${medium}&utm_campaign=${campaign}`;
  const u = new URL(site.playStoreUrl);
  u.searchParams.set('referrer', ref);
  return u.toString();
}

/** App Store link with campaign token (App Store Connect app analytics). */
export function appStoreLink(campaign: string): string {
  const u = new URL(site.appStoreUrl);
  u.searchParams.set('ct', campaign.slice(0, 40));
  return u.toString();
}

export function abs(p: string): string {
  return site.url + (p.startsWith('/') ? p : `/${p}`);
}

export function readJson<T>(file: string): T {
  return JSON.parse(fs.readFileSync(file, 'utf8')) as T;
}

/** Brand colours from branding/<country>/colors.json (single source of truth). */
export function brandColors(): { light: Record<string, string>; dark: Record<string, string> } {
  return readJson(path.join(REPO_ROOT, 'branding', country, 'colors.json'));
}

const warned = new Set<string>();
export function warnOnce(msg: string): void {
  if (warned.has(msg)) return;
  warned.add(msg);
  console.warn(`[app_site:${country}] WARNING ${msg}`);
}

export function money(amount: number): string {
  return new Intl.NumberFormat(site.locale, {
    style: 'currency',
    currency: site.currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(d: string | Date, opts: Intl.DateTimeFormatOptions = { dateStyle: 'long' }): string {
  return new Intl.DateTimeFormat(site.locale, { ...opts, timeZone: site.timezone }).format(new Date(d));
}
