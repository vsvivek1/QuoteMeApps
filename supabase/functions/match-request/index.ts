// match-request: called by the requests INSERT trigger (pg_net, x-webhook-secret)
// or manually with the service-role key. Reverse-matches sellers, writes one
// `new_lead` notification per seller (priority window, digest mode and quiet
// hours decide push_after), pushes the ones due now in one FCM batch and
// broadcasts `new_lead` on each seller's realtime channel `seller:{id}`.
//
// Body: { record: { id } } (database webhook shape) or { request_id }.
// Response: { request_id, matched, pushed_now, queued, skipped }
import { sendPushBatch } from "../_shared/fcm.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { planLeadPush, renderPush } from "../_shared/notify.ts";
import { adminClient, isServiceCaller, unwrap } from "../_shared/supabase.ts";
import { env } from "../_shared/env.ts";

interface Match {
  seller_id: string;
  verified: boolean;
  has_priority: boolean;
  notify_mode: string;
  quiet_hours_start: string | null;
  quiet_hours_end: string | null;
  timezone: string | null;
  language: string | null;
  fcm_tokens: string[];
}

serve(async (req) => {
  requireMethod(req, "POST");
  if (!isServiceCaller(req)) throw new HttpError(401, "invalid_webhook_secret");
  const body = await readJson<{ record?: { id?: string }; request_id?: string }>(req);
  const requestId = body.request_id ?? body.record?.id;
  if (!requestId) throw new HttpError(400, "request_id_required");

  const db = adminClient();
  const request = unwrap(
    await db.from("requests").select("id,title,category_id,city,status,hidden,priority_until,created_at")
      .eq("id", requestId).maybeSingle(),
  );
  if (!request) throw new HttpError(404, "request_not_found");
  if (request.status !== "open" || request.hidden) return json({ request_id: requestId, matched: 0, skipped: "not_open" });

  // Idempotency: pg_net may retry; never notify the same request twice.
  const { count } = await db.from("notifications").select("id", { count: "exact", head: true })
    .eq("type", "new_lead").eq("payload->>request_id", requestId);
  if ((count ?? 0) > 0) return json({ request_id: requestId, matched: 0, skipped: "already_matched" });

  const settings = unwrap(await db.from("app_settings").select("value").eq("key", "match_push_cap").maybeSingle());
  const cap = Math.min(Number(settings?.value ?? 200) || 200, 1000);
  const matches = unwrap(await db.rpc("match_sellers_for_request", { p_request_id: requestId, p_limit: cap })) as
    Match[];

  // Respect the seller's push setting (inbox row is still written).
  const pushOff = new Set<string>();
  if (matches.length) {
    const prefs = unwrap(
      await db.from("profiles").select("id,notification_prefs").in("id", matches.map((m) => m.seller_id)),
    ) as { id: string; notification_prefs: { push?: boolean } | null }[];
    for (const p of prefs) if (p.notification_prefs?.push === false) pushOff.add(p.id);
  }

  const now = new Date();
  const priorityUntil = request.priority_until ? new Date(request.priority_until) : null;
  const rows: Record<string, unknown>[] = [];
  const immediate: { id: string; m: Match }[] = [];
  for (const m of matches) {
    const plan = planLeadPush({
      now,
      sellerId: m.seller_id,
      priorityUntil,
      sellerHasPriority: m.has_priority || m.verified,
      notifyMode: m.notify_mode,
      quietStart: m.quiet_hours_start,
      quietEnd: m.quiet_hours_end,
      timeZone: m.timezone,
    });
    const id = crypto.randomUUID();
    const canPush = m.fcm_tokens.length > 0 && !pushOff.has(m.seller_id);
    const sendNow = plan.immediate && !plan.digestKey && canPush;
    rows.push({
      id,
      user_id: m.seller_id,
      type: "new_lead",
      payload: {
        request_id: requestId,
        title: request.title,
        category_id: request.category_id,
        city: request.city,
        route: `/seller/leads/${requestId}`,
      },
      digest_key: plan.digestKey,
      push_after: plan.pushAfter.toISOString(),
      // 'sending' = claimed by this invocation; 'queued' = send-push picks it up at push_after.
      push_status: sendNow ? "sending" : canPush ? "queued" : "none",
    });
    if (sendNow) immediate.push({ id, m });
  }
  for (let i = 0; i < rows.length; i += 500) unwrap(await db.from("notifications").insert(rows.slice(i, i + 500)));

  // FCM fast path for sellers who should hear right now.
  const messages = immediate.flatMap(({ id, m }) => {
    const t = renderPush("new_lead", { title: request.title }, m.language);
    return m.fcm_tokens.map((token) => ({
      notificationId: id,
      msg: {
        token,
        title: t.title,
        body: t.body,
        channel: t.channel,
        collapseKey: `lead:${requestId}`,
        data: { type: "new_lead", request_id: requestId, route: `/seller/leads/${requestId}` },
      },
    }));
  });
  const results = await sendPushBatch(messages.map((x) => x.msg));
  const sentIds = new Set<string>(), invalid: string[] = [];
  results.forEach((r, i) => {
    if (r.outcome === "sent" || r.outcome === "skipped") sentIds.add(messages[i].notificationId);
    if (r.outcome === "invalid_token") invalid.push(r.token);
  });
  const failedIds = immediate.map((x) => x.id).filter((id) => !sentIds.has(id));
  if (sentIds.size) await db.rpc("mark_notifications_pushed", { p_ids: [...sentIds], p_status: "sent" });
  if (failedIds.length) await db.rpc("mark_notifications_pushed", { p_ids: failedIds, p_status: "failed" });
  if (invalid.length) await db.rpc("delete_device_tokens", { p_tokens: invalid });

  // Realtime: refresh open lead feeds (no PII in the payload; the app re-queries get_lead_feed).
  await broadcast(
    matches.map((m) => ({
      topic: `seller:${m.seller_id}`,
      event: "new_lead",
      payload: { request_id: requestId, category_id: request.category_id, created_at: request.created_at },
    })),
  );

  return json({
    request_id: requestId,
    matched: matches.length,
    pushed_now: sentIds.size,
    queued: rows.filter((r) => r.push_status === "queued").length,
    failed: failedIds.length,
  });
});

async function broadcast(messages: { topic: string; event: string; payload: unknown }[]) {
  if (!messages.length) return;
  const url = `${env("SUPABASE_URL")}/realtime/v1/api/broadcast`;
  const key = env("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  for (let i = 0; i < messages.length; i += 100) {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
        body: JSON.stringify({ messages: messages.slice(i, i + 100).map((m) => ({ ...m, private: false })) }),
      });
      if (!res.ok) console.warn("broadcast failed", res.status, await res.text());
      else await res.body?.cancel();
    } catch (e) {
      console.warn("broadcast error", e);
    }
  }
}
