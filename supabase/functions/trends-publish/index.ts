// trends-publish (brief Section 21.10): every 5 minutes from pg_cron, or an admin "run now".
// Applies the ramp (automatic step-down on bad health), the kill switch and the caps (gate 6),
// writes each passing article to the public bucket trends-public at articles/<slug>.json plus
// index.json, re-uploads articles with new Update sections / corrections, marks superseded and
// dead-traffic articles noindex, removes unpublished ones, and POSTs VERCEL_DEPLOY_HOOK_TRENDS_SITE
// (when set) whenever the index changed.
//
// Without SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (bucket access) the run is a dry run.
// POST { action: "run" } -> { ok, dry_run, stats }
import { env } from "../_shared/env.ts";
import { serve } from "../_shared/http.ts";
import { runPublish } from "../_shared/trends/run_publish.ts";
import { handleRun, storageFromEnv } from "../_shared/trends/runtime.ts";

serve((req) =>
  handleRun(
    req,
    "trends-publish",
    (store) =>
      runPublish({
        store,
        storage: storageFromEnv(),
        deployHook: env("VERCEL_DEPLOY_HOOK_TRENDS_SITE") ?? null,
        fetch,
        now: () => new Date(),
      }),
    () => (storageFromEnv() ? null : "missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY: nothing uploaded"),
  )
);
