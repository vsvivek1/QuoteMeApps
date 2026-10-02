/**
 * Build-time configuration for the trends news site (brief Section 21.10).
 * Separate domain and brand from the apps on purpose: no app branding or app
 * links in the header/footer; apps are linked only from relevant articles.
 * All values are public; no secrets.
 */
import path from 'node:path';

const env = (key: string): string => (process.env[key] ?? '').trim();

export const REPO_ROOT = env('REPO_ROOT') || path.resolve(process.cwd(), '../..');
export const WEB_ROOT = path.join(REPO_ROOT, 'web');

const url = (env('SITE_URL') || 'https://trends-site.example').replace(/\/+$/, '');

export const site = {
  url,
  domain: new URL(url).host,
  /** Working name; final name depends on which domain is registered. */
  name: env('SITE_NAME') || "What's Happening",
  editorName: env('EDITOR_NAME') || '{{EDITOR_NAME}}',
  editorEmail: env('EDITOR_EMAIL') || '',
  publishers: {
    usa: 'Calecute Technologies LLC',
    india: 'Calecute Technologies (OPC) Private Limited',
  } as const,
  dataDir: path.resolve(process.cwd(), env('TRENDS_DATA_DIR') || 'data/articles'),
  configFile: path.resolve(process.cwd(), env('TRENDS_CONFIG') || 'data/config.json'),
  turnstileSiteKey: env('PUBLIC_TURNSTILE_SITE_KEY'),
  formsEndpoint: env('FORMS_ENDPOINT'),
  newsSitemap: env('NEWS_SITEMAP') === '1',
  /** Hosts that article app links may point to (UTM-tagged). */
  appLinkHosts: (env('APP_LINK_HOSTS') || 'iwantusa.app,iwantindia.app')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  /** Override "now" for reproducible builds/tests (ISO date). */
  now: env('BUILD_NOW') ? new Date(env('BUILD_NOW')) : new Date(),
};

export const formsEnabled = Boolean(site.turnstileSiteKey && /^https:\/\//.test(site.formsEndpoint));

export const COUNTRY_LABEL = { usa: 'United States', india: 'India' } as const;
export const COUNTRY_LOCALE = { usa: 'en-US', india: 'en-IN' } as const;

export function abs(p: string): string {
  return site.url + (p.startsWith('/') ? p : `/${p}`);
}

export function formatDateTime(d: string, country: 'usa' | 'india', tz: string): string {
  return new Intl.DateTimeFormat(COUNTRY_LOCALE[country], { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', timeZone: tz, timeZoneName: 'short' }).format(new Date(d));
}

const warned = new Set<string>();
export function warnOnce(msg: string): void {
  if (warned.has(msg)) return;
  warned.add(msg);
  console.warn(`[trends_site] WARNING ${msg}`);
}
