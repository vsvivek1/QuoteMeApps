// outreach-send: the only sender for seller cold email (Section 21.2 / 21.8).
//
// Callers: pg_cron every 10 min on weekdays (x-webhook-secret, { action: "run" })
//          or an admin from the panel (admin JWT):
//   { action: "run", campaign_id?, limit? }       send due touches (cron or admin)
//   { action: "preview", campaign_id, limit? }    render only (no send, no record)
//   { action: "verify_emails", limit? }           syntax + disposable + MX -> email_status
//   { action: "send_one", lead_id, campaign_id, inbox_id, channel, step, variant, category_id,
//     subject, body, footer, whatsapp_template, confirmed_by_admin: true }
//                                                 one admin-reviewed message (admin JWT only,
//                                                 never cron); see _shared/send_one.ts
//
// "run" only processes campaigns an admin explicitly set to active (status = active AND
// activated_by stamped by the outreach_campaign_guard trigger). New campaigns are always
// created as draft, so nothing is sent until an admin activates a campaign.
//
// Hard rules live in Postgres and are re-checked on every send:
//   outreach_enabled flag, business address set, suppression, max 3 touches, one
//   conversation per business, verified address, admin-activated campaign, weekday
//   business hours in the lead's time zone, global / campaign / per-domain / per-inbox
//   (warm-up) daily caps, automatic brakes.
// This function adds the content rules (plain text, < 120 words, one link, no
// brochure in touch 1, no caps/spam phrases, personalised), honest identity
// footer (postal address from app_settings.outreach_business_address), one-click
// List-Unsubscribe, randomised pacing and template rotation.
// A template that fails the content rules pauses its campaign (never "sends anyway").
import { findBrochure, signupUrl } from "../_shared/brochure.ts";
import { type EmailProvider, hasMxRecord, providerFromEnv } from "../_shared/email.ts";
import { appCountry, env, envInt } from "../_shared/env.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import {
  buildFooter,
  businessAddressReady,
  checkEmailSyntax,
  checkFooter,
  checkOutreachContent,
  listUnsubscribeHeaders,
  type OutreachIdentity,
  pickVariant,
  renderTemplate,
  type SequenceStep,
} from "../_shared/outreach.ts";
import { sendOne, type SendOneDeps } from "../_shared/send_one.ts";
import { adminClient, isServiceCaller, requireAdmin, unwrap } from "../_shared/supabase.ts";
import { approvedTemplatesFromEnv, whatsappProviderFromEnv } from "../_shared/whatsapp.ts";

const TIME_BUDGET_MS = 45_000;

/** Sender identity from env; the postal address is app_settings.outreach_business_address. */
function identity(physicalAddress = ""): OutreachIdentity {
  const us = appCountry() === "US";
  return {
    senderName: env("OUTREACH_SENDER_NAME") ?? "Vivek",
    senderRole: env("OUTREACH_SENDER_ROLE") ?? "Founder",
    companyName: env("OUTREACH_COMPANY_NAME") ??
      (us ? "Calecute Technologies LLC" : "Calecute Technologies (OPC) Private Limited"),
    physicalAddress,
    websiteUrl: env("OUTREACH_WEBSITE_URL") ?? "",
    privacyUrl: env("OUTREACH_PRIVACY_URL") ?? "",
    adNotice: env("OUTREACH_AD_NOTICE") ?? (us ? "This is a business offer from I Want USA." : ""),
  };
}

function unsubscribeUrl(token: string): string {
  const base = env("OUTREACH_UNSUBSCRIBE_URL") ?? `${env("SUPABASE_URL")}/functions/v1/outreach-webhook`;
  const u = new URL(base);
  u.searchParams.set("action", "unsubscribe");
  u.searchParams.set("token", token);
  return u.toString();
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

serve(async (req) => {
  requireMethod(req, "POST");
  const body = await readJson<{ action?: string; campaign_id?: string; limit?: number }>(req);
  const action = body.action ?? "run";

  // send_one: a person reviewed and confirmed this exact message. Admin JWT
  // only; the webhook secret / service key (cron) is never enough.
  if (action === "send_one") {
    const ctx = await requireAdmin(req);
    return json(await sendOne(sendOneDeps(), { id: ctx.user.id, email: ctx.user.email ?? null }, body));
  }

  if (!isServiceCaller(req)) await requireAdmin(req);
  const db = adminClient();

  if (action === "verify_emails") return json(await verifyEmails(body.limit ?? 50));

  const settings = await outreachSettings();
  if (!settings.outreachEnabled) return json({ skipped: "outreach_disabled" });
  if (!businessAddressReady(settings.businessAddress)) return json({ skipped: "business_address_missing" });

  const id = identity(settings.businessAddress);
  if (!id.websiteUrl || !id.privacyUrl) {
    throw new HttpError(503, "outreach_identity_not_configured", "Set OUTREACH_WEBSITE_URL, OUTREACH_PRIVACY_URL");
  }
  const preview = action === "preview";
  if (!preview && action !== "run") throw new HttpError(400, "unknown_action");

  // Verify a few new addresses each run so the queue keeps moving.
  const verified = preview ? null : await verifyEmails(25);

  // Sending runs only for campaigns an admin explicitly activated; a preview
  // may render any campaign by id.
  let q = db.from("outreach_campaigns").select("*");
  if (!preview || !body.campaign_id) q = q.eq("status", "active").not("activated_by", "is", null);
  if (body.campaign_id) q = q.eq("id", body.campaign_id);
  const campaigns = unwrap(await q) as any[];
  const provider = providerFromEnv();
  const started = Date.now();
  const perRun = Math.min(body.limit ?? envInt("OUTREACH_MAX_PER_RUN", 8), 50);
  const report: any[] = [];

  for (const c of campaigns) {
    if (Date.now() - started > TIME_BUDGET_MS) break;
    if (!preview) {
      const brakes = unwrap(await db.rpc("outreach_check_brakes", { p_campaign_id: c.id })) as any;
      if (brakes?.paused_reason) {
        report.push({ campaign_id: c.id, paused: brakes.paused_reason });
        continue;
      }
    }
    report.push(await runCampaign(c, { provider, id, preview, perRun, started }));
  }
  return json({ provider: provider.name, verified, campaigns: report });
});

async function outreachSettings(): Promise<{ outreachEnabled: boolean; businessAddress: unknown }> {
  const rows = unwrap(
    await adminClient().from("app_settings").select("key,value").in("key", ["outreach_enabled", "outreach_business_address"]),
  ) as { key: string; value: unknown }[];
  const get = (k: string) => rows.find((r) => r.key === k)?.value;
  return { outreachEnabled: get("outreach_enabled") === true, businessAddress: get("outreach_business_address") };
}

function sendOneDeps(): SendOneDeps {
  const db = adminClient();
  const { physicalAddress: _unused, ...id } = identity();
  return {
    settings: outreachSettings,
    loadLead: async (leadId) =>
      unwrap(
        await db.from("outreach_leads")
          .select("id,business_name,email,phone,city,stage,touches_sent,campaign_id,matched_category_ids,unsubscribe_token")
          .eq("id", leadId).maybeSingle(),
      ),
    loadCampaign: async (campaignId) =>
      unwrap(await db.from("outreach_campaigns").select("id,status,activated_by,inbox_ids").eq("id", campaignId).maybeSingle()),
    loadInbox: async (inboxId) =>
      unwrap(await db.from("outreach_inboxes").select("id,email,display_name,active").eq("id", inboxId).maybeSingle()),
    canSend: async (leadId, channel, inboxId) => {
      const r = (unwrap(await db.rpc("outreach_can_send", {
        p_lead_id: leadId, p_channel: channel, p_inbox_id: inboxId, p_at: new Date().toISOString(),
      })) as any[])[0];
      return { allowed: r?.allowed === true, reason: r?.reason ?? "no_answer" };
    },
    recordSend: async (a) =>
      unwrap(await db.rpc("outreach_record_send", {
        p_lead_id: a.leadId, p_campaign_id: a.campaignId, p_inbox_id: a.inboxId, p_channel: a.channel,
        p_step: a.step, p_variant: a.variant, p_subject: a.subject, p_body_preview: a.bodyPreview,
        p_recipient: a.recipient, p_provider_message_id: a.providerMessageId,
      })) as string,
    annotate: async (eventId, adminId, meta) => {
      const { error } = await db.from("outreach_events").update({ created_by: adminId, meta }).eq("id", eventId);
      if (error) console.error("send_one annotate failed", eventId, error);
    },
    audit: async (row) => {
      const { error } = await db.from("admin_audit_log").insert({
        actor_id: row.actorId, actor_email: row.actorEmail, action: "outreach_send_one",
        target_type: "outreach_lead", target_id: row.leadId, details: row.details,
      });
      if (error) console.error("send_one audit failed", row.leadId, error);
    },
    email: providerFromEnv(),
    whatsapp: whatsappProviderFromEnv(),
    identity: id,
    unsubscribeUrl,
    unsubscribeMailto: env("OUTREACH_UNSUBSCRIBE_MAILTO"),
    replyTo: env("OUTREACH_REPLY_TO"),
    approvedTemplates: approvedTemplatesFromEnv(),
    whatsappLanguage: env("WHATSAPP_TEMPLATE_LANGUAGE") ?? (appCountry() === "US" ? "en_US" : "en"),
  };
}

async function runCampaign(
  c: any,
  o: { provider: EmailProvider; id: OutreachIdentity; preview: boolean; perRun: number; started: number },
) {
  const db = adminClient();
  const seq = unwrap(await db.from("outreach_sequences").select("*").eq("id", c.sequence_id).single()) as any;
  const steps = seq.steps as SequenceStep[];
  const inboxes = c.inbox_ids?.length
    ? unwrap(await db.from("outreach_inboxes").select("*").in("id", c.inbox_ids).eq("active", true)) as any[]
    : [];
  if (!inboxes.length) return { campaign_id: c.id, skipped: "no_active_inbox" };

  const batch = unwrap(await db.rpc("outreach_next_batch", { p_campaign_id: c.id, p_limit: o.perRun * 3 })) as any[];
  const settings = unwrap(await db.from("app_settings").select("key,value").in("key", ["early_partner_free_until"])) as any[];
  const freeUntil = settings.find((s) => s.key === "early_partner_free_until")?.value;
  const catIds = [...new Set(batch.flatMap((l) => l.matched_category_ids as number[]))];
  const cats = catIds.length
    ? unwrap(await db.from("categories").select("id,names").in("id", catIds)) as { id: number; names: Record<string, string> }[]
    : [];
  const catName = new Map(cats.map((x) => [x.id, x]));
  const lang = seq.language ?? "en";

  const out = { campaign_id: c.id, considered: batch.length, sent: 0, previews: [] as any[], skipped: [] as any[] };
  for (const lead of batch) {
    if (out.sent >= o.perRun || Date.now() - o.started > TIME_BUDGET_MS) break;
    const step = steps[lead.next_step - 1];
    if (!step?.variants?.length) {
      out.skipped.push({ lead_id: lead.lead_id, reason: "no_template_for_step" });
      continue;
    }

    // Pick an inbox with capacity (DB re-checks every rule incl. warm-up caps).
    let inbox: any = null, reason = "no_inbox";
    for (const ib of [...inboxes].sort(() => Math.random() - 0.5)) {
      const r = (unwrap(await db.rpc("outreach_can_send", {
        p_lead_id: lead.lead_id, p_channel: "email", p_inbox_id: ib.id, p_at: new Date().toISOString(),
      })) as any[])[0];
      reason = r?.reason ?? "unknown";
      if (r?.allowed) {
        inbox = ib;
        break;
      }
      if (reason !== "inbox_daily_cap" && reason !== "inbox_inactive") break;
    }
    if (!inbox) {
      out.skipped.push({ lead_id: lead.lead_id, reason });
      if (["global_daily_cap", "campaign_daily_cap", "inbox_daily_cap"].includes(reason)) break;
      continue;
    }

    const category = catName.get(lead.matched_category_ids[0])?.names;
    const categoryName = (category?.[lang] ?? category?.en ?? "").toLowerCase();
    let link = signupUrl({
      source: "email", campaign: c.name, city: lead.city, category: categoryName, language: lang,
      signupToken: lead.signup_token, step: lead.next_step,
    });
    let brochureUsed = false;
    if (step.include_brochure && lead.next_step > 1) {
      const b = await findBrochure(db, { city: lead.city, categoryIds: lead.matched_category_ids, language: lang });
      if (b) {
        link = b.url;
        brochureUsed = true;
      }
    }
    const variantIdx = pickVariant(lead.lead_id, lead.next_step, step.variants.length);
    const v = step.variants[variantIdx];
    const vars = {
      business_name: lead.business_name,
      category: categoryName,
      city: lead.city ?? "",
      detail: lead.rating ? `your ${lead.rating}-star rating` : `your shop in ${lead.city ?? "town"}`,
      rating: lead.rating ?? "",
      link,
      free_until: freeUntil ? new Date(freeUntil).toLocaleDateString(lang === "hi" ? "hi-IN" : "en-US", { month: "long", day: "numeric", year: "numeric" }) : "",
      sender_name: o.id.senderName,
    };
    const subject = renderTemplate(v.subject, vars).trim();
    const text = renderTemplate(v.body, vars).trim();
    const unsub = unsubscribeUrl(lead.unsubscribe_token);
    const footer = buildFooter(o.id, unsub);
    const content = checkOutreachContent(subject, text, {
      step: lead.next_step, hasAttachment: false, businessName: lead.business_name, city: lead.city ?? undefined,
    });
    const foot = checkFooter(footer, o.id, unsub);
    if (!content.ok || !foot.ok) {
      const problems = [...content.problems, ...foot.problems];
      if (!o.preview) {
        await db.from("outreach_campaigns").update({
          status: "paused",
          paused_reason: `content_check_failed:step${lead.next_step}:v${variantIdx}:${problems.join(",")}`.slice(0, 300),
          paused_at: new Date().toISOString(),
        }).eq("id", c.id);
      }
      out.skipped.push({ lead_id: lead.lead_id, reason: "content_check_failed", problems });
      break;
    }

    const message = {
      from: { email: inbox.email, name: inbox.display_name },
      to: lead.email,
      replyTo: env("OUTREACH_REPLY_TO") ?? inbox.email,
      subject,
      text: `${text}\n${footer}`,
      headers: listUnsubscribeHeaders(unsub, env("OUTREACH_UNSUBSCRIBE_MAILTO")),
      tags: { campaign: String(c.id), step: String(lead.next_step) },
    };
    if (o.preview) {
      out.previews.push({ lead_id: lead.lead_id, inbox: inbox.email, brochure: brochureUsed, ...message });
      continue;
    }

    // Randomised pacing (rule 6): never a burst of identical sends.
    if (out.sent > 0) await sleep(1500 + Math.random() * 4000);
    try {
      const res = await o.provider.send(message);
      unwrap(await db.rpc("outreach_record_send", {
        p_lead_id: lead.lead_id, p_campaign_id: c.id, p_inbox_id: inbox.id, p_channel: "email",
        p_step: lead.next_step, p_variant: variantIdx, p_subject: subject, p_body_preview: text,
        p_recipient: lead.email, p_provider_message_id: res.providerMessageId,
      }));
      out.sent++;
    } catch (e) {
      console.error("outreach send failed", lead.lead_id, e);
      out.skipped.push({ lead_id: lead.lead_id, reason: "send_failed", error: String(e).slice(0, 200) });
    }
  }
  return out;
}

/** Rule 3: only verified addresses. unverified -> valid | invalid | disposable. */
async function verifyEmails(limit: number) {
  const db = adminClient();
  const leads = unwrap(
    await db.from("outreach_leads").select("id,email,address_source,website_domain").eq("email_status", "unverified")
      .not("email", "is", null).limit(Math.min(limit, 200)),
  ) as any[];
  const counts: Record<string, number> = {};
  for (const l of leads) {
    let status: string;
    const syn = checkEmailSyntax(l.email);
    if (!syn.ok) status = syn.reason === "disposable" ? "disposable" : "invalid";
    // Free-mail addresses only when the business itself published them (address_source).
    else if (!l.address_source) status = "invalid";
    else {
      const mx = await hasMxRecord(syn.domain);
      if (mx === null) {
        counts.retry_later = (counts.retry_later ?? 0) + 1;
        continue;
      }
      status = mx ? "valid" : "invalid";
    }
    counts[status] = (counts[status] ?? 0) + 1;
    await db.from("outreach_leads").update({ email_status: status, email: syn.ok ? syn.normalized : l.email }).eq("id", l.id);
  }
  return { checked: leads.length, ...counts };
}
