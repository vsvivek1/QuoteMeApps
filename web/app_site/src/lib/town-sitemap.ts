/**
 * Sitemap entries for the town and state pages: every indexable page in every language,
 * each listing all of its language versions (hreflang, including itself and x-default).
 */
import { abs } from './site';
import type { UrlEntry } from './sitemap';
import { statePath, statesWithTowns, townPages } from './towns';

const withAlts = (paths: { en: string; local: string | null; hreflang: string | null }, englishTag: string): UrlEntry[] => {
  if (!paths.local || !paths.hreflang) return [{ loc: abs(paths.en) }];
  const alternates = [
    { hreflang: englishTag, href: abs(paths.en) },
    { hreflang: paths.hreflang, href: abs(paths.local) },
    { hreflang: 'x-default', href: abs(paths.en) },
  ];
  return [{ loc: abs(paths.en), alternates }, { loc: abs(paths.local), alternates }];
};

export async function townSitemapEntries(englishTag: string): Promise<UrlEntry[]> {
  const out: UrlEntry[] = [];
  for (const p of (await townPages()).values()) {
    if (!p.indexable) continue;
    out.push(...withAlts({ en: p.path, local: p.localPath, hreflang: p.town.state.locale?.hreflang ?? null }, englishTag));
  }
  return out;
}

export function stateSitemapEntries(englishTag: string): UrlEntry[] {
  return statesWithTowns().flatMap((s) =>
    withAlts({ en: statePath(s), local: s.locale ? statePath(s, s.locale) : null, hreflang: s.locale?.hreflang ?? null }, englishTag),
  );
}
