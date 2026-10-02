// Nightly SEO export (brief Section 21.9): the testable core of the
// `seo-export` Edge Function. The database function public.seo_export()
// computes the aggregated, anonymised data; this module re-checks it
// (defence in depth: no price below the thresholds, valid slugs, no
// duplicates), uploads it to the public bucket and calls the Vercel Deploy
// Hook. Every side effect goes through `SeoExportDeps`, so tests use fakes.

export interface SeoThresholds {
  min_quotes: number;
  min_sellers: number;
  window_days: number;
  stale_days: number;
}

export interface SeoPageRow {
  city: string;
  category: string;
  quotes_window: number;
  sellers_window: number;
  local_sellers?: number;
  last_quote_at: string;
  period: { from: string; to: string };
  price?: { median: number; p25: number; p75: number } | null;
  median_response_hours?: number | null;
  median_delivery_days?: number | null;
  trend_pct_vs_last_month?: number | null;
  top_models?: { name: string; quotes: number }[];
  manual_noindex?: boolean;
}

export interface SeoData {
  country: "usa" | "india";
  generated_at: string;
  thresholds: SeoThresholds;
  categories: { slug: string; policy: string }[];
  cities: { slug: string; merge_into?: string | null }[];
  pages: SeoPageRow[];
  guides?: { slug: string; status: string }[];
  sellers?: { slug: string }[];
  [k: string]: unknown;
}

export interface ExportRpcResult {
  run_id: number | null;
  country: "usa" | "india";
  data: SeoData;
}

export type DeployHookStatus = "triggered" | "dry_run" | "failed" | "skipped";

export interface SeoExportDeps {
  /** public.seo_export(p_triggered_by, p_dry_run) with the service role. */
  runExport(triggeredBy: string, dryRun: boolean): Promise<ExportRpcResult>;
  /** Upload (upsert) a JSON object to the public bucket. */
  upload(path: string, body: string): Promise<void>;
  /** public.seo_finish_export(...). */
  finish(runId: number, path: string | null, uploadOk: boolean, deployHook: DeployHookStatus, error: string | null): Promise<void>;
  fetch: typeof fetch;
  /** VERCEL_DEPLOY_HOOK_APP_SITE (undefined = dry-run log only). Never logged. */
  deployHookUrl?: string;
  publicUrl(path: string): string;
  log(msg: string, extra?: Record<string, unknown>): void;
}

export interface SeoExportOptions {
  triggeredBy: string;
  dryRun?: boolean;
  /** Skip the deploy hook even when configured (e.g. a manual check run). */
  skipDeploy?: boolean;
}

export interface SeoExportSummary {
  run_id: number | null;
  country: string;
  path: string;
  public_url: string;
  dry_run: boolean;
  pages: number;
  priced_pages: number;
  guides: number;
  sellers: number;
  bytes: number;
  uploaded: boolean;
  deploy_hook: DeployHookStatus;
}

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export function exportPath(country: string): string {
  if (country !== "usa" && country !== "india") throw new Error(`invalid_country:${country}`);
  return `seo/${country}.json`;
}

/**
 * Same structural checks as web/app_site/src/lib/seo.ts (validate) plus the
 * anonymity rules. Returns a list of problems (empty = OK).
 */
export function checkSeoData(d: SeoData): string[] {
  const errs: string[] = [];
  if (d.country !== "usa" && d.country !== "india") errs.push(`bad country ${d.country}`);
  if (Number.isNaN(Date.parse(d.generated_at))) errs.push("generated_at is not an ISO date");
  for (const key of ["categories", "cities", "pages"] as const) {
    if (!Array.isArray(d[key])) errs.push(`${key} must be an array`);
  }
  if (errs.length) return errs;
  const t = d.thresholds;
  if (!t || !(t.min_quotes >= 3) || !(t.min_sellers >= 2)) errs.push("thresholds below the anonymity floor (3 quotes / 2 sellers)");
  for (const c of [...d.categories, ...d.cities]) if (!SLUG.test(c.slug)) errs.push(`bad slug "${c.slug}"`);
  const cityDupes = dupes(d.cities.map((c) => c.slug));
  if (cityDupes.length) errs.push(`duplicate city slugs: ${cityDupes.join(", ")}`);
  const cats = new Map(d.categories.map((c) => [c.slug, c]));
  const cities = new Set(d.cities.map((c) => c.slug));
  const seen = new Set<string>();
  for (const p of d.pages) {
    const key = `${p.city}/${p.category}`;
    if (seen.has(key)) errs.push(`duplicate page ${key}`);
    seen.add(key);
    if (!cities.has(p.city)) errs.push(`page ${key}: unknown city`);
    const cat = cats.get(p.category);
    if (!cat) errs.push(`page ${key}: unknown category`);
    else if (cat.policy !== "allowed") errs.push(`page ${key}: category policy ${cat.policy}`);
    const enough = t && p.quotes_window >= t.min_quotes && p.sellers_window >= t.min_sellers;
    const detail = p.price != null || (p.top_models?.length ?? 0) > 0 || p.median_delivery_days != null ||
      p.median_response_hours != null || p.trend_pct_vs_last_month != null;
    if (detail && !enough) errs.push(`page ${key}: price details below the thresholds`);
    if (p.price && !(p.price.p25 > 0 && p.price.median >= p.price.p25 && p.price.p75 >= p.price.median)) {
      errs.push(`page ${key}: inconsistent price range`);
    }
  }
  for (const g of d.guides ?? []) {
    if (!SLUG.test(g.slug)) errs.push(`bad guide slug "${g.slug}"`);
    if (g.status !== "approved" && g.status !== "published") errs.push(`guide ${g.slug}: status ${g.status} must not be exported`);
  }
  return errs;
}

function dupes(xs: string[]): string[] {
  const seen = new Set<string>();
  const out = new Set<string>();
  for (const x of xs) (seen.has(x) ? out : seen).add(x);
  return [...out];
}

/** POST the Vercel Deploy Hook (no body needed). The URL is never logged. */
export async function triggerDeployHook(
  deps: Pick<SeoExportDeps, "fetch" | "deployHookUrl" | "log">,
): Promise<DeployHookStatus> {
  if (!deps.deployHookUrl) {
    deps.log("seo-export: VERCEL_DEPLOY_HOOK_APP_SITE not set, dry run (no rebuild triggered)");
    return "dry_run";
  }
  try {
    const res = await deps.fetch(deps.deployHookUrl, { method: "POST" });
    await res.body?.cancel();
    if (!res.ok) {
      deps.log("seo-export: deploy hook failed", { status: res.status });
      return "failed";
    }
    return "triggered";
  } catch (e) {
    deps.log("seo-export: deploy hook error", { error: String(e) });
    return "failed";
  }
}

export async function runSeoExport(deps: SeoExportDeps, opts: SeoExportOptions): Promise<SeoExportSummary> {
  const dryRun = opts.dryRun === true;
  const res = await deps.runExport(opts.triggeredBy, dryRun);
  const path = exportPath(res.country);
  const body = JSON.stringify(res.data);
  const problems = checkSeoData(res.data);
  const summary: SeoExportSummary = {
    run_id: res.run_id,
    country: res.country,
    path,
    public_url: deps.publicUrl(path),
    dry_run: dryRun,
    pages: res.data.pages.length,
    priced_pages: res.data.pages.filter((p) => p.price).length,
    guides: res.data.guides?.length ?? 0,
    sellers: res.data.sellers?.length ?? 0,
    bytes: new TextEncoder().encode(body).length,
    uploaded: false,
    deploy_hook: "skipped",
  };

  if (problems.length) {
    const msg = `export_check_failed: ${problems.slice(0, 10).join("; ")}`;
    deps.log("seo-export: data check failed, nothing uploaded", { problems: problems.slice(0, 20) });
    if (res.run_id != null) await deps.finish(res.run_id, null, false, "skipped", msg);
    throw new SeoExportError("export_check_failed", problems);
  }
  if (dryRun) return summary;

  try {
    await deps.upload(path, body);
    summary.uploaded = true;
  } catch (e) {
    if (res.run_id != null) await deps.finish(res.run_id, path, false, "skipped", `upload_failed: ${String(e)}`);
    throw new SeoExportError("upload_failed", [String(e)]);
  }

  summary.deploy_hook = opts.skipDeploy ? "skipped" : await triggerDeployHook(deps);
  if (res.run_id != null) {
    await deps.finish(res.run_id, path, true, summary.deploy_hook,
      summary.deploy_hook === "failed" ? "deploy_hook_failed" : null);
  }
  deps.log("seo-export: done", { ...summary });
  return summary;
}

export class SeoExportError extends Error {
  constructor(public code: string, public problems: string[]) {
    super(code);
  }
}
