// Defaults = the values seeded into trends.trend_settings by migration 20261002001200
// (themselves taken from web/trends_site/data/config.json). The database row wins; the
// defaults only fill keys that are missing (and power dry runs and tests).
import type { Country, Settings } from "./types.ts";

export const DEFAULT_SETTINGS: Settings = {
  pipeline: { enabled: false },
  publishing: { paused: false, paused_at: null, paused_reason: null },
  caps: {
    ramp_levels: [1, 2, 5, 10, 20],
    hard_max_per_day: 20,
    max_per_hour: 3,
    timezones: { usa: "America/New_York", india: "Asia/Kolkata" },
    max_drafts_per_run: 3,
    queue_ttl_hours: 6,
  },
  ramp: {
    usa: { level: 0, changed_at: null },
    india: { level: 0, changed_at: null },
    min_days_between_steps: 30,
    auto_step_up: false,
    health: {
      max_age_days: 7,
      min_indexed_share: 0.6,
      max_click_drop: 0.3,
      max_sc_warnings: 0,
      max_error_reports_24h: 5,
    },
  },
  gates: {
    min_sources: 2,
    max_similarity: 0.2,
    shingle_words: 6,
    max_quote_words: 25,
    min_words: 250,
    min_section_words: 15,
    max_perspective_ratio: 1.5,
    noindex_min_visits_14d: 20,
    max_rewrites: 1,
  },
  detection: {
    fire_threshold: 60,
    min_signals: 3,
    cluster_similarity: 0.5,
    velocity_window_minutes: 60,
    baseline_hours: 6,
    topic_ttl_hours: 48,
    merge_window_days: 7,
    end_velocity: 10,
    end_after_hours: 6,
    update_min_interval_minutes: 60,
    max_updates: 10,
    source_weights: { google_trends: 3, google_news: 1, reddit: 1 },
    non_publisher_domains: [
      "news.google.com",
      "trends.google.com",
      "google.com",
      "reddit.com",
      "redd.it",
      "x.com",
      "twitter.com",
      "facebook.com",
      "youtube.com",
      "instagram.com",
      "msn.com",
      "yahoo.com",
    ],
  },
  sensitive_tags: [
    "religion",
    "caste",
    "communal",
    "ethnic-conflict",
    "death",
    "deaths",
    "disaster-casualties",
    "crime",
    "health",
    "medical",
    "election",
    "elections",
    "politics",
    "legal-case",
    "court",
    "finance-advice",
    "markets",
    "minors",
    "children",
    "private-individual",
  ],
  sensitive_keywords: [
    "killed",
    "dead",
    "death",
    "deaths",
    "died",
    "murder",
    "rape",
    "assault",
    "riot",
    "riots",
    "communal",
    "caste",
    "religious",
    "mosque",
    "temple",
    "church",
    "gurdwara",
    "election",
    "elections",
    "poll",
    "vote",
    "voting",
    "minister",
    "senator",
    "congressman",
    "party",
    "court",
    "lawsuit",
    "arrested",
    "police",
    "vaccine",
    "disease",
    "outbreak",
    "cancer",
    "stock tips",
    "invest now",
    "crypto",
    "child",
    "children",
    "minor",
    "suicide",
    "terror",
    "shooting",
  ],
  banned_perspective_terms: [
    "left",
    "right",
    "left-wing",
    "right-wing",
    "liberal",
    "conservative",
    "communist",
    "capitalist",
    "socialist",
    "progressive",
    "democrat",
    "republican",
    "bjp",
    "congress",
    "aap",
    "hindu",
    "muslim",
    "christian",
    "sikh",
    "secular",
  ],
  app_links: [],
  app_hosts: { usa: "iwantusa.app", india: "iwantindia.app" },
};

type Obj = Record<string, unknown>;
const isObj = (v: unknown): v is Obj => !!v && typeof v === "object" && !Array.isArray(v);

function merge<T>(base: T, over: unknown): T {
  if (!isObj(base) || !isObj(over)) return (over === undefined || over === null ? base : over) as T;
  const out: Obj = { ...(base as Obj) };
  for (const [k, v] of Object.entries(over)) out[k] = k in out ? merge(out[k], v) : v;
  return out as T;
}

/** Builds Settings from trend_settings rows ({key, value}). */
export function settingsFromRows(rows: { key: string; value: unknown }[]): Settings {
  let s: Settings = structuredClone(DEFAULT_SETTINGS);
  for (const r of rows) {
    if (r.key in s) s = { ...s, [r.key]: merge((s as unknown as Obj)[r.key], r.value) } as Settings;
  }
  return s;
}

/** Daily cap of a country at its ramp level (ramp_levels[level], never above hard_max_per_day). */
export function perDayCap(s: Settings, country: Country): number {
  const levels = s.caps.ramp_levels;
  const lvl = Math.max(0, Math.min(s.ramp[country]?.level ?? 0, levels.length - 1));
  return Math.min(levels[lvl] ?? 1, s.caps.hard_max_per_day);
}
