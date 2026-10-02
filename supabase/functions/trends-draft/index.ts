// trends-draft (brief Section 21.10): every 5 minutes from pg_cron, or an admin "run now".
// For fired topics: gate 1 (>= 2 independent publisher domains) and gate 2 (sensitive topics go
// to the human review queue) BEFORE any model call; then the Claude draft in the two-perspective
// format, gate 3 originality (one rewrite, then reject), gate 4 fact consistency (second model
// pass), gate 5 value, the balance check, and gate 6 capacity (no drafting past today's cap,
// nothing at all while the kill switch is on). Also writes live "Update" sections and corrections
// for published articles that keep trending.
//
// Model: ANTHROPIC_MODEL (default "claude-sonnet-5-5"), key ANTHROPIC_API_KEY. Without the key,
// drafting is skipped and logged (gates 1-2 still route topics).
// POST { action: "run" } -> { ok, dry_run, stats }
import { env } from "../_shared/env.ts";
import { serve } from "../_shared/http.ts";
import { claudeFromEnv } from "../_shared/trends/claude.ts";
import { runDraft } from "../_shared/trends/run_draft.ts";
import { handleRun } from "../_shared/trends/runtime.ts";

serve((req) =>
  handleRun(
    req,
    "trends-draft",
    (store) => runDraft({ store, claude: claudeFromEnv(env), now: () => new Date() }),
    () => (env("ANTHROPIC_API_KEY") ? null : "missing ANTHROPIC_API_KEY: drafting skipped"),
  )
);
