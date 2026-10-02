// Types of the trends pipeline (brief Section 21.10). The article shape is the
// web/trends_site format (see web/trends_site/data/fixtures and src/lib/articles.ts).

export type Country = "usa" | "india";
export type SourceKind = "google_trends" | "google_news" | "reddit";
export type Level = "country" | "state" | "metro";

export interface TrendSource {
  id: number;
  kind: SourceKind;
  country: Country;
  geo: string;
  place_slug: string;
  place_name: string;
  state: string | null;
  level: Level;
  query: string | null;
}

export interface SignalInput {
  source_id: number | null;
  source_kind: SourceKind;
  country: Country;
  place_slug: string;
  place_name: string;
  state: string | null;
  level: Level;
  geo: string | null;
  topic: string;
  norm_title: string;
  dedupe_key: string;
  url: string | null;
  publisher: string | null;
  publisher_domain: string | null;
  citable: boolean;
  snippet: string | null;
  score: number;
  /** Google Trends news items: the trend title they belong to (clusters them directly). */
  cluster_hint?: string;
}

export interface Signal {
  id?: number;
  topic_id?: string | null;
  source_kind: SourceKind;
  topic: string;
  norm_title?: string;
  url: string | null;
  publisher: string | null;
  publisher_domain: string | null;
  citable: boolean;
  snippet: string | null;
  score: number;
  first_seen: string;
  last_seen: string;
}

export type TopicStatus =
  | "watching"
  | "fired"
  | "review"
  | "drafted"
  | "published"
  | "waiting_sources"
  | "dropped"
  | "ended";

export interface Topic {
  id: string;
  country: Country;
  place_slug: string;
  place_name: string;
  state: string | null;
  level: Level;
  title: string;
  norm_title: string;
  alt_titles: string[];
  status: TopicStatus;
  velocity: number;
  peak_velocity: number;
  signal_count: number;
  domain_count: number;
  domains: string[];
  domains_at_reject: number | null;
  first_seen: string;
  last_seen: string;
  fired_at: string | null;
  ended_at: string | null;
  article_slug: string | null;
}

export interface ArticleSource {
  publisher: string;
  url: string;
  title?: string;
  snippet?: string;
}

export interface Article {
  id: string;
  slug: string;
  country: Country;
  places: { slug: string; name: string; state?: string; level: Level }[];
  headline: string;
  summary: string[];
  perspectives: { framing: string; a: { label: string; body: string }; b: { label: string; body: string } };
  agree: string;
  local_angle: string;
  context?: string;
  watch_next: string;
  updates: { at: string; text: string }[];
  corrections: { at: string; text: string }[];
  sources: ArticleSource[];
  topic_tags: string[];
  sensitive: boolean;
  review: { approved_by: string | null; approved_at: string | null };
  checks: {
    originality?: { passed: boolean; max_similarity: number };
    fact_consistency?: { passed: boolean; conflicts: boolean; unsupported_claims_removed: number };
    balance?: { passed: boolean };
  };
  published_at: string;
  updated_at?: string;
  trend_ended_at: string | null;
  traffic: { visits_14d_after_end: number | null };
  superseded_by: string | null;
  noindex?: boolean;
  app_link: { label: string; url: string } | null;
  velocity?: number;
  ai_disclosure?: string;
}

export interface Settings {
  pipeline: { enabled: boolean };
  publishing: { paused: boolean; paused_at: string | null; paused_reason?: string | null };
  caps: {
    ramp_levels: number[];
    hard_max_per_day: number;
    max_per_hour: number;
    timezones: Record<Country, string>;
    max_drafts_per_run: number;
    queue_ttl_hours: number;
  };
  ramp: {
    usa: { level: number; changed_at: string | null };
    india: { level: number; changed_at: string | null };
    min_days_between_steps: number;
    auto_step_up: boolean;
    health: {
      max_age_days: number;
      min_indexed_share: number;
      max_click_drop: number;
      max_sc_warnings: number;
      max_error_reports_24h: number;
    };
  };
  gates: {
    min_sources: number;
    max_similarity: number;
    shingle_words: number;
    max_quote_words: number;
    min_words: number;
    min_section_words: number;
    max_perspective_ratio: number;
    noindex_min_visits_14d: number;
    max_rewrites: number;
  };
  detection: {
    fire_threshold: number;
    min_signals: number;
    cluster_similarity: number;
    velocity_window_minutes: number;
    baseline_hours: number;
    topic_ttl_hours: number;
    merge_window_days: number;
    end_velocity: number;
    end_after_hours: number;
    update_min_interval_minutes: number;
    max_updates: number;
    source_weights: Record<SourceKind, number>;
    non_publisher_domains: string[];
  };
  sensitive_tags: string[];
  sensitive_keywords: string[];
  banned_perspective_terms: string[];
  app_links: { country: Country; keywords: string[]; category: string; label: string }[];
  app_hosts: Record<Country, string>;
}

export interface Health {
  country: Country;
  recorded_at: string;
  indexed_share: number | null;
  clicks_7d: number | null;
  clicks_prev_7d: number | null;
  sc_warnings: number;
  manual_action: boolean;
  error_reports_24h: number;
}

export interface GateResult {
  passed: boolean;
  [k: string]: unknown;
}

export type DraftStatus = "queued" | "review" | "rejected" | "published" | "noindex";

export interface Draft {
  id: string;
  topic_id: string | null;
  country: Country;
  slug: string | null;
  status: DraftStatus;
  article: Article | null;
  gates: Record<string, GateResult>;
  failed_gate: string | null;
  reason: string | null;
  sensitive: boolean;
  sensitive_reasons: string[];
  review_stage: "topic" | "content" | null;
  topic_reviewed_at: string | null;
  reviewer_id: string | null;
  reviewed_at: string | null;
  velocity: number;
  published_at: string | null;
  last_update_at: string | null;
  superseded_by: string | null;
  noindex_reason: string | null;
  visits_14d_after_end: number | null;
  storage_path: string | null;
  dirty: boolean;
  created_at: string;
}
