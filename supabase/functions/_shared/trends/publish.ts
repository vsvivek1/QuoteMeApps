// Publishing helpers for trends-publish: the final article JSON (web/trends_site format),
// noindex rules, gate 6 selection with the caps, and the bucket index.
//
// Bucket layout (trends-public, public read):
//   index.json             { version, generated_at, settings: {paused, paused_at, per_day}, articles: [...] }
//   articles/<slug>.json   one article
import { capCheck } from "./ramp.ts";
import { perDayCap } from "./settings.ts";
import type { Article, Country, Draft, Settings } from "./types.ts";

export const INDEX_PATH = "index.json";
export const articlePath = (slug: string) => `articles/${slug}.json`;

/** Why a published article should be noindex (null = indexable). */
export function noindexReason(
  d: Pick<Draft, "superseded_by" | "visits_14d_after_end" | "noindex_reason" | "status">,
  trendEndedAt: string | null,
  now: Date,
  s: Settings,
): string | null {
  if (d.superseded_by) return `superseded by ${d.superseded_by}`;
  if (
    trendEndedAt && now.getTime() - Date.parse(trendEndedAt) >= 14 * 86_400_000 &&
    typeof d.visits_14d_after_end === "number" && d.visits_14d_after_end < s.gates.noindex_min_visits_14d
  ) {
    return `traffic died (${d.visits_14d_after_end} visits in 14 days after the trend)`;
  }
  if (
    d.status === "noindex" && d.noindex_reason && !d.noindex_reason.startsWith("superseded") &&
    !d.noindex_reason.startsWith("traffic died")
  ) {
    return d.noindex_reason; // manual
  }
  return null;
}

/** The JSON written to the bucket: the draft article plus the row's publishing state. */
export function finalArticle(
  d: Pick<Draft, "article" | "slug" | "published_at" | "superseded_by" | "visits_14d_after_end" | "velocity">,
  opts: { trendEndedAt: string | null; noindex: boolean; now: Date },
): Article {
  const a = structuredClone(d.article!) as Article;
  a.slug = d.slug!;
  a.published_at = d.published_at ?? opts.now.toISOString();
  a.updated_at = a.updated_at && Date.parse(a.updated_at) > Date.parse(a.published_at)
    ? a.updated_at
    : a.published_at;
  a.superseded_by = d.superseded_by ?? null;
  a.trend_ended_at = opts.trendEndedAt;
  a.traffic = { visits_14d_after_end: d.visits_14d_after_end ?? null };
  a.noindex = opts.noindex || undefined;
  if (a.noindex === undefined) delete a.noindex;
  a.updates = a.updates ?? [];
  a.corrections = a.corrections ?? [];
  return a;
}

export interface PublishDecision {
  id: string;
  decision: "publish" | "capped" | "expired" | "paused";
  reason: string | null;
}

/**
 * Gate 6 at publish time. Highest velocity first; each publish counts against the daily and
 * hourly caps of its country; queued drafts older than caps.queue_ttl_hours expire (stale news).
 */
export function selectForPublish(
  queued: Pick<Draft, "id" | "country" | "velocity" | "created_at">[],
  publishedAt: Record<Country, string[]>,
  s: Settings,
  now: Date,
): PublishDecision[] {
  const times: Record<Country, string[]> = {
    usa: [...(publishedAt.usa ?? [])],
    india: [...(publishedAt.india ?? [])],
  };
  const order = [...queued].sort((a, b) =>
    b.velocity - a.velocity || Date.parse(a.created_at) - Date.parse(b.created_at)
  );
  const out: PublishDecision[] = [];
  for (const d of order) {
    if (now.getTime() - Date.parse(d.created_at) > s.caps.queue_ttl_hours * 3_600_000) {
      out.push({ id: d.id, decision: "expired", reason: `queued for more than ${s.caps.queue_ttl_hours} h` });
      continue;
    }
    const c = capCheck(d.country, now, times[d.country], s);
    if (!c.allowed) {
      out.push({ id: d.id, decision: s.publishing.paused ? "paused" : "capped", reason: c.reason });
      continue;
    }
    times[d.country].push(now.toISOString());
    out.push({ id: d.id, decision: "publish", reason: null });
  }
  return out;
}

export interface IndexEntry {
  slug: string;
  path: string;
  country: Country;
  published_at: string;
  updated_at: string;
  noindex: boolean;
}

export interface TrendsIndex {
  version: 1;
  generated_at: string;
  settings: { paused: boolean; paused_at: string | null; per_day: Record<Country, number> };
  articles: IndexEntry[];
}

export function buildIndex(entries: IndexEntry[], s: Settings, now: Date): TrendsIndex {
  const seen = new Set<string>();
  const articles = [...entries]
    .filter((e) => /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(e.slug) && !seen.has(e.slug) && seen.add(e.slug))
    .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at) || a.slug.localeCompare(b.slug));
  return {
    version: 1,
    generated_at: now.toISOString(),
    settings: {
      paused: s.publishing.paused,
      paused_at: s.publishing.paused ? s.publishing.paused_at ?? now.toISOString() : null,
      per_day: { usa: perDayCap(s, "usa"), india: perDayCap(s, "india") },
    },
    articles,
  };
}
