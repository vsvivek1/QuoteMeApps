// Trends "Run now" (migration 1300): an admin JWT may start each trends function at most
// `limit` times per window; past that handleRun answers 429 rate_limited with Retry-After and
// runs nothing. Cron / service callers are never limited. (The SQL side, trends.start_admin_run,
// is covered by supabase/tests/database/21_trends_run_now.test.sql.)
import { assert, assertEquals } from "@std/assert";
import { errorResponse, HttpError } from "../_shared/http.ts";
import { type Caller, handleRun, rateLimitedError, type RunDeps } from "../_shared/trends/runtime.ts";
import type { RunNowGrant, Store } from "../_shared/trends/store.ts";

class FakeStore {
  limit = 6;
  adminRuns: { fn: string; actor: string; dryRun: boolean }[] = [];
  cronRuns: string[] = [];
  finished: { id: number; ok: boolean }[] = [];
  closed = 0;
  startRun(fn: string) {
    this.cronRuns.push(fn);
    return Promise.resolve(1000 + this.cronRuns.length);
  }
  startAdminRun(fn: string, dryRun: boolean, actor: string): Promise<RunNowGrant> {
    const used = this.adminRuns.filter((r) => r.fn === fn).length;
    const base = { limit: this.limit, window_seconds: 3600 };
    if (used >= this.limit) {
      return Promise.resolve({ ...base, allowed: false, used, remaining: 0, retry_after_seconds: 754.2 });
    }
    this.adminRuns.push({ fn, actor, dryRun });
    return Promise.resolve({
      ...base,
      allowed: true,
      run_id: this.adminRuns.length,
      used: used + 1,
      remaining: this.limit - used - 1,
      retry_after_seconds: 0,
    });
  }
  finishRun(id: number, ok: boolean) {
    this.finished.push({ id, ok });
    return Promise.resolve();
  }
  close() {
    this.closed++;
    return Promise.resolve();
  }
}

const post = () =>
  new Request("http://x/trends-draft", { method: "POST", body: JSON.stringify({ action: "run" }) });
const deps = (store: FakeStore | null, caller: Caller): RunDeps => ({
  authorize: () => Promise.resolve(caller),
  store: () => store as unknown as Store | null,
});
const ADMIN: Caller = { kind: "admin", adminId: "00000000-0000-4000-8000-000000000001" };

/** handleRun through the same error mapping as serve(). */
async function call(
  store: FakeStore | null,
  caller: Caller,
  run: () => Promise<unknown>,
  fn = "trends-draft" as const,
) {
  try {
    return await handleRun(post(), fn, run, () => null, deps(store, caller));
  } catch (e) {
    if (!(e instanceof HttpError)) throw e;
    return errorResponse(e.status, e.code, e.details, e.hint, e.headers);
  }
}

Deno.test("run now: six admin runs per function, the seventh is 429 with Retry-After and runs nothing", async () => {
  const store = new FakeStore();
  let runs = 0;
  const run = () => {
    runs++;
    return Promise.resolve({ queued: 0 });
  };
  for (let i = 0; i < 6; i++) assertEquals((await call(store, ADMIN, run)).status, 200);
  assertEquals(runs, 6);
  const res = await call(store, ADMIN, run);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("Retry-After"), "755");
  const body = await res.json();
  assertEquals(body.code, "rate_limited");
  assertEquals(body.details, {
    fn: "trends-draft",
    limit: 6,
    window_seconds: 3600,
    used: 6,
    retry_after_seconds: 755,
  });
  assertEquals(runs, 6, "nothing ran");
  assertEquals(store.finished.length, 6, "no run row finished for the refusal");
  assertEquals(store.closed, 7, "the connection is closed either way");
  assertEquals(store.adminRuns[0].actor, ADMIN.kind === "admin" ? ADMIN.adminId : "");
});

Deno.test("run now: the limit is per function; cron callers are never limited", async () => {
  const store = new FakeStore();
  store.limit = 1;
  const run = () => Promise.resolve({});
  assertEquals((await call(store, ADMIN, run, "trends-draft")).status, 200);
  assertEquals((await call(store, ADMIN, run, "trends-draft")).status, 429);
  assertEquals((await handleRun(post(), "trends-poll", run, () => null, deps(store, ADMIN))).status, 200);
  for (let i = 0; i < 10; i++) {
    assertEquals((await call(store, { kind: "service" }, run)).status, 200);
  }
  assertEquals(store.cronRuns.length, 10, "cron runs use startRun, not the admin window");
});

Deno.test("run now: admin runs are recorded by the grant and finished with their stats", async () => {
  const store = new FakeStore();
  const res = await handleRun(
    post(),
    "trends-publish",
    () => Promise.resolve({ published: [] }),
    () => "no bucket",
    deps(store, ADMIN),
  );
  assertEquals(await res.json(), { ok: true, dry_run: true, reason: "no bucket", stats: { published: [] } });
  assertEquals(store.adminRuns, [{
    fn: "trends-publish",
    actor: ADMIN.kind === "admin" ? ADMIN.adminId : "",
    dryRun: true,
  }]);
  assertEquals(store.finished, [{ id: 1, ok: true }]);
});

Deno.test("run now: without a database it is a dry run and is not limited", async () => {
  const res = await call(null, ADMIN, () => Promise.reject(new Error("must not run")));
  assertEquals(res.status, 200);
  assertEquals((await res.json()).dry_run, true);
});

Deno.test("rateLimitedError: Retry-After is a whole number of seconds, at least 1", () => {
  const g = { allowed: false, used: 6, limit: 6, remaining: 0, window_seconds: 3600, retry_after_seconds: 0 };
  const e = rateLimitedError("trends-poll", g);
  assertEquals([e.status, e.code, e.headers?.["Retry-After"]], [429, "rate_limited", "1"]);
  assert(e.hint?.includes("60 minutes"));
});

Deno.test("errorResponse (used by serve for HttpError) carries extra headers next to CORS", () => {
  const res = errorResponse(429, "rate_limited", null, undefined, { "Retry-After": "30" });
  assertEquals(res.headers.get("Retry-After"), "30");
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
});
