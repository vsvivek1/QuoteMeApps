// web-forms: the websites' form endpoint (web/README.md "Form endpoint contract").
//
// POST JSON { form, country, page, submitted_at, fields, consents, honeypot, turnstile_token }
//   form = seller_signup | contact | waitlist | account_deletion | trends_contact
// POST JSON { action: "confirm_deletion", request_id, otp }      second step of account deletion
// GET  ?action=confirm_waitlist&token=...                          double opt-in link (email)
// GET  ?action=unsubscribe_waitlist&token=...                      unsubscribe link in waitlist mails
//
// Order of checks: CORS allow-list (WEB_FORMS_ALLOWED_ORIGINS) -> honeypot (non-empty: 200, dropped,
// nothing stored) -> per-IP rate limit (429 + Retry-After; Upstash, else Postgres) -> Turnstile
// siteverify (TURNSTILE_SECRET_KEY, action must equal the form kind) -> field/consent validation.
// Responses never reveal whether an account or email exists.
import { hasMxRecord, transactionalFrom, transactionalProviderFromEnv } from "../_shared/email.ts";
import { appCountry, env } from "../_shared/env.ts";
import { randomToken, sha256Hex } from "../_shared/crypto.ts";
import { businessKey, normalizeDomain } from "../_shared/leads.ts";
import { clientIp, rateLimitWithFallback } from "../_shared/ratelimit.ts";
import { adminClient, anonClient, clientForToken } from "../_shared/supabase.ts";
import { verifyTurnstile } from "../_shared/turnstile.ts";
import { corsHeadersFor, countryParam, type FormPayload, normalizePhoneDigits, validateForm } from "../_shared/webforms.ts";

const allowedOrigins = () => (env("WEB_FORMS_ALLOWED_ORIGINS") ?? "").split(",").map((s) => s.trim()).filter(Boolean);
const functionUrl = () => env("WEB_FORMS_PUBLIC_URL") ?? `${env("SUPABASE_URL")}/functions/v1/web-forms`;

function reply(status: number, body: unknown, cors: Record<string, string> | null, extra: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...(cors ?? {}), ...extra },
  });
}

function page(title: string, msg: string, status = 200) {
  return new Response(
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${title}</title>` +
      `<body style="font-family:system-ui;max-width:32rem;margin:4rem auto;padding:0 1rem"><h1>${title}</h1><p>${msg}</p></body>`,
    { status, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

async function ipHash(ip: string) {
  return (await sha256Hex(`${env("IP_HASH_SALT") ?? "iwant"}:${ip}`)).slice(0, 32);
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const origin = req.headers.get("Origin");
  const cors = corsHeadersFor(origin, allowedOrigins());

  try {
    if (req.method === "GET") return await handleGet(url);
    if (req.method === "OPTIONS") return new Response(null, { status: cors ? 204 : 403, headers: cors ?? {} });
    if (req.method !== "POST") return reply(405, { code: "method_not_allowed" }, cors);
    if (!cors) return reply(403, { code: "origin_not_allowed" }, null);

    const raw = await req.text();
    if (raw.length > 20_000) return reply(413, { code: "payload_too_large" }, cors);
    let body: FormPayload & { action?: string; request_id?: string; otp?: string };
    try {
      body = JSON.parse(raw);
    } catch {
      return reply(400, { code: "invalid_json" }, cors);
    }

    const ip = clientIp(req).split(",")[0].trim();
    const ipKey = await ipHash(ip);

    if (body.action === "confirm_deletion") {
      const rl = await rateLimitWithFallback("web-forms-otp", ipKey, 10, 3600);
      if (!rl.success) return reply(429, { code: "rate_limited" }, cors, { "Retry-After": String(rl.retryAfterSeconds) });
      return reply(...await confirmDeletion(body.request_id, body.otp), cors);
    }

    // Honeypot: pretend success, store nothing.
    if (typeof body.honeypot === "string" && body.honeypot.trim() !== "") return reply(200, { ok: true }, cors);

    const rl = await rateLimitWithFallback("web-forms", ipKey, Number(env("WEB_FORMS_RATE_LIMIT") ?? 5), 600);
    if (!rl.success) return reply(429, { code: "rate_limited" }, cors, { "Retry-After": String(rl.retryAfterSeconds) });

    const ts = await verifyTurnstile(body.turnstile_token ?? "", ip === "unknown" ? null : ip, {
      action: body.form,
      hostnames: (env("TURNSTILE_ALLOWED_HOSTNAMES") ?? "").split(",").map((s) => s.trim()).filter(Boolean),
    });
    if (!ts.ok) return reply(403, { code: "captcha_failed", details: ts.reason }, cors);

    const v = validateForm(body, countryParam(appCountry()));
    if (!v.ok) return reply(400, { code: v.code, details: v.field ?? null }, cors);

    const db = adminClient();
    const { data: sub, error } = await db.from("web_form_submissions").insert({
      form: v.form,
      country: body.country ?? null,
      page: (body.page ?? "").slice(0, 300) || null,
      fields: v.fields,
      submitted_at: body.submitted_at && !isNaN(Date.parse(body.submitted_at)) ? body.submitted_at : null,
      ip_hash: ipKey,
      user_agent: (req.headers.get("User-Agent") ?? "").slice(0, 300),
      status: v.form === "waitlist" || v.form === "account_deletion" ? "pending_confirmation" : "received",
    }).select("id").single();
    if (error) throw error;

    // Consent text + timestamps, exactly as shown on the page.
    if (v.consents.length) {
      await db.from("consents").insert(v.consents.map((c) => ({
        document: c.document,
        version: "web",
        granted: true,
        accepted_at: new Date().toISOString(),
        source: `web:${v.form}`,
        email: v.fields.email ?? null,
        phone: v.fields.phone ?? v.fields.whatsapp ?? null,
        consent_key: c.key,
        consent_text: c.text,
        form: v.form,
        page: body.page ?? null,
        submission_id: sub.id,
        // double opt-in consents count only once confirmed
        confirmed_at: v.form === "waitlist" ? null : new Date().toISOString(),
      })));
    }

    switch (v.form) {
      case "waitlist":
        await waitlist(sub.id, v.fields, v.consents.some((c) => c.key === "consent_whatsapp"));
        break;
      case "seller_signup":
        await sellerSignup(sub.id, v.fields, v.consents, body.page ?? "/sellers");
        break;
      case "account_deletion":
        return reply(200, { ok: true, request_id: await deletionRequest(sub.id, v.fields) }, cors);
      default:
        await notifyAdmins("web_contact", { submission_id: sub.id, form: v.form, topic: v.fields.topic ?? null });
    }
    return reply(200, { ok: true }, cors);
  } catch (e) {
    console.error("web-forms error", e);
    return reply(500, { code: "internal_error" }, cors);
  }
});

// --- waitlist (double opt-in) --------------------------------------------------------------------

async function waitlist(submissionId: string, f: Record<string, string>, whatsappConsent: boolean) {
  const db = adminClient();
  const { data: existing } = await db.from("waitlist_signups").select("id,status,confirmation_sent_at")
    .ilike("email", f.email).maybeSingle();
  if (existing?.status === "confirmed") return; // already in; nothing to send
  if (existing?.confirmation_sent_at && Date.now() - Date.parse(existing.confirmation_sent_at) < 10 * 60_000) return;

  const token = randomToken(32);
  const row = {
    email: f.email,
    city: f.city ?? null,
    postal_code: f.postal_code ?? null,
    whatsapp: whatsappConsent ? f.whatsapp ?? null : null,
    source: f.source ?? "waitlist_page",
    status: "pending",
    confirm_token_hash: await sha256Hex(token),
    confirm_expires_at: new Date(Date.now() + 72 * 3600_000).toISOString(),
    submission_id: submissionId,
  };
  const { data: saved, error } = existing
    ? await db.from("waitlist_signups").update(row).eq("id", existing.id).select("id").single()
    : await db.from("waitlist_signups").insert(row).select("id").single();
  if (error) throw error;

  // Only the confirmation mail is sent before the person confirms.
  const provider = transactionalProviderFromEnv();
  const from = transactionalFrom();
  const domain = f.email.split("@")[1];
  if (!provider || !from) {
    console.log("[web-forms] waitlist confirmation stubbed (TRANSACTIONAL_EMAIL_PROVIDER not set)", saved.id);
    return;
  }
  if ((await hasMxRecord(domain)) === false) return;
  const link = `${functionUrl()}?action=confirm_waitlist&token=${token}`;
  await provider.send({
    from,
    to: f.email,
    subject: "Please confirm your email",
    text: `Hi,\n\nPlease confirm you want updates about ${env("APP_DISPLAY_NAME") ?? "I Want"} in ${f.city ?? "your city"}:\n${link}\n\nIf you did not ask for this, ignore this email and nothing more will be sent.\n`,
  });
  await db.from("waitlist_signups").update({ confirmation_sent_at: new Date().toISOString() }).eq("id", saved.id);
}

async function handleGet(url: URL): Promise<Response> {
  const action = url.searchParams.get("action");
  const token = url.searchParams.get("token") ?? "";
  if (!/^[a-f0-9]{32,128}$/.test(token)) return page("Link not valid", "This link is not valid.", 400);
  const db = adminClient();

  if (action === "confirm_waitlist") {
    const { data: w } = await db.from("waitlist_signups").select("id,status,confirm_expires_at,submission_id,whatsapp")
      .eq("confirm_token_hash", await sha256Hex(token)).maybeSingle();
    if (!w || w.status !== "pending" || Date.parse(w.confirm_expires_at) < Date.now()) {
      return page("Link expired", "This confirmation link has expired. Please sign up again.", 410);
    }
    const now = new Date().toISOString();
    await db.from("waitlist_signups").update({
      status: "confirmed",
      confirmed_at: now,
      confirm_token_hash: null,
      whatsapp_opt_in_at: w.whatsapp ? now : null,
    }).eq("id", w.id);
    await db.from("consents").update({ confirmed_at: now }).eq("submission_id", w.submission_id);
    await db.from("web_form_submissions").update({ status: "confirmed" }).eq("id", w.submission_id);
    const redirect = env("WAITLIST_CONFIRMED_URL");
    if (redirect) return Response.redirect(redirect, 303);
    return page("You're on the list", "Thanks for confirming. We'll email you when we're live in your area.");
  }

  if (action === "unsubscribe_waitlist") {
    const { data: w } = await db.from("waitlist_signups").select("id,email").eq("unsubscribe_token", token).maybeSingle();
    if (w) {
      const now = new Date().toISOString();
      await db.from("waitlist_signups").update({ status: "unsubscribed", unsubscribed_at: now, whatsapp_opt_in_at: null })
        .eq("id", w.id);
      await db.from("consents").update({ withdrawn_at: now, granted: false }).ilike("email", w.email)
        .in("document", ["email_marketing", "whatsapp"]).is("withdrawn_at", null);
    }
    return page("Unsubscribed", "You won't get any more emails from us.");
  }
  return page("Not found", "Unknown action.", 404);
}

// --- seller sign-up -> inbound CRM lead ----------------------------------------------------------

async function sellerSignup(
  submissionId: string,
  f: Record<string, string>,
  consents: { key: string; text: string }[],
  pagePath: string,
) {
  const db = adminClient();
  const country = appCountry();
  const phone = normalizePhoneDigits(f.phone, country);
  const { data: cat } = await db.from("categories").select("id").eq("slug", f.category).maybeSingle();
  const lead = {
    business_key: businessKey({ website: f.website, phone: phone ? `+${phone}` : null, osmId: `web-${submissionId}` }),
    business_name: f.business_name,
    categories_source: [`web:${f.category}`],
    matched_category_ids: cat ? [cat.id] : [],
    email: f.email,
    address_source: `inbound:web_form:${submissionId}`,
    phone: phone ? `+${phone}` : null,
    website: f.website ?? null,
    website_domain: normalizeDomain(f.website),
    city: f.city,
    postal_code: f.postal_code,
    source: "inbound",
    source_ref: submissionId,
    lawful_basis: "inbound_request",
    chosen_reason: `Inbound seller sign-up form (${pagePath})`,
  };
  let { data: leadId } = await db.rpc("outreach_upsert_lead", { p_lead: lead });
  if (!leadId) {
    // Same business already in the CRM (phone / domain / email): attach to it.
    const { data: found } = await db.from("outreach_leads").select("id")
      .or([`business_key.eq.${lead.business_key}`, phone ? `phone.eq.+${phone}` : null, `email.eq.${f.email}`].filter(Boolean).join(","))
      .limit(1).maybeSingle();
    leadId = found?.id ?? null;
  }
  if (leadId) {
    const wa = consents.find((c) => c.key === "consent_whatsapp");
    const now = new Date().toISOString();
    await db.from("outreach_leads").update({
      next_action: `Call back: inbound sign-up from ${f.contact_name}`,
      next_action_due: now.slice(0, 10),
      notes: `Inbound web sign-up ${now}: contact ${f.contact_name}, category ${f.category}`,
      ...(wa ? { whatsapp_opt_in_at: now, whatsapp_opt_in_channel: "web_form", whatsapp_opt_in_proof: wa.text.slice(0, 500) } : {}),
    }).eq("id", leadId);
    await db.from("web_form_submissions").update({ lead_id: leadId }).eq("id", submissionId);
  }
  await notifyAdmins("web_seller_signup", { submission_id: submissionId, lead_id: leadId, business_name: f.business_name, city: f.city });
}

// --- account deletion (OTP to the registered phone) ------------------------------------------------

async function deletionRequest(submissionId: string, f: Record<string, string>): Promise<string> {
  const db = adminClient();
  const country = appCountry();
  const phone = f.phone ? normalizePhoneDigits(f.phone, country) : null;
  let userId: string | null = null, registeredPhone: string | null = null;
  if (phone) {
    const { data } = await db.from("profiles").select("id,phone").eq("phone", phone).neq("status", "deleted").maybeSingle();
    if (data) [userId, registeredPhone] = [data.id, data.phone];
  }
  if (!userId && f.email) {
    const { data } = await db.from("profiles").select("id,phone").ilike("email", f.email).neq("status", "deleted").maybeSingle();
    if (data) [userId, registeredPhone] = [data.id, data.phone];
  }
  let status = "manual_review"; // no account, or no phone on it: an admin confirms by email
  if (userId && registeredPhone) {
    const { error } = await anonClient().auth.signInWithOtp({ phone: `+${registeredPhone}`, options: { shouldCreateUser: false } });
    status = error ? "manual_review" : "otp_sent";
    if (error) console.warn("deletion otp send failed", error.message);
  }
  const { data, error } = await db.from("account_deletion_requests").insert({
    email: f.email ?? null,
    phone: registeredPhone ?? phone ?? f.phone ?? null,
    user_id: userId,
    reason: f.reason ?? null,
    status,
    otp_sent_at: status === "otp_sent" ? new Date().toISOString() : null,
    submission_id: submissionId,
  }).select("id").single();
  if (error) throw error;
  if (status === "manual_review") await notifyAdmins("account_deletion_request", { request_id: data.id });
  return data.id;
}

async function confirmDeletion(requestId?: string, otp?: string): Promise<[number, unknown]> {
  if (!requestId || !/^[0-9a-f-]{36}$/.test(requestId) || !otp || !/^\d{4,8}$/.test(otp)) {
    return [400, { code: "invalid_request" }];
  }
  const db = adminClient();
  const { data: r } = await db.from("account_deletion_requests").select("*").eq("id", requestId).maybeSingle();
  // Same answer for unknown / wrong-state requests (no enumeration).
  if (!r || r.status !== "otp_sent" || !r.user_id || !r.phone) return [400, { code: "invalid_or_expired_code" }];
  if (r.otp_attempts >= 5 || Date.now() - Date.parse(r.otp_sent_at) > 15 * 60_000) {
    await db.from("account_deletion_requests").update({ status: "expired" }).eq("id", r.id);
    return [400, { code: "invalid_or_expired_code" }];
  }
  await db.from("account_deletion_requests").update({ otp_attempts: r.otp_attempts + 1 }).eq("id", r.id);
  const { data: auth, error } = await anonClient().auth.verifyOtp({ phone: `+${r.phone}`, token: otp, type: "sms" });
  if (error || !auth.session || auth.user?.id !== r.user_id) return [400, { code: "invalid_or_expired_code" }];

  await db.from("account_deletion_requests").update({ status: "confirmed", confirmed_at: new Date().toISOString() }).eq("id", r.id);
  const { error: delErr } = await clientForToken(auth.session.access_token).rpc("delete_my_account");
  if (delErr) {
    console.error("delete_my_account failed", delErr);
    await db.from("account_deletion_requests").update({ status: "manual_review" }).eq("id", r.id);
    return [500, { code: "deletion_failed" }];
  }
  await db.auth.admin.deleteUser(r.user_id, true);
  await db.from("account_deletion_requests").update({ status: "completed", completed_at: new Date().toISOString() }).eq("id", r.id);
  await db.from("web_form_submissions").update({ status: "handled", handled_at: new Date().toISOString() }).eq("id", r.submission_id);
  return [200, { ok: true, deleted: true }];
}

async function notifyAdmins(type: string, payload: Record<string, unknown>) {
  const db = adminClient();
  const { data: admins } = await db.from("profiles").select("id").contains("roles", ["admin"]).eq("status", "active");
  if (!admins?.length) return;
  await db.from("notifications").insert(admins.map((a: { id: string }) => ({
    user_id: a.id,
    type,
    payload: { ...payload, route: "/admin/inbox" },
    push_status: "queued",
  })));
}
