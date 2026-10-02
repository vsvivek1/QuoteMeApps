// Trends pipeline: publish selection (gate 6), noindex rules, final article JSON, the bucket
// index, and full trends-publish / trends-draft runs against an in-memory store.
import { assert, assertEquals } from "@std/assert";
import { makeClaude } from "../_shared/trends/claude.ts";
import { buildArticle, pickSources } from "../_shared/trends/draft.ts";
import { buildIndex, finalArticle, noindexReason, selectForPublish } from "../_shared/trends/publish.ts";
import { runDraft } from "../_shared/trends/run_draft.ts";
import { runPublish, type TrendsStorage } from "../_shared/trends/run_publish.ts";
import type { Store } from "../_shared/trends/store.ts";
import type { Country, Draft, Health, Settings, Topic } from "../_shared/trends/types.ts";
import { claudeFetch, iso, modelArticle, NOW, settings, signals, topic } from "./trends_fixtures.ts";

const s0 = settings();

function draft(p: Partial<Draft> & { id: string }): Draft {
  const a = buildArticle(
    structuredClone(modelArticle),
    { ...topic, id: `${p.id}-0000-0000` },
    pickSources(signals, s0),
    s0,
    NOW,
  );
  return {
    topic_id: topic.id,
    country: "usa",
    slug: a.slug,
    status: "queued",
    article: a,
    gates: {},
    failed_gate: null,
    reason: null,
    sensitive: false,
    sensitive_reasons: [],
    review_stage: null,
    topic_reviewed_at: null,
    reviewer_id: null,
    reviewed_at: null,
    velocity: 70,
    published_at: null,
    last_update_at: null,
    superseded_by: null,
    noindex_reason: null,
    visits_14d_after_end: null,
    storage_path: null,
    dirty: false,
    created_at: iso(30),
    ...p,
  };
}

Deno.test("selectForPublish: highest velocity first, caps per country, stale queue expires, kill switch", () => {
  const q = [
    { id: "a", country: "usa" as const, velocity: 60, created_at: iso(20) },
    { id: "b", country: "usa" as const, velocity: 90, created_at: iso(10) },
    { id: "c", country: "india" as const, velocity: 50, created_at: iso(10) },
    { id: "d", country: "india" as const, velocity: 99, created_at: iso(60 * 7) },
  ];
  const r = selectForPublish(q, { usa: [], india: [] }, s0, NOW); // level 0: 1 per day per country
  assertEquals(r.map((x) => `${x.id}:${x.decision}`), ["d:expired", "b:publish", "a:capped", "c:publish"]);
  const paused = settings({ publishing: { paused: true, paused_at: NOW.toISOString() } });
  assert(selectForPublish(q, { usa: [], india: [] }, paused, NOW).every((x) => x.decision !== "publish"));
});

Deno.test("noindex rules: superseded, traffic died 14 days after the trend, manual", () => {
  const base = {
    superseded_by: null,
    visits_14d_after_end: null,
    noindex_reason: null,
    status: "published" as const,
  };
  assertEquals(noindexReason(base, null, NOW, s0), null);
  assertEquals(noindexReason({ ...base, superseded_by: "newer" }, null, NOW, s0), "superseded by newer");
  const ended = "2026-09-10T00:00:00Z";
  assertEquals(
    noindexReason({ ...base, visits_14d_after_end: 12 }, ended, NOW, s0),
    "traffic died (12 visits in 14 days after the trend)",
  );
  assertEquals(noindexReason({ ...base, visits_14d_after_end: 50 }, ended, NOW, s0), null);
  assertEquals(noindexReason({ ...base, visits_14d_after_end: 12 }, "2026-09-25T00:00:00Z", NOW, s0), null); // < 14 days
  assertEquals(
    noindexReason({ ...base, status: "noindex", noindex_reason: "manual" }, null, NOW, s0),
    "manual",
  );
});

Deno.test("finalArticle carries publishing state in the site format", () => {
  const d = draft({ id: "f1", published_at: iso(60), superseded_by: "newer-story", visits_14d_after_end: 5 });
  const a = finalArticle(d, { trendEndedAt: "2026-09-10T00:00:00Z", noindex: true, now: NOW });
  assertEquals(a.published_at, iso(60));
  assertEquals(a.superseded_by, "newer-story");
  assertEquals(a.trend_ended_at, "2026-09-10T00:00:00Z");
  assertEquals(a.traffic, { visits_14d_after_end: 5 });
  assertEquals(a.noindex, true);
  assert("updates" in a && "corrections" in a && "review" in a && "checks" in a);
  assertEquals(finalArticle(d, { trendEndedAt: null, noindex: false, now: NOW }).noindex, undefined);
});

Deno.test("buildIndex: newest first, unique valid slugs, effective settings for the site build", () => {
  const s = settings();
  s.ramp.usa = { level: 2, changed_at: null };
  s.publishing = { paused: true, paused_at: "2026-10-02T12:00:00Z" };
  const e = (slug: string, at: string) => ({
    slug,
    path: `articles/${slug}.json`,
    country: "usa" as Country,
    published_at: at,
    updated_at: at,
    noindex: false,
  });
  const idx = buildIndex(
    [e("older", iso(100)), e("newer", iso(10)), e("newer", iso(5)), e("Bad Slug", iso(1))],
    s,
    NOW,
  );
  assertEquals(idx.version, 1);
  assertEquals(idx.articles.map((a) => a.slug), ["newer", "older"]);
  assertEquals(idx.settings, {
    paused: true,
    paused_at: "2026-10-02T12:00:00Z",
    per_day: { usa: 5, india: 1 },
  });
});

// ---- in-memory store ------------------------------------------------------------------------------
class MemStore implements Partial<Store> {
  s: Settings = settings();
  drafts: Draft[] = [];
  topics: Topic[] = [{ ...topic }];
  health: Partial<Record<Country, Health>> = {};
  logs: { decision: string; reason: string | null }[] = [];
  saved: Record<string, unknown> = {};
  settings() {
    return Promise.resolve(structuredClone(this.s));
  }
  saveSetting(key: string, value: unknown) {
    this.saved[key] = value;
    (this.s as unknown as Record<string, unknown>)[key] = structuredClone(value);
    return Promise.resolve();
  }
  log(decision: string, reason: string | null) {
    this.logs.push({ decision, reason });
    return Promise.resolve();
  }
  latestHealth(c: Country) {
    return Promise.resolve(this.health[c] ?? null);
  }
  queuedReady() {
    return Promise.resolve(
      this.drafts.filter((d) => d.status === "queued" && d.article && d.slug).map((d) => structuredClone(d)),
    );
  }
  publishedTimes() {
    const out: Record<Country, string[]> = { usa: [], india: [] };
    for (const d of this.drafts) if (d.published_at) out[d.country].push(d.published_at);
    return Promise.resolve(out);
  }
  updateDraft(id: string, patch: Record<string, unknown>) {
    Object.assign(this.drafts.find((d) => d.id === id)!, structuredClone(patch));
    return Promise.resolve();
  }
  updateTopic(id: string, patch: Record<string, unknown>) {
    Object.assign(this.topics.find((t) => t.id === id) ?? {}, patch);
    return Promise.resolve();
  }
  needsUpload() {
    return Promise.resolve(
      this.drafts.filter((d) =>
        ["published", "noindex"].includes(d.status) || (d.status === "rejected" && d.storage_path)
      )
        .map((d) => ({
          ...structuredClone(d),
          topic_ended_at: this.topics.find((t) => t.id === d.topic_id)?.ended_at ?? null,
        })),
    );
  }
  indexRows() {
    return Promise.resolve(
      this.drafts.filter((d) => ["published", "noindex"].includes(d.status) && d.storage_path).map((d) => ({
        slug: d.slug!,
        country: d.country,
        published_at: d.published_at!,
        updated_at: d.article?.updated_at ?? d.published_at!,
        noindex: d.status === "noindex",
        storage_path: d.storage_path!,
      })),
    );
  }
  // trends-draft
  pendingDrafts() {
    return Promise.resolve([]);
  }
  firedTopics() {
    return Promise.resolve(this.topics.filter((t) => t.status === "fired"));
  }
  topicSignals() {
    return Promise.resolve(structuredClone(signals));
  }
  insertDraft(row: Record<string, unknown>) {
    const id = `d${this.drafts.length + 1}`;
    this.drafts.push({ ...draft({ id }), ...(row as Partial<Draft>), id, created_at: NOW.toISOString() });
    return Promise.resolve(id);
  }
  publishedWithNewSignals() {
    return Promise.resolve([]);
  }
}

class MemStorage implements TrendsStorage {
  files = new Map<string, string>();
  puts: string[] = [];
  put(path: string, body: string) {
    this.files.set(path, body);
    this.puts.push(path);
    return Promise.resolve();
  }
  remove(path: string) {
    this.files.delete(path);
    return Promise.resolve();
  }
  get(path: string) {
    return Promise.resolve(this.files.get(path) ?? null);
  }
}

function hookFetch() {
  const calls: string[] = [];
  const f = ((u: string | URL | Request) => {
    calls.push(String(u));
    return Promise.resolve(new Response("ok", { status: 201 }));
  }) as typeof fetch;
  return { f, calls };
}

const asStore = (m: MemStore) => m as unknown as Store;

Deno.test("trends-publish run: publishes within caps, writes article + index, calls the deploy hook once", async () => {
  const m = new MemStore();
  m.drafts = [draft({ id: "p1", velocity: 90 }), draft({ id: "p2", velocity: 50, slug: "second-story" })];
  const storage = new MemStorage();
  const hook = hookFetch();
  const deps = {
    store: asStore(m),
    storage,
    deployHook: "https://api.vercel.com/v1/integrations/deploy/x",
    fetch: hook.f,
    now: () => NOW,
  };
  const r = await runPublish(deps);
  assertEquals(r.published, [m.drafts[0].slug]);
  assertEquals(r.capped, 1);
  assertEquals(m.drafts[0].status, "published");
  assertEquals(m.drafts[0].storage_path, `articles/${m.drafts[0].slug}.json`);
  const written = JSON.parse(storage.files.get(`articles/${m.drafts[0].slug}.json`)!);
  assertEquals(written.published_at, NOW.toISOString());
  const index = JSON.parse(storage.files.get("index.json")!);
  assertEquals(index.articles.map((a: { slug: string }) => a.slug), [m.drafts[0].slug]);
  assertEquals(index.settings.per_day, { usa: 1, india: 1 });
  assertEquals(hook.calls.length, 1);
  assertEquals(m.logs.map((l) => l.decision), ["published", "capped"]);
  assert(m.saved.ramp, "launch date recorded for the ramp");

  // nothing new: index unchanged, no hook, cap decision not logged again
  const again = await runPublish(deps);
  assertEquals([again.published.length, again.index_changed], [0, false]);
  assertEquals(hook.calls.length, 1);
  assertEquals(m.logs.filter((l) => l.decision === "capped").length, 1);
});

Deno.test("trends-publish run: kill switch publishes nothing; manual action pauses and steps down", async () => {
  const m = new MemStore();
  m.s.ramp.usa = { level: 2, changed_at: "2026-09-01T00:00:00Z" };
  m.health.usa = {
    country: "usa",
    recorded_at: iso(30),
    indexed_share: 0.9,
    clicks_7d: 100,
    clicks_prev_7d: 100,
    sc_warnings: 0,
    manual_action: true,
    error_reports_24h: 0,
  };
  m.drafts = [draft({ id: "k1" })];
  const r = await runPublish({
    store: asStore(m),
    storage: new MemStorage(),
    deployHook: null,
    fetch: hookFetch().f,
    now: () => NOW,
  });
  assertEquals(r.paused, true);
  assertEquals(r.published, []);
  assertEquals(m.drafts[0].status, "queued");
  assertEquals((m.saved.publishing as { paused: boolean }).paused, true);
  assertEquals((m.saved.ramp as Settings["ramp"]).usa.level, 1);
  assertEquals(m.logs.map((l) => l.decision).sort(), ["auto_pause", "ramp_down"]);
});

Deno.test("trends-publish run: corrections re-upload, superseded becomes noindex, unpublished is removed", async () => {
  const m = new MemStore();
  const storage = new MemStorage();
  const live = draft({
    id: "u1",
    status: "published",
    published_at: iso(120),
    storage_path: "articles/old.json",
    slug: "old",
    superseded_by: "newer",
  });
  live.article!.corrections = [{ at: iso(5), text: "An earlier version misstated the forecast total." }];
  const gone = draft({ id: "u2", status: "rejected", storage_path: "articles/gone.json", slug: "gone" });
  storage.files.set("articles/gone.json", "{}");
  m.drafts = [live, gone];
  const r = await runPublish({
    store: asStore(m),
    storage,
    deployHook: null,
    fetch: hookFetch().f,
    now: () => NOW,
  });
  assertEquals([r.noindexed, r.reuploaded, r.removed], [1, 1, 1]);
  assertEquals(m.drafts[0].status, "noindex");
  const written = JSON.parse(storage.files.get("articles/old.json")!);
  assertEquals([written.noindex, written.superseded_by, written.corrections.length], [true, "newer", 1]);
  assertEquals(storage.files.has("articles/gone.json"), false);
  const index = JSON.parse(storage.files.get("index.json")!);
  assertEquals(index.articles, [{
    slug: "old",
    path: "articles/old.json",
    country: "usa",
    published_at: iso(120),
    updated_at: m.drafts[0].article!.updated_at,
    noindex: true,
  }]);
});

Deno.test("trends-publish dry run (no bucket credentials) changes nothing", async () => {
  const m = new MemStore();
  m.drafts = [draft({ id: "dr" })];
  const r = await runPublish({
    store: asStore(m),
    storage: null,
    deployHook: null,
    fetch: hookFetch().f,
    now: () => NOW,
  });
  assertEquals([r.dry_run, r.published.length], [true, 1]);
  assertEquals(m.drafts[0].status, "queued");
});

Deno.test("trends-draft run: kill switch and missing API key mean no model calls", async () => {
  const m = new MemStore();
  m.s.publishing = { paused: true, paused_at: NOW.toISOString() };
  const cf = claudeFetch({});
  const claude = makeClaude({ apiKey: "k", model: "claude-sonnet-5-5", fetch: cf.fetch });
  const paused = await runDraft({ store: asStore(m), claude, now: () => NOW });
  assertEquals(paused.paused, true);
  assertEquals(cf.calls.length, 0);

  m.s.publishing = { paused: false, paused_at: null };
  const noKey = await runDraft({ store: asStore(m), claude: null, now: () => NOW });
  assertEquals([noKey.no_api_key, noKey.skipped_no_key, m.drafts.length], [true, 1, 0]);
});

Deno.test("trends-draft run: drafts a fired topic within today's capacity and logs the decision", async () => {
  const m = new MemStore();
  const cf = claudeFetch({});
  const r = await runDraft({
    store: asStore(m),
    claude: makeClaude({ apiKey: "k", model: "claude-sonnet-5-5", fetch: cf.fetch }),
    now: () => NOW,
  });
  assertEquals([r.drafted, r.queued], [1, 1]);
  assertEquals(m.drafts[0].status, "queued");
  assertEquals(m.topics[0].status, "drafted");
  assertEquals(m.logs[0].decision, "queued");
  // daily capacity used up: the next fired topic waits instead of spending on a draft
  m.drafts[0].published_at = NOW.toISOString();
  m.topics.push({ ...topic, id: "7f3c2a10-0000-4000-8000-000000000002", status: "fired" });
  const before = cf.calls.length;
  const r2 = await runDraft({
    store: asStore(m),
    claude: makeClaude({ apiKey: "k", model: "claude-sonnet-5-5", fetch: cf.fetch }),
    now: () => NOW,
  });
  assertEquals(r2.waiting_cap, 1);
  assertEquals(cf.calls.length, before);
});
