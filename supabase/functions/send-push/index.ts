// send-push: flushes due notifications to FCM.
// Called by the notifications INSERT trigger and the */5 cron job (pg_net,
// x-webhook-secret), or with the service-role key.
//
// Body: { action: "flush_due", limit?: number }
// Claims rows atomically (claim_due_notifications, SKIP LOCKED) and merges rows
// that share (user, digest_key) into one push ("5 new quotes", lead digests,
// chat bursts). Quiet hours and digest timing are already encoded in
// push_after (match-request for leads; SQL for quote digests), so everything
// claimed here is due. Users with push off are marked 'skipped'; dead FCM
// tokens are deleted.
import { sendPushBatch } from "../_shared/fcm.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { type ClaimedNotification, groupForPush, renderPush } from "../_shared/notify.ts";
import { adminClient, isServiceCaller, unwrap } from "../_shared/supabase.ts";

const TIME_BUDGET_MS = 20_000;

serve(async (req) => {
  requireMethod(req, "POST");
  if (!isServiceCaller(req)) throw new HttpError(401, "invalid_webhook_secret");
  const body = await readJson<{ action?: string; limit?: number }>(req);
  if ((body.action ?? "flush_due") !== "flush_due") throw new HttpError(400, "unknown_action");

  const db = adminClient();
  const started = Date.now();
  const totals = { claimed: 0, pushes: 0, sent: 0, skipped: 0, failed: 0, tokens_deleted: 0 };

  while (Date.now() - started < TIME_BUDGET_MS) {
    const rows = unwrap(
      await db.rpc("claim_due_notifications", { p_limit: Math.min(body.limit ?? 500, 2000) }),
    ) as ClaimedNotification[];
    if (!rows.length) break;
    totals.claimed += rows.length;

    const groups = groupForPush(rows);
    const skipIds: string[] = [];
    const work: { ids: string[]; msgIndex: number[] }[] = [];
    const messages: Parameters<typeof sendPushBatch>[0] = [];
    for (const g of groups) {
      if (!g.pushEnabled || g.tokens.length === 0) {
        skipIds.push(...g.ids);
        continue;
      }
      const t = renderPush(g.type, g.payload, g.language, g.count);
      const data: Record<string, string> = { type: g.type, count: String(g.count) };
      for (const k of ["route", "request_id", "quote_id", "chat_id", "order_id"]) {
        if (g.payload[k] != null) data[k] = String(g.payload[k]);
      }
      const idx: number[] = [];
      for (const token of g.tokens) {
        idx.push(messages.length);
        messages.push({ token, title: t.title, body: t.body, channel: t.channel, collapseKey: g.collapseKey, data });
      }
      work.push({ ids: g.ids, msgIndex: idx });
    }

    const results = await sendPushBatch(messages);
    const sent: string[] = [], failed: string[] = [], invalid: string[] = [];
    for (const w of work) {
      const outcomes = w.msgIndex.map((i) => results[i]);
      outcomes.forEach((o) => o.outcome === "invalid_token" && invalid.push(o.token));
      // A notification counts as sent when at least one device got it.
      if (outcomes.some((o) => o.outcome === "sent" || o.outcome === "skipped")) sent.push(...w.ids);
      else failed.push(...w.ids);
    }
    totals.pushes += work.length;
    if (sent.length) await db.rpc("mark_notifications_pushed", { p_ids: sent, p_status: "sent" });
    if (failed.length) await db.rpc("mark_notifications_pushed", { p_ids: failed, p_status: "failed" });
    if (skipIds.length) await db.rpc("mark_notifications_pushed", { p_ids: skipIds, p_status: "skipped" });
    if (invalid.length) {
      totals.tokens_deleted += Number(unwrap(await db.rpc("delete_device_tokens", { p_tokens: invalid })) ?? 0);
    }
    totals.sent += sent.length;
    totals.failed += failed.length;
    totals.skipped += skipIds.length;
    if (rows.length < (body.limit ?? 500)) break;
  }
  return json(totals);
});
