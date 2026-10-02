// trends-publish run: ramp + kill switch, gate 6 caps, bucket upload (articles/<slug>.json +
// index.json), noindex / superseded / unpublish maintenance, Vercel deploy hook.
import {
  articlePath,
  buildIndex,
  finalArticle,
  INDEX_PATH,
  noindexReason,
  selectForPublish,
} from "./publish.ts";
import { evaluateRamp } from "./ramp.ts";
import type { Store } from "./store.ts";
import type { Country } from "./types.ts";

export interface TrendsStorage {
  put(path: string, body: string): Promise<void>;
  remove(path: string): Promise<void>;
  get(path: string): Promise<string | null>;
}

export interface PublishDeps {
  store: Store;
  storage: TrendsStorage | null; // null = dry run (no bucket credentials)
  deployHook: string | null;
  fetch: typeof fetch;
  now: () => Date;
}

const COUNTRIES: Country[] = ["usa", "india"];

export async function runPublish(deps: PublishDeps) {
  const { store, storage } = deps;
  const s = await store.settings();
  const now = deps.now();
  const dry = !storage;
  const stats = {
    dry_run: dry,
    paused: false,
    published: [] as string[],
    capped: 0,
    expired: 0,
    reuploaded: 0,
    removed: 0,
    noindexed: 0,
    ramp: [] as unknown[],
    index_changed: false,
    deploy_hook: null as null | number | string,
  };

  // Ramp: automatic step-down (or opt-in step-up) from the latest health snapshot; auto pause.
  let rampChanged = false;
  for (const c of COUNTRIES) {
    const dec = evaluateRamp(c, await store.latestHealth(c), now, s);
    if (dec.action !== "none") {
      s.ramp[c] = { level: dec.to, changed_at: now.toISOString() };
      rampChanged = true;
      stats.ramp.push({ country: c, ...dec });
      await store.log(dec.action === "down" ? "ramp_down" : "ramp_up", dec.reason, null, {
        country: c,
        from: dec.from,
        to: dec.to,
        auto: true,
      });
    }
    if (dec.pause && !s.publishing.paused) {
      s.publishing = { paused: true, paused_at: now.toISOString(), paused_reason: dec.pause };
      if (!dry) await store.saveSetting("publishing", { ...s.publishing, paused_by: "auto" });
      await store.log("auto_pause", dec.pause, null, { country: c });
    }
  }
  stats.paused = s.publishing.paused;

  // Gate 6: kill switch + caps, highest velocity first.
  if (!s.publishing.paused) {
    const queued = await store.queuedReady();
    const decisions = selectForPublish(queued, await store.publishedTimes(48), s, now);
    for (const dec of decisions) {
      const d = queued.find((q) => q.id === dec.id)!;
      if (dec.decision === "publish") {
        if (dry) {
          stats.published.push(d.slug!);
          continue;
        }
        const path = articlePath(d.slug!);
        const published = { ...d, published_at: now.toISOString() };
        const a = finalArticle(published, { trendEndedAt: null, noindex: false, now });
        await storage!.put(path, JSON.stringify(a));
        await store.updateDraft(d.id, {
          status: "published",
          published_at: now.toISOString(),
          storage_path: path,
          dirty: false,
          article: a,
          gates: { ...d.gates, caps: { passed: true, at: now.toISOString() } },
        });
        if (d.topic_id) {
          await store.updateTopic(d.topic_id, {
            status: "published",
            article_slug: d.slug,
            status_reason: "published",
          });
        }
        await store.log("published", null, d, { path, velocity: d.velocity });
        stats.published.push(d.slug!);
        // the ramp's first month starts at the first published article (launch)
        if (!s.ramp[d.country].changed_at) {
          s.ramp[d.country] = { ...s.ramp[d.country], changed_at: now.toISOString() };
          rampChanged = true;
        }
      } else if (dec.decision === "expired") {
        stats.expired++;
        if (!dry) {
          await store.updateDraft(d.id, {
            status: "rejected",
            failed_gate: "caps",
            reason: dec.reason,
            gates: { ...d.gates, caps: { passed: false, reason: dec.reason } },
          });
          if (d.topic_id) {
            await store.updateTopic(d.topic_id, {
              status: "dropped",
              status_reason: "cap: not published in time",
            });
          }
          await store.log("rejected", `caps: ${dec.reason}`, d);
        }
      } else {
        stats.capped++;
        // log a cap decision once per draft, not every five minutes
        if (!dry && !(d.gates?.caps && d.gates.caps.passed === false)) {
          await store.updateDraft(d.id, {
            gates: { ...d.gates, caps: { passed: false, reason: dec.reason, at: now.toISOString() } },
          });
          await store.log("capped", dec.reason, d);
        }
      }
    }
  }
  if (rampChanged && !dry) await store.saveSetting("ramp", s.ramp);

  // Maintenance: corrections / updates / noindex / unpublish (allowed while paused: they only
  // correct or withdraw what is already live).
  for (const d of await store.needsUpload()) {
    if (d.status === "rejected") {
      if (!dry && d.storage_path) {
        await storage!.remove(d.storage_path);
        await store.updateDraft(d.id, { storage_path: null, dirty: false });
        await store.log("unpublished", d.reason, d);
      }
      stats.removed++;
      continue;
    }
    let dirty = d.dirty;
    let status = d.status;
    let reason = d.noindex_reason;
    const auto = noindexReason(d, d.topic_ended_at, now, s);
    if (auto && status === "published") {
      status = "noindex";
      reason = auto;
      dirty = true;
      stats.noindexed++;
      if (!dry) await store.log(auto.startsWith("superseded") ? "superseded" : "noindex", auto, d);
    }
    if ((d.article?.trend_ended_at ?? null) !== (d.topic_ended_at ?? null)) dirty = true;
    if (!dirty || dry) continue;
    const a = finalArticle(d, { trendEndedAt: d.topic_ended_at, noindex: status === "noindex", now });
    const path = d.storage_path ?? articlePath(d.slug!);
    await storage!.put(path, JSON.stringify(a));
    await store.updateDraft(d.id, {
      status,
      noindex_reason: reason,
      dirty: false,
      article: a,
      storage_path: path,
    });
    stats.reuploaded++;
  }

  // Index: rewritten when it differs from the bucket copy (ignoring generated_at).
  if (!dry) {
    const rows = await store.indexRows();
    const index = buildIndex(
      rows.map((r) => ({
        slug: r.slug,
        path: r.storage_path,
        country: r.country,
        published_at: r.published_at,
        updated_at: r.updated_at,
        noindex: r.noindex,
      })),
      s,
      now,
    );
    const strip = (x: string | null) => {
      try {
        const o = x ? JSON.parse(x) : null;
        if (o) delete o.generated_at;
        return JSON.stringify(o);
      } catch {
        return null;
      }
    };
    const body = JSON.stringify(index);
    if (strip(await storage!.get(INDEX_PATH)) !== strip(body)) {
      await storage!.put(INDEX_PATH, body);
      stats.index_changed = true;
    }
    if (stats.index_changed && deps.deployHook) {
      try {
        const res = await deps.fetch(deps.deployHook, {
          method: "POST",
          signal: AbortSignal.timeout(10_000),
        });
        await res.body?.cancel();
        stats.deploy_hook = res.status;
      } catch (e) {
        stats.deploy_hook = e instanceof Error ? e.message : "error";
      }
    }
  }
  return stats;
}
