// trends-poll run: feeds -> signals -> clusters -> velocity -> fired topics.
import { clusterSignals, computeVelocity, nextTopicState } from "./cluster.ts";
import { type FetchFn, pollSource, type RedditCreds } from "./feeds.ts";
import type { Store } from "./store.ts";
import type { SignalInput, TrendSource } from "./types.ts";

export interface PollDeps {
  store: Store;
  fetch: FetchFn;
  reddit: RedditCreds | null;
  now: () => Date;
}

async function mapLimit<T, R>(items: T[], limit: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (i < items.length) {
      const idx = i++;
      out[idx] = await fn(items[idx]);
    }
  }));
  return out;
}

export async function runPoll(deps: PollDeps) {
  const { store } = deps;
  const s = await store.settings();
  const d = s.detection;
  const sources = await store.enabledSources();
  const perSource: Record<string, unknown>[] = [];

  const results = await mapLimit(sources, 6, async (src: TrendSource) => {
    try {
      const r = await pollSource(src, {
        fetch: deps.fetch,
        reddit: deps.reddit,
        nonPublisher: d.non_publisher_domains,
      });
      await store.markSource(src.id, r.skipped ? "skipped" : "ok", r.signals.length, r.skipped ?? null);
      perSource.push({
        id: src.id,
        kind: src.kind,
        geo: src.geo,
        items: r.signals.length,
        skipped: r.skipped,
      });
      return r.signals;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      await store.markSource(src.id, "error", 0, msg);
      perSource.push({ id: src.id, kind: src.kind, geo: src.geo, error: msg });
      return [] as SignalInput[];
    }
  });

  // one row per (kind, place, dedupe key) in this batch
  const batch = new Map<string, SignalInput>();
  for (const sig of results.flat()) {
    const k = `${sig.source_kind}|${sig.place_slug}|${sig.dedupe_key}`;
    const prev = batch.get(k);
    if (!prev || sig.score > prev.score) batch.set(k, sig);
  }
  const all = [...batch.values()];
  const existing = await store.existingSignals(all);
  const keyOf = (x: SignalInput) => `${x.source_kind}|${x.place_slug}|${x.dedupe_key}`;
  const fresh = all.filter((x) => !existing.has(keyOf(x)));

  const knownHints = new Map<string, string>();
  for (const x of all) {
    const t = existing.get(keyOf(x));
    if (t && x.cluster_hint && !x.url) knownHints.set(`${x.country}|${x.place_slug}|${x.cluster_hint}`, t);
  }

  const active = await store.activeTopics(d.topic_ttl_hours, d.merge_window_days);
  const cl = clusterSignals(fresh, active, d.cluster_similarity, knownHints);
  const usedNew = [...new Set(cl.assignments.filter((k) => k.startsWith("new:")))];
  const created = await store.createTopics(usedNew.map((k) => cl.topics.get(k)!));
  const idOf = (k: string) => created.get(k) ?? k;
  for (const t of active) {
    const c = cl.topics.get(t.id);
    if (c && c.alt_titles.length !== (t.alt_titles ?? []).length) {
      await store.setAltTitles(t.id, c.alt_titles);
    }
  }
  const inserted = await store.upsertSignals([
    ...fresh.map((x, i) => ({ ...x, topic_id: idOf(cl.assignments[i]) })),
    ...all.filter((x) => existing.has(keyOf(x))).map((x) => ({ ...x, topic_id: null })),
  ]);

  // velocity + transitions for every active topic (decay too) and the new ones
  const now = deps.now();
  const touched = new Set<string>([
    ...cl.assignments.map(idOf),
    ...[...existing.values()].filter((x): x is string => !!x),
  ]);
  const topicIds = [...new Set([...active.map((t) => t.id), ...created.values()])];
  const recent = await store.recentSignals(topicIds, d.velocity_window_minutes + d.baseline_hours * 60 + 60);
  const stats = await store.topicStats(topicIds, d.non_publisher_domains);
  const fired: { id: string; title: string; place: string; velocity: number }[] = [];
  const byId = new Map(active.map((t) => [t.id, t]));
  for (const id of topicIds) {
    const t = byId.get(id) ?? {
      id,
      status: "watching" as const,
      last_seen: now.toISOString(),
      first_seen: now.toISOString(),
      domains_at_reject: null,
      fired_at: null,
      peak_velocity: 0,
      title: "",
      place_name: "",
    };
    const v = computeVelocity(recent.get(id) ?? [], now, d);
    const st = stats.get(id);
    if (st) {
      v.domains = st.domains;
      v.signalCount = st.signal_count;
    }
    const lastSeen = touched.has(id) ? now.toISOString() : t.last_seen;
    const tr = nextTopicState({ ...t, last_seen: lastSeen }, v, now, d);
    const patch: Record<string, unknown> = {
      velocity: v.velocity,
      peak_velocity: Math.max(t.peak_velocity ?? 0, v.velocity),
      signal_count: v.signalCount,
      domain_count: v.domains.length,
      domains: v.domains,
      last_seen: lastSeen,
    };
    if (tr) {
      patch.status = tr.status;
      patch.status_reason = tr.reason ?? null;
      if (tr.fired_at) patch.fired_at = tr.fired_at;
      if (tr.ended_at !== undefined) patch.ended_at = tr.ended_at;
      if (tr.status === "fired") {
        const c = cl.topics.get(id) ?? [...cl.topics.values()].find((x) => idOf(x.key) === id);
        fired.push({
          id,
          title: t.title || c?.title || "",
          place: t.place_name || c?.place_name || "",
          velocity: v.velocity,
        });
      }
    }
    await store.updateTopic(id, patch);
  }
  return {
    sources: sources.length,
    source_errors: perSource.filter((p) => p.error).length,
    per_source: perSource,
    signals_seen: all.length,
    signals_new: inserted,
    topics_new: created.size,
    topics_active: topicIds.length,
    fired,
  };
}
