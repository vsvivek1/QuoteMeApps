// Runtime wiring shared by trends-poll / trends-draft / trends-publish: caller auth,
// database, bucket, run bookkeeping and dry runs when credentials are missing.
import { env } from "../env.ts";
import { HttpError, json, readJson, requireMethod } from "../http.ts";
import { adminClient, isServiceCaller, requireAdmin } from "../supabase.ts";
import type { TrendsStorage } from "./run_publish.ts";
import { pgStore, type RunNowGrant, type Store } from "./store.ts";

export const BUCKET = "trends-public";

export type Caller = { kind: "service" } | { kind: "admin"; adminId: string };

/** pg_cron / pg_net (x-webhook-secret), the service role key, or an admin JWT ("run now"). */
export async function authorize(req: Request): Promise<Caller> {
  if (isServiceCaller(req)) return { kind: "service" };
  const ctx = await requireAdmin(req);
  return { kind: "admin", adminId: ctx.user.id };
}

/** 429 for an admin "Run now" past the per-function window (migration 1300). */
export function rateLimitedError(fn: string, g: RunNowGrant): HttpError {
  const retry = Math.max(1, Math.ceil(g.retry_after_seconds || 1));
  return new HttpError(
    429,
    "rate_limited",
    {
      fn,
      limit: g.limit,
      window_seconds: g.window_seconds,
      used: g.used,
      retry_after_seconds: retry,
    },
    `at most ${g.limit} admin runs of ${fn} per ${Math.round(g.window_seconds / 60)} minutes`,
    {
      "Retry-After": String(retry),
    },
  );
}

export interface RunDeps {
  authorize: (req: Request) => Promise<Caller>;
  store: () => Store | null;
}

const defaultDeps: RunDeps = { authorize, store: storeFromEnv };

export function storeFromEnv(): Store | null {
  const url = env("SUPABASE_DB_URL");
  return url ? pgStore(url) : null;
}

export function storageFromEnv(): TrendsStorage | null {
  if (!env("SUPABASE_URL") || !env("SUPABASE_SERVICE_ROLE_KEY")) return null;
  const bucket = () => adminClient().storage.from(BUCKET);
  return {
    async put(path, body) {
      const { error } = await bucket().upload(path, new Blob([body], { type: "application/json" }), {
        upsert: true,
        contentType: "application/json",
        cacheControl: "60",
      });
      if (error) throw new Error(`storage_put ${path}: ${error.message}`);
    },
    async remove(path) {
      const { error } = await bucket().remove([path]);
      if (error) throw new Error(`storage_remove ${path}: ${error.message}`);
    },
    async get(path) {
      const { data, error } = await bucket().download(path);
      if (error || !data) return null;
      return await data.text();
    },
  };
}

/** Runs one pipeline step with run bookkeeping; without SUPABASE_DB_URL it answers a dry run. */
export async function handleRun(
  req: Request,
  fn: "trends-poll" | "trends-draft" | "trends-publish",
  run: (store: Store, dryRun: boolean) => Promise<unknown>,
  dryRunReason: () => string | null,
  deps: RunDeps = defaultDeps,
): Promise<Response> {
  requireMethod(req, "POST");
  const caller = await deps.authorize(req);
  const body = await readJson<{ action?: string }>(req);
  if ((body.action ?? "run") !== "run") throw new HttpError(400, "unknown_action");
  const store = deps.store();
  if (!store) {
    console.log(`${fn}: SUPABASE_DB_URL not set; dry run, nothing done`);
    return json({ ok: true, dry_run: true, reason: "missing SUPABASE_DB_URL" });
  }
  const reason = dryRunReason();
  let runId: number | null = null;
  try {
    if (caller.kind === "admin") {
      // Admin "Run now": at most N per function per hour per project, so clicks cannot run up
      // model spend. The check records the run atomically; a refusal records nothing.
      const grant = await store.startAdminRun(fn, !!reason, caller.adminId);
      if (!grant.allowed) throw rateLimitedError(fn, grant);
      runId = Number(grant.run_id);
    } else {
      runId = await store.startRun(fn, !!reason);
    }
    const stats = await run(store, !!reason);
    await store.finishRun(runId, true, stats);
    return json({ ok: true, dry_run: !!reason, ...(reason ? { reason } : {}), stats });
  } catch (e) {
    if (e instanceof HttpError && e.status === 429) throw e;
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`${fn} failed`, msg);
    if (runId !== null) await store.finishRun(runId, false, {}, msg.slice(0, 1000)).catch(() => {});
    throw new HttpError(500, "trends_run_failed", msg.slice(0, 300));
  } finally {
    await store.close().catch(() => {});
  }
}
