// outreach-webhook: delivery events, replies and unsubscribes for seller outreach.
//
//   GET/POST ?action=unsubscribe&token=...      one-click unsubscribe (List-Unsubscribe / RFC 8058)
//   POST (Resend, Svix-signed: svix-id / svix-timestamp / svix-signature, RESEND_WEBHOOK_SECRET)
//        email.delivered | email.bounced | email.complained | email.clicked | email.received (inbound reply)
//   POST ?provider=brevo&secret=EDGE_WEBHOOK_SECRET   Brevo transactional webhooks
//   POST (x-webhook-secret) { type: "reply", from, text, message_id?, in_reply_to? }
//        generic inbound reply (SES receipt rule -> Lambda, Brevo inbound parse, mailbox poller)
//
// Effects (all via SQL so the rules hold for every path):
//   hard bounce / complaint / unsubscribe / negative reply -> suppression_list (instant, permanent)
//   reply -> lead stage "replied", sequence stopped, admins notified; "not now" -> remind in 3 months
//   bounce / complaint / negative reply -> outreach_check_brakes (auto-pause)
import { classifyReply } from "../_shared/outreach.ts";
import { env } from "../_shared/env.ts";
import { HttpError, json, requireMethod, serve } from "../_shared/http.ts";
import { verifySvixSignature } from "../_shared/signatures.ts";
import { adminClient, hasValidWebhookSecret, unwrap } from "../_shared/supabase.ts";

const html = (msg: string) =>
  new Response(
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Unsubscribed</title><body style="font-family:system-ui;max-width:32rem;margin:4rem auto;padding:0 1rem"><p>${msg}</p></body>`,
    { headers: { "Content-Type": "text/html; charset=utf-8" } },
  );

async function record(eventType: string, providerMessageId: string | null, email: string | null, meta: unknown) {
  return unwrap(await adminClient().rpc("outreach_record_event", {
    p_event_type: eventType,
    p_provider_message_id: providerMessageId,
    p_email: email,
    p_meta: meta ?? {},
    p_channel: "email",
  }));
}

async function notifyAdmins(leadEventId: string | null, from: string, kind: string) {
  const db = adminClient();
  const admins = unwrap(await db.from("profiles").select("id").contains("roles", ["admin"]).eq("status", "active")) as {
    id: string;
  }[];
  if (!admins.length) return;
  await db.from("notifications").insert(admins.map((a) => ({
    user_id: a.id,
    type: "outreach_reply",
    payload: { from, kind, event_id: leadEventId, route: "/admin/outreach" },
    push_status: "queued",
  })));
}

async function handleReply(from: string, text: string, inReplyTo: string | null) {
  const kind = classifyReply(text ?? "");
  // Always record the reply first (stops the sequence), then the classification.
  const replyId = await record("replied", inReplyTo, from, { excerpt: (text ?? "").slice(0, 1000), raw_kind: kind });
  if (kind !== "replied") await record(kind, inReplyTo, from, { auto_classified: true });
  await notifyAdmins(replyId as string | null, from, kind);
  return { kind, event_id: replyId };
}

const RESEND_MAP: Record<string, string> = {
  "email.delivered": "delivered",
  "email.complained": "complained",
  "email.clicked": "clicked",
};

const BREVO_MAP: Record<string, string> = {
  delivered: "delivered",
  hard_bounce: "bounced",
  soft_bounce: "soft_bounced",
  spam: "complained",
  complaint: "complained",
  unsubscribed: "unsubscribed",
  click: "clicked",
  invalid_email: "bounced",
  blocked: "bounced",
};

serve(async (req) => {
  const url = new URL(req.url);

  // One-click unsubscribe -----------------------------------------------------------------
  if (url.searchParams.get("action") === "unsubscribe") {
    requireMethod(req, "GET", "POST");
    const token = url.searchParams.get("token") ?? "";
    if (!/^[a-f0-9]{16,64}$/.test(token)) {
      return req.method === "GET" ? html("This unsubscribe link is not valid.") : json({ ok: false }, 400);
    }
    // Unknown tokens get the same answer (no lead enumeration).
    await adminClient().rpc("outreach_unsubscribe", { p_token: token });
    if (req.method === "POST") return json({ ok: true }); // RFC 8058: always 2xx
    return html("You're unsubscribed. We won't email you again.");
  }

  requireMethod(req, "POST");
  const raw = await req.text();

  // Resend (Svix signature) ---------------------------------------------------------------
  if (req.headers.get("svix-id")) {
    const secret = env("RESEND_WEBHOOK_SECRET");
    const ok = secret && await verifySvixSignature(raw, {
      id: req.headers.get("svix-id"),
      timestamp: req.headers.get("svix-timestamp"),
      signature: req.headers.get("svix-signature"),
    }, secret);
    if (!ok) throw new HttpError(401, "invalid_signature");
    const ev = JSON.parse(raw) as { type: string; data: any };
    const d = ev.data ?? {};
    const to = Array.isArray(d.to) ? d.to[0] : d.to;
    if (ev.type === "email.bounced") {
      const permanent = (d.bounce?.type ?? "Permanent").toLowerCase() !== "transient";
      return json({ event: await record(permanent ? "bounced" : "soft_bounced", d.email_id ?? null, to ?? null, d.bounce ?? {}) });
    }
    if (ev.type === "email.received") {
      const from = typeof d.from === "string" ? d.from.replace(/^.*<([^>]+)>.*$/, "$1") : d.from?.email;
      return json(await handleReply(from, d.text ?? d.plain ?? "", d.in_reply_to ?? null));
    }
    const mapped = RESEND_MAP[ev.type];
    if (!mapped) return json({ ignored: ev.type });
    return json({ event: await record(mapped, d.email_id ?? null, to ?? null, { type: ev.type }) });
  }

  // Everything else needs the shared secret ------------------------------------------------
  if (!hasValidWebhookSecret(req, url)) throw new HttpError(401, "invalid_webhook_secret");
  const body = JSON.parse(raw || "{}");

  if (url.searchParams.get("provider") === "brevo") {
    const mapped = BREVO_MAP[String(body.event)];
    if (!mapped) return json({ ignored: body.event });
    return json({ event: await record(mapped, body["message-id"] ?? null, body.email ?? null, { reason: body.reason ?? null }) });
  }

  if (body.type === "reply") {
    if (!body.from) throw new HttpError(400, "from_required");
    return json(await handleReply(String(body.from).toLowerCase(), String(body.text ?? ""), body.in_reply_to ?? body.message_id ?? null));
  }
  if (["bounced", "soft_bounced", "complained", "unsubscribed", "delivered", "clicked"].includes(body.type)) {
    return json({ event: await record(body.type, body.message_id ?? null, body.email ?? null, body.meta ?? {}) });
  }
  throw new HttpError(400, "unknown_event");
});
