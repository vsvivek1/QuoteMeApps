// Database access for the trends pipeline. The trends schema is deliberately NOT exposed
// through PostgREST, so the Edge Functions talk to Postgres directly with SUPABASE_DB_URL
// (provided to every Supabase Edge Function; use the transaction pooler URL, hence prepare:false).
// Rows are read as to_jsonb(...) so timestamps arrive as ISO strings and numerics as numbers.
import postgres from "postgres";
import type { ClusterTopic } from "./cluster.ts";
import { settingsFromRows } from "./settings.ts";
import type { Country, Draft, Health, Settings, Signal, SignalInput, Topic, TrendSource } from "./types.ts";

type Sql = ReturnType<typeof postgres>;

export interface TopicStats {
  topic_id: string;
  domains: string[];
  signal_count: number;
}

export interface Store {
  settings(): Promise<Settings>;
  saveSetting(key: string, value: unknown): Promise<void>;
  startRun(fn: string, dryRun: boolean): Promise<number>;
  finishRun(id: number, ok: boolean, stats: unknown, error?: string | null): Promise<void>;
  log(
    decision: string,
    reason: string | null,
    draft: Pick<Draft, "id" | "topic_id" | "slug" | "country"> | null,
    details?: unknown,
  ): Promise<void>;

  enabledSources(): Promise<TrendSource[]>;
  markSource(id: number, status: string, items: number, error?: string | null): Promise<void>;
  activeTopics(ttlHours: number, mergeDays: number): Promise<Topic[]>;
  existingSignals(
    keys: { source_kind: string; place_slug: string; dedupe_key: string }[],
  ): Promise<Map<string, string | null>>;
  createTopics(topics: ClusterTopic[]): Promise<Map<string, string>>;
  setAltTitles(id: string, alt: string[]): Promise<void>;
  upsertSignals(rows: (SignalInput & { topic_id: string | null })[]): Promise<number>;
  recentSignals(topicIds: string[], sinceMinutes: number): Promise<Map<string, Signal[]>>;
  topicStats(topicIds: string[], nonPublisher: string[]): Promise<Map<string, TopicStats>>;
  updateTopic(id: string, patch: Record<string, unknown>): Promise<void>;

  firedTopics(limit: number): Promise<Topic[]>;
  getTopic(id: string): Promise<Topic | null>;
  topicSignals(topicId: string, limit?: number): Promise<Signal[]>;
  pendingDrafts(): Promise<Draft[]>;
  insertDraft(row: Record<string, unknown>): Promise<string>;
  updateDraft(id: string, patch: Record<string, unknown>): Promise<void>;
  publishedTimes(sinceHours: number): Promise<Record<Country, string[]>>;
  publishedWithNewSignals(
    minIntervalMinutes: number,
  ): Promise<{ draft: Draft; topic: Topic; signals: Signal[] }[]>;
  latestHealth(country: Country): Promise<Health | null>;

  queuedReady(): Promise<Draft[]>;
  needsUpload(): Promise<(Draft & { topic_ended_at: string | null })[]>;
  indexRows(): Promise<
    {
      slug: string;
      country: Country;
      published_at: string;
      updated_at: string;
      noindex: boolean;
      storage_path: string;
    }[]
  >;
  close(): Promise<void>;
}

const DRAFT_PATCH_COLS = new Set([
  "slug",
  "status",
  "article",
  "gates",
  "failed_gate",
  "reason",
  "sensitive",
  "sensitive_reasons",
  "review_stage",
  "model",
  "rewrites",
  "velocity",
  "published_at",
  "last_update_at",
  "superseded_by",
  "noindex_reason",
  "storage_path",
  "dirty",
]);
const TOPIC_PATCH_COLS = new Set([
  "status",
  "velocity",
  "peak_velocity",
  "signal_count",
  "domain_count",
  "domains",
  "domains_at_reject",
  "fired_at",
  "ended_at",
  "status_reason",
  "article_slug",
  "last_seen",
]);
const JSON_COLS = new Set(["article", "gates"]);

function patchSql(sql: Sql, patch: Record<string, unknown>, allowed: Set<string>) {
  const clean: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(patch)) {
    if (!allowed.has(k)) throw new Error(`unknown column ${k}`);
    // deno-lint-ignore no-explicit-any
    clean[k] = JSON_COLS.has(k) && v !== null ? sql.json(v as any) : v;
  }
  return sql(clean as Record<string, postgres.ParameterOrJSON<never>>, Object.keys(clean));
}

export function pgStore(url: string): Store {
  const sql = postgres(url, {
    prepare: false,
    max: 2,
    idle_timeout: 10,
    connect_timeout: 10,
    onnotice: () => {},
  });
  const j = <T>(rows: { j: unknown }[]) => rows.map((r) => r.j as T);

  return {
    async settings() {
      const rows = await sql<{ key: string; value: unknown }[]>`select key, value from trends.trend_settings`;
      return settingsFromRows(rows);
    },
    async saveSetting(key, value) {
      // deno-lint-ignore no-explicit-any
      await sql`update trends.trend_settings set value = ${sql.json(value as any)} where key = ${key}`;
    },
    async startRun(fn, dryRun) {
      const [r] = await sql<
        { id: number }[]
      >`insert into trends.trend_runs (fn, dry_run) values (${fn}, ${dryRun}) returning id`;
      return Number(r.id);
    },
    async finishRun(id, ok, stats, error = null) {
      // deno-lint-ignore no-explicit-any
      await sql`update trends.trend_runs set finished_at = now(), ok = ${ok}, stats = ${
        sql.json(stats as any)
      }, error = ${error} where id = ${id}`;
    },
    async log(decision, reason, d, details = {}) {
      await sql`insert into trends.trend_publish_log (draft_id, topic_id, slug, country, decision, reason, details)
        values (${d?.id ?? null}, ${d?.topic_id ?? null}, ${d?.slug ?? null}, ${
        d?.country ?? (details as { country?: string })?.country ?? null
      },
                ${decision}, ${reason}, ${sql.json((details ?? {}) as never)})`;
    },

    async enabledSources() {
      return j<TrendSource>(
        await sql`select to_jsonb(s) as j from trends.trend_sources s where enabled order by id`,
      );
    },
    async markSource(id, status, items, error = null) {
      await sql`update trends.trend_sources set last_polled_at = now(), last_status = ${status}, last_items = ${items},
        last_error = ${error ? error.slice(0, 500) : null} where id = ${id}`;
    },
    async activeTopics(ttlHours, mergeDays) {
      return j<Topic>(
        await sql`select to_jsonb(t) as j from trends.trend_topics t
        where (t.status in ('watching','fired','review','drafted','waiting_sources') and t.last_seen > now() - make_interval(hours => ${ttlHours}))
           or (t.status = 'published' and coalesce(t.fired_at, t.first_seen) > now() - make_interval(days => ${mergeDays}))`,
      );
    },
    async existingSignals(keys) {
      const out = new Map<string, string | null>();
      if (!keys.length) return out;
      const rows = await sql<{ k: string; topic_id: string | null }[]>`
        select s.source_kind || '|' || s.place_slug || '|' || s.dedupe_key as k, s.topic_id
          from trends.trend_signals s
          join unnest(${keys.map((k) => k.source_kind)}::text[], ${keys.map((k) => k.place_slug)}::text[],
                      ${keys.map((k) => k.dedupe_key)}::text[]) as x(kind, place, key)
            on s.source_kind = x.kind and s.place_slug = x.place and s.dedupe_key = x.key`;
      for (const r of rows) out.set(r.k, r.topic_id);
      return out;
    },
    async createTopics(topics) {
      const ids = new Map<string, string>();
      for (const t of topics) {
        const [r] = await sql<{ id: string }[]>`insert into trends.trend_topics
          (country, place_slug, place_name, state, level, title, norm_title, alt_titles)
          values (${t.country}, ${t.place_slug}, ${t.place_name}, ${t.state}, ${t.level}, ${
          t.title.slice(0, 400)
        },
                  ${t.norm_title}, ${t.alt_titles}) returning id`;
        ids.set(t.key, r.id);
      }
      return ids;
    },
    async setAltTitles(id, alt) {
      await sql`update trends.trend_topics set alt_titles = ${alt} where id = ${id}`;
    },
    async upsertSignals(rows) {
      if (!rows.length) return 0;
      let inserted = 0;
      for (let i = 0; i < rows.length; i += 200) {
        const chunk = rows.slice(i, i + 200).map((r) => ({
          source_id: r.source_id,
          source_kind: r.source_kind,
          country: r.country,
          place_slug: r.place_slug,
          geo: r.geo,
          topic: r.topic,
          norm_title: r.norm_title,
          dedupe_key: r.dedupe_key,
          url: r.url,
          publisher: r.publisher,
          publisher_domain: r.publisher_domain,
          citable: r.citable,
          snippet: r.snippet,
          score: r.score,
          topic_id: r.topic_id,
        }));
        const res = await sql<{ inserted: boolean }[]>`insert into trends.trend_signals ${
          sql(
            chunk,
            "source_id",
            "source_kind",
            "country",
            "place_slug",
            "geo",
            "topic",
            "norm_title",
            "dedupe_key",
            "url",
            "publisher",
            "publisher_domain",
            "citable",
            "snippet",
            "score",
            "topic_id",
          )
        }
          on conflict (source_kind, place_slug, dedupe_key) do update
            set last_seen = now(), seen_count = trends.trend_signals.seen_count + 1,
                score = greatest(trends.trend_signals.score, excluded.score),
                snippet = coalesce(trends.trend_signals.snippet, excluded.snippet),
                topic_id = coalesce(trends.trend_signals.topic_id, excluded.topic_id)
          returning (xmax = 0) as inserted`;
        inserted += res.filter((r) => r.inserted).length;
      }
      return inserted;
    },
    async recentSignals(topicIds, sinceMinutes) {
      const out = new Map<string, Signal[]>();
      if (!topicIds.length) return out;
      const rows = await sql<{ j: Signal }[]>`select to_jsonb(s) as j from trends.trend_signals s
        where s.topic_id = any(${topicIds}::uuid[]) and s.last_seen > now() - make_interval(mins => ${sinceMinutes})`;
      for (const r of rows) {
        const k = r.j.topic_id!;
        out.set(k, [...(out.get(k) ?? []), r.j]);
      }
      return out;
    },
    async topicStats(topicIds, nonPublisher) {
      const out = new Map<string, TopicStats>();
      if (!topicIds.length) return out;
      const rows = await sql<TopicStats[]>`select topic_id,
          coalesce(array_agg(distinct publisher_domain) filter (where citable and publisher_domain is not null
                   and not publisher_domain = any(${nonPublisher}::text[])), '{}') as domains,
          count(*)::int as signal_count
        from trends.trend_signals where topic_id = any(${topicIds}::uuid[]) group by topic_id`;
      for (const r of rows) out.set(r.topic_id, { ...r, domains: [...r.domains].sort() });
      return out;
    },
    async updateTopic(id, patch) {
      await sql`update trends.trend_topics set ${patchSql(sql, patch, TOPIC_PATCH_COLS)} where id = ${id}`;
    },

    async firedTopics(limit) {
      return j<Topic>(
        await sql`select to_jsonb(t) as j from trends.trend_topics t
        where t.status = 'fired' and not exists (
          select 1 from trends.trend_drafts d where d.topic_id = t.id and d.status in ('queued','review','published','noindex'))
        order by t.velocity desc, t.fired_at limit ${limit}`,
      );
    },
    async getTopic(id) {
      return j<Topic>(await sql`select to_jsonb(t) as j from trends.trend_topics t where id = ${id}`)[0] ??
        null;
    },
    async topicSignals(topicId, limit = 200) {
      return j<Signal>(
        await sql`select to_jsonb(s) as j from trends.trend_signals s where topic_id = ${topicId}
        order by first_seen desc limit ${limit}`,
      );
    },
    async pendingDrafts() {
      return j<Draft>(
        await sql`select to_jsonb(d) as j from trends.trend_drafts d
        where d.status = 'queued' and d.article is null order by d.velocity desc, d.created_at`,
      );
    },
    async insertDraft(row) {
      const cols = Object.keys(row);
      const vals: Record<string, unknown> = {};
      // deno-lint-ignore no-explicit-any
      for (const c of cols) vals[c] = JSON_COLS.has(c) && row[c] !== null ? sql.json(row[c] as any) : row[c];
      const [r] = await sql<{ id: string }[]>`insert into trends.trend_drafts ${
        sql(vals as never, cols)
      } returning id`;
      return r.id;
    },
    async updateDraft(id, patch) {
      await sql`update trends.trend_drafts set ${patchSql(sql, patch, DRAFT_PATCH_COLS)} where id = ${id}`;
    },
    async publishedTimes(sinceHours) {
      const rows = await sql<
        { country: Country; at: string }[]
      >`select country, to_jsonb(published_at) #>> '{}' as at
        from trends.trend_drafts where published_at > now() - make_interval(hours => ${sinceHours})`;
      const out: Record<Country, string[]> = { usa: [], india: [] };
      for (const r of rows) out[r.country].push(r.at);
      return out;
    },
    async publishedWithNewSignals(minIntervalMinutes) {
      const rows = await sql<{ d: Draft; t: Topic }[]>`select to_jsonb(d) as d, to_jsonb(t) as t
        from trends.trend_drafts d join trends.trend_topics t on t.id = d.topic_id
        where d.status = 'published' and t.status = 'published'
          and coalesce(d.last_update_at, d.published_at) < now() - make_interval(mins => ${minIntervalMinutes})
          and exists (select 1 from trends.trend_signals s where s.topic_id = t.id and s.citable
                       and s.first_seen > coalesce(d.last_update_at, d.published_at))
        order by t.velocity desc limit 5`;
      const out = [];
      for (const r of rows) {
        const since = r.d.last_update_at ?? r.d.published_at!;
        const signals = j<Signal>(
          await sql`select to_jsonb(s) as j from trends.trend_signals s
          where s.topic_id = ${r.t.id} and s.first_seen > ${since}::timestamptz order by first_seen limit 50`,
        );
        out.push({ draft: r.d, topic: r.t, signals });
      }
      return out;
    },
    async latestHealth(country) {
      return j<Health>(
        await sql`select to_jsonb(h) as j from trends.trend_health h where country = ${country}
        order by recorded_at desc limit 1`,
      )[0] ?? null;
    },

    async queuedReady() {
      return j<Draft>(
        await sql`select to_jsonb(d) as j from trends.trend_drafts d
        where d.status = 'queued' and d.article is not null and d.slug is not null order by d.velocity desc, d.created_at`,
      );
    },
    async needsUpload() {
      const rows = await sql<
        { d: Draft; ended: string | null }[]
      >`select to_jsonb(d) as d, to_jsonb(t.ended_at) #>> '{}' as ended
        from trends.trend_drafts d left join trends.trend_topics t on t.id = d.topic_id
        where d.status in ('published','noindex') or (d.status = 'rejected' and d.storage_path is not null)`;
      return rows.map((r) => ({ ...r.d, topic_ended_at: r.ended }));
    },
    async indexRows() {
      return await sql`select slug, country, to_jsonb(published_at) #>> '{}' as published_at,
          coalesce(article ->> 'updated_at', to_jsonb(published_at) #>> '{}') as updated_at,
          status = 'noindex' as noindex, storage_path
        from trends.trend_drafts where status in ('published','noindex') and storage_path is not null`;
    },
    async close() {
      await sql.end({ timeout: 5 });
    },
  };
}
