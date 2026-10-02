// trends-draft run: fired topics -> gates 1-2 -> Claude draft -> gates 3-5 + balance,
// approved sensitive topics, and live updates of published articles.
import { type Claude, ClaudeError } from "./claude.ts";
import { type DraftOutcome, draftTopic, draftUpdate, preGates } from "./draft.ts";
import { remainingToday } from "./ramp.ts";
import type { Store } from "./store.ts";
import type { Country, Draft, Topic } from "./types.ts";

export interface DraftDeps {
  store: Store;
  claude: Claude | null;
  now: () => Date;
}

function draftRow(o: DraftOutcome, topic: Topic, model: string | null): Record<string, unknown> {
  return {
    status: o.status,
    review_stage: o.review_stage,
    article: o.article,
    gates: o.gates,
    failed_gate: o.failed_gate,
    reason: o.reason,
    sensitive: o.sensitive,
    sensitive_reasons: o.sensitive_reasons,
    rewrites: o.rewrites,
    model,
    velocity: topic.velocity,
    slug: o.article?.slug ?? null,
  };
}

const decisionOf = (
  o: DraftOutcome,
) => (o.status === "queued" ? "queued" : o.status === "review" ? "review" : "rejected");

export async function runDraft(deps: DraftDeps) {
  const { store, claude } = deps;
  const s = await store.settings();
  const now = deps.now();
  const stats = {
    paused: s.publishing.paused,
    no_api_key: !claude,
    drafted: 0,
    queued: 0,
    review: 0,
    rejected: 0,
    waiting_cap: 0,
    skipped_no_key: 0,
    errors: [] as string[],
    updates: 0,
    corrections: 0,
  };
  if (s.publishing.paused) return stats; // kill switch: no model spend, nothing new queued

  const published = await store.publishedTimes(48);
  const remaining: Record<Country, number> = {
    usa: remainingToday("usa", now, published.usa, s),
    india: remainingToday("india", now, published.india, s),
  };
  let budget = s.caps.max_drafts_per_run;

  const save = async (o: DraftOutcome, topic: Topic, existingId: string | null) => {
    let row = draftRow(o, topic, claude?.model ?? null);
    let id = existingId;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        if (id) await store.updateDraft(id, row);
        else id = await store.insertDraft({ topic_id: topic.id, country: topic.country, ...row });
        break;
      } catch (e) {
        // slug taken (same headline drafted before): suffix and retry
        if ((e as { code?: string }).code === "23505" && o.article && attempt < 2) {
          o.article.slug = `${o.article.slug}-${(now.getTime() + attempt).toString(36).slice(-4)}`;
          row = draftRow(o, topic, claude?.model ?? null);
          continue;
        }
        throw e;
      }
    }
    await store.updateTopic(topic.id, {
      status: o.topic_status,
      status_reason: o.topic_reason,
      ...(o.domains_at_reject !== undefined ? { domains_at_reject: o.domains_at_reject } : {}),
    });
    await store.log(decisionOf(o), o.failed_gate ? `${o.failed_gate}: ${o.reason}` : o.reason, {
      id: id!,
      topic_id: topic.id,
      slug: o.article?.slug ?? null,
      country: topic.country,
    }, { gates: o.gates });
    stats[o.status === "queued" ? "queued" : o.status === "review" ? "review" : "rejected"]++;
    if (o.status === "queued") remaining[topic.country]--;
  };

  const runModel = async (topic: Topic, topicApproved: boolean, existing: Draft | null) => {
    if (!claude) {
      stats.skipped_no_key++;
      return;
    }
    if (remaining[topic.country] <= 0) {
      stats.waiting_cap++;
      return;
    }
    if (budget <= 0) return;
    budget--;
    try {
      const signals = await store.topicSignals(topic.id);
      const o = await draftTopic({ topic, signals, settings: s, claude, topicApproved, now });
      stats.drafted++;
      await save(o, topic, existing?.id ?? null);
    } catch (e) {
      if (e instanceof ClaudeError && e.code === "claude_refusal") {
        const o: DraftOutcome = {
          status: "rejected",
          review_stage: null,
          article: null,
          gates: {},
          failed_gate: "model",
          reason: `model declined (${e.message})`,
          sensitive: false,
          sensitive_reasons: [],
          rewrites: 0,
          topic_status: "dropped",
          topic_reason: "model declined",
        };
        await save(o, topic, existing?.id ?? null);
      } else {
        // transient (network, 5xx, invalid JSON): the topic stays fired and is retried next run
        stats.errors.push(`${topic.id}: ${e instanceof Error ? e.message : String(e)}`.slice(0, 300));
      }
    }
  };

  // 1. sensitive topics a reviewer approved (queued, nothing drafted yet)
  for (const d of await store.pendingDrafts()) {
    const topic = d.topic_id ? await store.getTopic(d.topic_id) : null;
    if (!topic) continue;
    await runModel(topic, true, d);
  }

  // 2. newly fired topics, highest velocity first; gates 1-2 decide before any model call
  for (const topic of await store.firedTopics(25)) {
    const signals = await store.topicSignals(topic.id);
    const pre = preGates(topic, signals, s, false);
    if (pre.outcome) {
      await save(pre.outcome, topic, null);
      continue;
    }
    await runModel(topic, false, null);
  }
  if (!claude) {
    console.log("trends-draft: ANTHROPIC_API_KEY not set; drafting skipped", {
      skipped: stats.skipped_no_key,
    });
  }

  // 3. live updates and corrections on published articles that keep trending
  if (claude) {
    for (
      const { draft, signals } of await store.publishedWithNewSignals(s.detection.update_min_interval_minutes)
    ) {
      try {
        const u = await draftUpdate({
          article: draft.article!,
          newSignals: signals,
          settings: s,
          claude,
          now,
        });
        await store.updateDraft(draft.id, {
          last_update_at: now.toISOString(),
          ...(u.kind ? { article: u.article, dirty: true } : {}),
        });
        if (u.kind) {
          if (u.kind !== "correction") stats.updates++;
          if (u.kind !== "update") stats.corrections++;
          await store.log(u.kind === "update" ? "updated" : "corrected", u.reason, draft, { kind: u.kind });
        }
      } catch (e) {
        stats.errors.push(`update ${draft.id}: ${e instanceof Error ? e.message : String(e)}`.slice(0, 300));
      }
    }
  }
  return stats;
}
