// Runtime wiring shared by trends-poll / trends-draft / trends-publish: caller auth,
// database, bucket, run bookkeeping and dry runs when credentials are missing.
import { env } from "../env.ts";
import { HttpError, json, readJson, requireMethod } from "../http.ts";
import { adminClient, isServiceCaller, requireAdmin } from "../supabase.ts";
import type { TrendsStorage } from "./run_publish.ts";
import { pgStore, type Store } from "./store.ts";

export const BUCKET = "trends-public";

/** pg_cron / pg_net (x-webhook-secret), the service role key, or an admin JWT ("run now"). */
export async function authorize(req: Request): Promise<"service" | "admin"> {
  if (isServiceCaller(req)) return "service";
  await requireAdmin(req);
  return "admin";
}

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
): Promise<Response> {
  requireMethod(req, "POST");
  await authorize(req);
  const body = await readJson<{ action?: string }>(req);
  if ((body.action ?? "run") !== "run") throw new HttpError(400, "unknown_action");
  const store = storeFromEnv();
  if (!store) {
    console.log(`${fn}: SUPABASE_DB_URL not set; dry run, nothing done`);
    return json({ ok: true, dry_run: true, reason: "missing SUPABASE_DB_URL" });
  }
  const reason = dryRunReason();
  let runId: number | null = null;
  try {
    runId = await store.startRun(fn, !!reason);
    const stats = await run(store, !!reason);
    await store.finishRun(runId, true, stats);
    return json({ ok: true, dry_run: !!reason, ...(reason ? { reason } : {}), stats });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`${fn} failed`, msg);
    if (runId !== null) await store.finishRun(runId, false, {}, msg.slice(0, 1000)).catch(() => {});
    throw new HttpError(500, "trends_run_failed", msg.slice(0, 300));
  } finally {
    await store.close().catch(() => {});
  }
}
