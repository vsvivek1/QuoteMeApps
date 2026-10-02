// Clustering, velocity and firing (trends-poll).
//
// Clustering: a signal joins the most similar active topic of the same country and place
// (normalised-title similarity >= detection.cluster_similarity, compared with the topic title
// and a few member headlines). Google Trends news items carry their trend title as a hint and
// join that trend's topic directly. Otherwise a new topic is opened.
//
// Velocity (0-100): weighted signals first seen in the last window, plus a bonus while Google
// Trends still lists the topic and per independent publisher, scaled by acceleration against the
// preceding baseline hours and saturated:  100 * (1 - exp(-raw * accel / 25)).
import { normalizeTitle, titleSimilarity } from "./text.ts";
import type { Country, Level, Settings, Signal, SignalInput, Topic, TopicStatus } from "./types.ts";

export interface ClusterTopic {
  key: string; // topic id, or "new:<n>" for topics opened in this batch
  country: Country;
  place_slug: string;
  place_name: string;
  state: string | null;
  level: Level;
  title: string;
  norm_title: string;
  alt_titles: string[];
  status: TopicStatus;
  isNew: boolean;
}

export interface ClusterResult {
  assignments: string[]; // topic key per input signal (same order)
  topics: Map<string, ClusterTopic>;
}

const MAX_ALT = 6;

export function clusterSignals(
  signals: SignalInput[],
  active: Pick<
    Topic,
    | "id"
    | "country"
    | "place_slug"
    | "place_name"
    | "state"
    | "level"
    | "title"
    | "norm_title"
    | "alt_titles"
    | "status"
  >[],
  threshold: number,
  /** "country|place|hint" -> topic id, from trend titles already stored (their news items join them) */
  knownHints: Map<string, string> = new Map(),
): ClusterResult {
  const topics = new Map<string, ClusterTopic>();
  for (const t of active) {
    topics.set(t.id, { ...t, key: t.id, alt_titles: [...(t.alt_titles ?? [])], isNew: false });
  }
  const hintIndex = new Map<string, string>(); // country|place|hint -> key
  for (const [k, id] of knownHints) if (topics.has(id)) hintIndex.set(k, id);
  let n = 0;
  const assignments: string[] = [];

  // Trend titles first so that their news items (and other feeds) can join them.
  const order = signals.map((_s, i) => i).sort((a, b) => {
    const ra = signals[a].source_kind === "google_trends" && !signals[a].url ? 0 : 1;
    const rb = signals[b].source_kind === "google_trends" && !signals[b].url ? 0 : 1;
    return ra - rb || a - b;
  });

  for (const i of order) {
    const s = signals[i];
    const scope = `${s.country}|${s.place_slug}`;
    let key: string | undefined;
    const ignore = new Set(normalizeTitle(s.place_name).split(" "));
    if (s.cluster_hint) key = hintIndex.get(`${scope}|${s.cluster_hint}`);
    if (!key) {
      let best = 0;
      for (const t of topics.values()) {
        if (t.country !== s.country || t.place_slug !== s.place_slug) continue;
        const sim = Math.max(
          titleSimilarity(s.norm_title, t.norm_title, ignore),
          ...t.alt_titles.map((a) => titleSimilarity(s.norm_title, a, ignore)),
        );
        if (sim >= threshold && sim > best) {
          best = sim;
          key = t.key;
        }
      }
    }
    if (!key) {
      key = `new:${n++}`;
      topics.set(key, {
        key,
        country: s.country,
        place_slug: s.place_slug,
        place_name: s.place_name,
        state: s.state,
        level: s.level,
        title: s.topic,
        norm_title: s.norm_title,
        alt_titles: [],
        status: "watching",
        isNew: true,
      });
    } else {
      const t = topics.get(key)!;
      if (
        s.norm_title !== t.norm_title && !t.alt_titles.includes(s.norm_title) && t.alt_titles.length < MAX_ALT
      ) {
        t.alt_titles.push(s.norm_title);
      }
    }
    if (s.cluster_hint) hintIndex.set(`${scope}|${s.cluster_hint}`, key);
    assignments[i] = key;
  }
  return { assignments, topics };
}

export interface VelocityInfo {
  velocity: number;
  recentWeight: number;
  baselineRate: number;
  accel: number;
  domains: string[]; // distinct citable publisher domains (all time for the topic)
  publisherDomains: number; // distinct publisher domains seen in window + baseline
  signalCount: number;
}

export function signalWeight(s: Pick<Signal, "source_kind" | "score">, d: Settings["detection"]): number {
  return (d.source_weights[s.source_kind] ?? 1) * (1 + Math.log10(1 + Math.max(0, s.score) / 1000));
}

export function computeVelocity(signals: Signal[], now: Date, d: Settings["detection"]): VelocityInfo {
  const t = now.getTime();
  const win = d.velocity_window_minutes * 60_000;
  const baseMs = d.baseline_hours * 3_600_000;
  const nonPub = new Set(d.non_publisher_domains);
  let recentW = 0;
  let baseW = 0;
  let trendBonus = 0;
  const recentDomains = new Set<string>();
  const citable = new Set<string>();
  for (const s of signals) {
    const first = Date.parse(s.first_seen);
    const last = Date.parse(s.last_seen);
    const w = signalWeight(s, d);
    if (first > t - win && first <= t) recentW += w;
    else if (first > t - win - baseMs && first <= t - win) baseW += w;
    // still listed by Google Trends in this window: the trend is alive
    if (s.source_kind === "google_trends" && !s.url && last > t - win) trendBonus = Math.max(trendBonus, w);
    if (s.publisher_domain && !nonPub.has(s.publisher_domain) && last > t - win - baseMs) {
      recentDomains.add(s.publisher_domain);
    }
    if (s.citable && s.publisher_domain && !nonPub.has(s.publisher_domain)) citable.add(s.publisher_domain);
  }
  const baselineRate = baseW / Math.max(1, baseMs / win); // weight per window in the baseline
  const accel = Math.min(2, Math.max(0.5, (recentW + 1) / (baselineRate + 1)));
  const raw = recentW + trendBonus + 2 * recentDomains.size;
  const velocity = Math.round(100 * (1 - Math.exp((-raw * accel) / 25)));
  return {
    velocity,
    recentWeight: recentW,
    baselineRate,
    accel,
    domains: [...citable].sort(),
    publisherDomains: recentDomains.size,
    signalCount: signals.length,
  };
}

export interface TopicTransition {
  status: TopicStatus;
  fired_at?: string;
  ended_at?: string | null;
  reason?: string;
}

/**
 * Next status of a topic after its velocity was recomputed. Fires when velocity crosses the
 * threshold with enough signals; a topic waiting for sources re-fires once it has more citable
 * domains than when it was set aside; quiet topics end (articles) or are dropped (no article).
 */
export function nextTopicState(
  topic: Pick<Topic, "status" | "last_seen" | "domains_at_reject" | "fired_at" | "first_seen">,
  v: VelocityInfo,
  now: Date,
  d: Settings["detection"],
): TopicTransition | null {
  const t = now.getTime();
  const quietFor = t - Date.parse(topic.last_seen);
  const hot = v.velocity >= d.fire_threshold && v.signalCount >= d.min_signals;
  switch (topic.status) {
    case "watching":
      if (hot) return { status: "fired", fired_at: now.toISOString(), reason: `velocity ${v.velocity}` };
      if (t - Date.parse(topic.first_seen) > d.topic_ttl_hours * 3_600_000) {
        return { status: "dropped", reason: "expired" };
      }
      return null;
    case "waiting_sources":
      if (hot && v.domains.length > (topic.domains_at_reject ?? 0)) {
        return { status: "fired", fired_at: now.toISOString(), reason: "more sources" };
      }
      if (quietFor > d.topic_ttl_hours * 3_600_000) return { status: "dropped", reason: "expired" };
      return null;
    case "published":
      if (v.velocity < d.end_velocity && quietFor > d.end_after_hours * 3_600_000) {
        return { status: "ended", ended_at: now.toISOString(), reason: "trend ended" };
      }
      return null;
    case "fired":
      if (quietFor > d.topic_ttl_hours * 3_600_000) {
        return { status: "dropped", reason: "expired before drafting" };
      }
      return null;
    default:
      return null;
  }
}
