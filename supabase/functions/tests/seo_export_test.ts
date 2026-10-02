// seo-export: data checks (anonymity floor, slugs, duplicates), upload path,
// deploy hook (dry run when unset, URL never logged) and run bookkeeping.
import { assert, assertEquals, assertFalse, assertRejects } from "@std/assert";
import {
  checkSeoData,
  type ExportRpcResult,
  exportPath,
  runSeoExport,
  type SeoData,
  type SeoExportDeps,
  SeoExportError,
} from "../_shared/seo_export.ts";

const HOOK = "https://api.vercel.com/v1/integrations/deploy/prj_x/secret-hook-id";

function data(over: Partial<SeoData> = {}): SeoData {
  return {
    country: "usa",
    generated_at: "2026-10-02T02:40:00Z",
    thresholds: { min_quotes: 10, min_sellers: 3, window_days: 90, stale_days: 90 },
    categories: [{ slug: "refrigerators", policy: "allowed" }, { slug: "hvac", policy: "restricted" }],
    cities: [{ slug: "dallas" }, { slug: "highland-park", merge_into: "dallas" }],
    pages: [
      {
        city: "dallas",
        category: "refrigerators",
        quotes_window: 37,
        sellers_window: 12,
        last_quote_at: "2026-09-30T00:00:00Z",
        period: { from: "2026-07-04", to: "2026-10-02" },
        price: { median: 1450, p25: 1100, p75: 1890 },
        top_models: [{ name: "Model A", quotes: 9 }],
      },
    ],
    guides: [{ slug: "fridge-size", status: "published" }],
    sellers: [],
    ...over,
  };
}

interface World {
  deps: SeoExportDeps;
  uploads: { path: string; body: string }[];
  finished: unknown[][];
  logs: string[];
  hookCalls: string[];
}

function world(o: { result?: ExportRpcResult; hook?: string; hookStatus?: number; uploadFails?: boolean } = {}): World {
  const w: World = { uploads: [], finished: [], logs: [], hookCalls: [], deps: undefined as unknown as SeoExportDeps };
  w.deps = {
    runExport: (_by, dryRun) => Promise.resolve(o.result ?? { run_id: dryRun ? null : 7, country: "usa", data: data() }),
    upload: (path, body) => {
      if (o.uploadFails) return Promise.reject(new Error("bucket missing"));
      w.uploads.push({ path, body });
      return Promise.resolve();
    },
    finish: (...args) => {
      w.finished.push(args);
      return Promise.resolve();
    },
    fetch: ((url: string, init?: RequestInit) => {
      w.hookCalls.push(`${init?.method} ${url}`);
      return Promise.resolve(new Response("{}", { status: o.hookStatus ?? 201 }));
    }) as typeof fetch,
    deployHookUrl: o.hook,
    publicUrl: (p) => `https://ref.supabase.co/storage/v1/object/public/public-data/${p}`,
    log: (msg, extra) => w.logs.push(`${msg} ${extra ? JSON.stringify(extra) : ""}`),
  };
  return w;
}

Deno.test("export path per country", () => {
  assertEquals(exportPath("usa"), "seo/usa.json");
  assertEquals(exportPath("india"), "seo/india.json");
  let threw = false;
  try {
    exportPath("../etc");
  } catch {
    threw = true;
  }
  assert(threw);
});

Deno.test("valid data passes the checks", () => {
  assertEquals(checkSeoData(data()), []);
});

Deno.test("no price, models or medians below the thresholds (no single-quote leakage)", () => {
  const leaky = data({
    pages: [{
      city: "dallas",
      category: "refrigerators",
      quotes_window: 1,
      sellers_window: 1,
      last_quote_at: "2026-09-30T00:00:00Z",
      period: { from: "2026-07-04", to: "2026-10-02" },
      price: { median: 999, p25: 999, p75: 999 },
    }],
  });
  assertEquals(checkSeoData(leaky), ["page dallas/refrigerators: price details below the thresholds"]);
  const models = data({
    pages: [{ ...data().pages[0], price: null, quotes_window: 9, top_models: [{ name: "X", quotes: 9 }] }],
  });
  assertEquals(checkSeoData(models), ["page dallas/refrigerators: price details below the thresholds"]);
  const counts = data({ pages: [{ ...data().pages[0], price: null, top_models: [], quotes_window: 2, sellers_window: 1 }] });
  assertEquals(checkSeoData(counts), [], "counts alone are fine below the thresholds");
});

Deno.test("thresholds floor, slugs, duplicates, restricted categories, guide status", () => {
  const t = data({ thresholds: { min_quotes: 1, min_sellers: 1, window_days: 90, stale_days: 90 } });
  assert(checkSeoData(t).some((e) => e.includes("anonymity floor")));
  assert(checkSeoData(data({ cities: [{ slug: "Dallas TX" }] })).some((e) => e.includes('bad slug "Dallas TX"')));
  const dup = data({ pages: [data().pages[0], data().pages[0]] });
  assert(checkSeoData(dup).includes("duplicate page dallas/refrigerators"));
  const restricted = data({ pages: [{ ...data().pages[0], category: "hvac" }] });
  assert(checkSeoData(restricted).includes("page dallas/hvac: category policy restricted"));
  assert(checkSeoData(data({ guides: [{ slug: "draft-guide", status: "draft" }] })).some((e) => e.includes("must not be exported")));
  assert(checkSeoData(data({ pages: [{ ...data().pages[0], price: { median: 10, p25: 20, p75: 30 } }] }))
    .some((e) => e.includes("inconsistent price range")));
});

Deno.test("run: uploads seo/<country>.json, triggers the deploy hook, records the run", async () => {
  const w = world({ hook: HOOK });
  const s = await runSeoExport(w.deps, { triggeredBy: "cron" });
  assertEquals(w.uploads.length, 1);
  assertEquals(w.uploads[0].path, "seo/usa.json");
  assertEquals(JSON.parse(w.uploads[0].body).country, "usa");
  assertEquals(w.hookCalls, [`POST ${HOOK}`]);
  assertEquals(s.deploy_hook, "triggered");
  assertEquals(s.public_url, "https://ref.supabase.co/storage/v1/object/public/public-data/seo/usa.json");
  assertEquals(s.priced_pages, 1);
  assertEquals(w.finished, [[7, "seo/usa.json", true, "triggered", null]]);
  assertFalse(w.logs.join("\n").includes("secret-hook-id"), "the deploy hook URL is never logged");
});

Deno.test("run without VERCEL_DEPLOY_HOOK_APP_SITE: upload + dry-run log, no fetch", async () => {
  const w = world();
  const s = await runSeoExport(w.deps, { triggeredBy: "cron" });
  assertEquals(s.deploy_hook, "dry_run");
  assertEquals(w.hookCalls, []);
  assert(w.logs.some((l) => l.includes("dry run")));
  assertEquals(w.finished[0][3], "dry_run");
});

Deno.test("deploy hook failure is recorded but the upload stands", async () => {
  const w = world({ hook: HOOK, hookStatus: 500 });
  const s = await runSeoExport(w.deps, { triggeredBy: "cron" });
  assert(s.uploaded);
  assertEquals(s.deploy_hook, "failed");
  assertEquals(w.finished, [[7, "seo/usa.json", true, "failed", "deploy_hook_failed"]]);
});

Deno.test("dry_run: nothing uploaded, no hook", async () => {
  const w = world({ hook: HOOK });
  const s = await runSeoExport(w.deps, { triggeredBy: "admin:x", dryRun: true });
  assertEquals(s.dry_run, true);
  assertEquals(w.uploads, []);
  assertEquals(w.hookCalls, []);
  assertEquals(s.run_id, null);
});

Deno.test("failed data check: nothing uploaded, run marked failed", async () => {
  const bad = data({ pages: [{ ...data().pages[0], quotes_window: 2 }] });
  const w = world({ hook: HOOK, result: { run_id: 9, country: "usa", data: bad } });
  const err = await assertRejects(() => runSeoExport(w.deps, { triggeredBy: "cron" }), SeoExportError);
  assertEquals(err.code, "export_check_failed");
  assertEquals(w.uploads, []);
  assertEquals(w.hookCalls, []);
  assertEquals(w.finished.length, 1);
  assertEquals(w.finished[0][2], false);
});

Deno.test("upload failure: no hook, run marked failed", async () => {
  const w = world({ hook: HOOK, uploadFails: true });
  const err = await assertRejects(() => runSeoExport(w.deps, { triggeredBy: "cron" }), SeoExportError);
  assertEquals(err.code, "upload_failed");
  assertEquals(w.hookCalls, []);
  assertEquals(w.finished[0][2], false);
});
