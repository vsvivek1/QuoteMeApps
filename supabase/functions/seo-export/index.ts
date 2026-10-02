// seo-export: nightly SEO data export for web/app_site (brief Section 21.9).
//
// 1. public.seo_export() (service role) computes the aggregated, anonymised
//    city x category stats, guides and opted-in seller directory entries and
//    refreshes seo_pages;
// 2. the JSON is checked again and uploaded to the public bucket
//    (SEO_PUBLIC_BUCKET, default "public-data") at seo/<country>.json;
// 3. the Vercel Deploy Hook in VERCEL_DEPLOY_HOOK_APP_SITE is POSTed so the
//    site rebuilds (dry-run log when unset).
//
// Callers: pg_cron (x-webhook-secret, job iwant-seo-export) or an admin JWT
// (admin panel "Run export now").
// POST { action?: "run", dry_run?: boolean, skip_deploy?: boolean, triggered_by?: string }
import { env, requireEnv } from "../_shared/env.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { enforceRateLimit } from "../_shared/ratelimit.ts";
import { type ExportRpcResult, runSeoExport, SeoExportError } from "../_shared/seo_export.ts";
import { adminClient, isServiceCaller, requireAdmin, unwrap } from "../_shared/supabase.ts";

interface Body {
  action?: string;
  dry_run?: boolean;
  skip_deploy?: boolean;
  triggered_by?: string;
}

serve(async (req) => {
  requireMethod(req, "POST");
  let caller = "cron";
  if (!isServiceCaller(req)) {
    const ctx = await requireAdmin(req);
    caller = `admin:${ctx.user.id}`;
    await enforceRateLimit("seo-export", ctx.user.id, 10, 3600);
  }
  const body = await readJson<Body>(req);
  if (body.action && body.action !== "run") throw new HttpError(400, "unknown_action");

  const db = adminClient();
  const bucket = env("SEO_PUBLIC_BUCKET") ?? "public-data";
  const base = requireEnv("SUPABASE_URL").replace(/\/+$/, "");
  const triggeredBy = caller === "cron" ? (body.triggered_by ?? "cron").slice(0, 40) : caller;

  try {
    const summary = await runSeoExport({
      runExport: async (by, dryRun) =>
        unwrap<ExportRpcResult>(await db.rpc("seo_export", { p_triggered_by: by, p_dry_run: dryRun })),
      upload: async (path, text) => {
        const { error } = await db.storage.from(bucket).upload(path, new Blob([text], { type: "application/json" }), {
          upsert: true,
          contentType: "application/json",
          cacheControl: "300",
        });
        if (error) throw error;
      },
      finish: async (runId, path, uploadOk, deployHook, error) => {
        unwrap(await db.rpc("seo_finish_export", {
          p_run_id: runId,
          p_storage_path: path,
          p_upload_ok: uploadOk,
          p_deploy_hook: deployHook,
          p_error: error,
        }));
      },
      fetch: (input, init) => fetch(input, init),
      deployHookUrl: env("VERCEL_DEPLOY_HOOK_APP_SITE"),
      publicUrl: (path) => `${base}/storage/v1/object/public/${bucket}/${path}`,
      log: (msg, extra) => console.log(msg, extra ? JSON.stringify(extra) : ""),
    }, { triggeredBy, dryRun: body.dry_run === true, skipDeploy: body.skip_deploy === true });
    return json(summary);
  } catch (e) {
    if (e instanceof SeoExportError) throw new HttpError(e.code === "upload_failed" ? 502 : 422, e.code, e.problems.slice(0, 20));
    throw e;
  }
});
