// trends-poll (brief Section 21.10): every 5 minutes from pg_cron (x-webhook-secret), or an
// admin "run now". Polls Google Trends trending-searches RSS per geo, Google News RSS per place
// (headlines + links only) and Reddit (official API, only when REDDIT_CLIENT_ID / _SECRET are
// set), stores trend_signals, clusters duplicates, recomputes velocity and fires topics.
//
// POST { action: "run" } -> { ok, dry_run, stats: { sources, signals_seen, signals_new, topics_new, fired, ... } }
// Without SUPABASE_DB_URL the call is a dry run.
import { env } from "../_shared/env.ts";
import { serve } from "../_shared/http.ts";
import { runPoll } from "../_shared/trends/run_poll.ts";
import { handleRun } from "../_shared/trends/runtime.ts";

serve((req) =>
  handleRun(req, "trends-poll", (store) => {
    const id = env("REDDIT_CLIENT_ID");
    const secret = env("REDDIT_CLIENT_SECRET");
    const reddit = id && secret
      ? {
        clientId: id,
        clientSecret: secret,
        userAgent: env("REDDIT_USER_AGENT") ?? "web:trends-pipeline:1.0 (by /u/unset)",
      }
      : null;
    return runPoll({ store, fetch, reddit, now: () => new Date() });
  }, () => null)
);
