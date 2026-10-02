import { getCollection, type CollectionEntry } from 'astro:content';
import { country, site, warnOnce } from './site';

export type LegalEntry = CollectionEntry<'legal_usa'> | CollectionEntry<'legal_india'>;

export async function legalPages(): Promise<LegalEntry[]> {
  const entries = country === 'usa' ? await getCollection('legal_usa') : await getCollection('legal_india');
  return [...entries].sort((a, b) => a.data.order - b.data.order);
}

const DOMAIN_PLACEHOLDERS = /\{\{\s*(USA|INDIA)_WEB_DOMAIN\s*\}\}/g;
const ANY_PLACEHOLDER = /\{\{\s*([A-Z0-9_]+)\s*\}\}/g;

/**
 * Rendered HTML for a legal page. The web domain placeholder is filled from the
 * site URL; any other pending {{PLACEHOLDER}} (company address, emails...) is
 * reported, and fails the build when LEGAL_STRICT=1 (use for production).
 */
export function legalHtml(entry: LegalEntry): string {
  const html = (entry.rendered?.html ?? '').replace(DOMAIN_PLACEHOLDERS, site.domain);
  const pending = [...new Set([...html.matchAll(ANY_PLACEHOLDER)].map((m) => m[1]))];
  if (pending.length) {
    const msg = `legal/${entry.data.slug}: pending placeholders ${pending.join(', ')} (fill legal/config.json and rerun legal/build.py)`;
    if (site.legalStrict) throw new Error(msg);
    warnOnce(msg);
  }
  return html;
}
