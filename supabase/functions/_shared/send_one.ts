// outreach-send action "send_one": one lead, one admin-reviewed message, one
// explicit confirmation (admin/BACKEND_NEEDS.md item 3). The panel never sends
// automatically; this path re-runs every server-side rule before sending:
//   1. the request itself (confirmed_by_admin, step = next touch, campaign / inbox match,
//      relevant category, approved WhatsApp template)
//   2. the database gate outreach_can_send(lead, channel, inbox): outreach flag, business
//      address, suppression, max 3 touches, one conversation, verified address / opt-in,
//      admin-activated campaign, step delay, business hours, global / campaign / domain /
//      inbox (warm-up) caps
//   3. the content rules (checkOutreachContent + no brochure link in touch 1)
//   4. the identity footer and List-Unsubscribe headers built here (the client footer is
//      only a preview and is ignored)
// then sends through the provider, records the send with outreach_record_send (whose
// trigger re-checks the hard rules again) and writes the admin audit log.
// Dependencies are injected so the whole flow is unit tested without a database.
import type { EmailProvider } from "./email.ts";
import {
  buildFooter,
  businessAddressReady,
  checkFooter,
  checkOutreachContent,
  hasBrochureLink,
  listUnsubscribeHeaders,
  type OutreachIdentity,
} from "./outreach.ts";
import { checkWhatsAppTemplate, normalizeWhatsAppPhone, type WhatsAppProvider } from "./whatsapp.ts";

export interface SendOneRequest {
  action: "send_one";
  lead_id: string;
  campaign_id?: string | null;
  inbox_id?: string | null;
  channel: "email" | "whatsapp";
  step: number;
  variant?: number | null;
  category_id?: number | null;
  subject?: string | null;
  body?: string | null;
  /** Client-side preview only; never sent. */
  footer?: string | null;
  whatsapp_template?: string | null;
  confirmed_by_admin?: boolean;
}

export type SendOneResult = { ok: true; event_id: string; provider_message_id: string } | {
  ok: false;
  reason: string;
  problems?: string[];
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Shape checks on the request body (before anything is read from the database). */
export function parseSendOne(
  b: Record<string, unknown>,
): { ok: true; req: SendOneRequest } | { ok: false; reason: string } {
  if (b.confirmed_by_admin !== true) return { ok: false, reason: "not_confirmed_by_admin" };
  if (typeof b.lead_id !== "string" || !UUID_RE.test(b.lead_id)) {
    return { ok: false, reason: "invalid_lead_id" };
  }
  if (b.channel !== "email" && b.channel !== "whatsapp") return { ok: false, reason: "channel_not_allowed" };
  if (typeof b.step !== "number" || !Number.isInteger(b.step) || b.step < 1 || b.step > 3) {
    return { ok: false, reason: "invalid_step" };
  }
  for (const k of ["campaign_id", "inbox_id"] as const) {
    const v = b[k];
    if (v != null && (typeof v !== "string" || !UUID_RE.test(v))) {
      return { ok: false, reason: `invalid_${k}` };
    }
  }
  if (b.category_id != null && (typeof b.category_id !== "number" || !Number.isInteger(b.category_id))) {
    return { ok: false, reason: "invalid_category_id" };
  }
  if (b.channel === "email") {
    if (b.inbox_id == null) return { ok: false, reason: "inbox_required" };
    if (typeof b.subject !== "string" || typeof b.body !== "string") {
      return { ok: false, reason: "subject_and_body_required" };
    }
    if (b.subject.length > 500 || b.body.length > 5000) return { ok: false, reason: "message_too_long" };
  }
  return { ok: true, req: b as unknown as SendOneRequest };
}

export interface LeadRow {
  id: string;
  business_name: string;
  email: string | null;
  phone: string | null;
  city: string | null;
  stage: string;
  touches_sent: number;
  campaign_id: string | null;
  matched_category_ids: number[];
  unsubscribe_token: string;
}

export interface CampaignRow {
  id: string;
  status: string;
  activated_by: string | null;
  inbox_ids: string[];
}

export interface InboxRow {
  id: string;
  email: string;
  display_name: string;
  active: boolean;
}

export interface SendOneDeps {
  /** app_settings.outreach_enabled and app_settings.outreach_business_address. */
  settings(): Promise<{ outreachEnabled: boolean; businessAddress: unknown }>;
  loadLead(id: string): Promise<LeadRow | null>;
  loadCampaign(id: string): Promise<CampaignRow | null>;
  loadInbox(id: string): Promise<InboxRow | null>;
  canSend(
    leadId: string,
    channel: string,
    inboxId: string | null,
  ): Promise<{ allowed: boolean; reason: string }>;
  recordSend(a: {
    leadId: string;
    campaignId: string;
    inboxId: string | null;
    channel: string;
    step: number;
    variant: number;
    subject: string;
    bodyPreview: string;
    recipient: string;
    providerMessageId: string;
  }): Promise<string>;
  /** Stamps the admin and the request context on the recorded event. */
  annotate(eventId: string, adminId: string, meta: Record<string, unknown>): Promise<void>;
  audit(
    row: { actorId: string; actorEmail: string | null; leadId: string; details: Record<string, unknown> },
  ): Promise<void>;
  email: EmailProvider;
  whatsapp: WhatsAppProvider;
  /** Identity from env; the postal address comes from the setting. */
  identity: Omit<OutreachIdentity, "physicalAddress">;
  unsubscribeUrl(token: string): string;
  unsubscribeMailto?: string;
  replyTo?: string;
  approvedTemplates?: string[] | null;
  whatsappLanguage: string;
}

export async function sendOne(
  deps: SendOneDeps,
  admin: { id: string; email: string | null },
  body: Record<string, unknown>,
): Promise<SendOneResult> {
  const parsed = parseSendOne(body);
  if (!parsed.ok) return parsed;
  const r = parsed.req;

  const settings = await deps.settings();
  if (!settings.outreachEnabled) return { ok: false, reason: "outreach_disabled" };
  if (!businessAddressReady(settings.businessAddress)) {
    return { ok: false, reason: "business_address_missing" };
  }
  const id: OutreachIdentity = { ...deps.identity, physicalAddress: settings.businessAddress };
  if (!id.companyName || !id.websiteUrl || !id.privacyUrl || !id.senderName) {
    return { ok: false, reason: "outreach_identity_not_configured" };
  }

  const lead = await deps.loadLead(r.lead_id);
  if (!lead) return { ok: false, reason: "lead_not_found" };
  if (r.step !== lead.touches_sent + 1) return { ok: false, reason: "step_mismatch" };
  if (!lead.campaign_id) return { ok: false, reason: "no_campaign" };
  if (r.campaign_id && r.campaign_id !== lead.campaign_id) return { ok: false, reason: "campaign_mismatch" };
  if (r.category_id != null && !lead.matched_category_ids.includes(r.category_id)) {
    return { ok: false, reason: "not_relevant" };
  }
  const campaign = await deps.loadCampaign(lead.campaign_id);
  if (!campaign) return { ok: false, reason: "no_campaign" };
  if (campaign.status !== "active") return { ok: false, reason: `campaign_${campaign.status}` };
  if (!campaign.activated_by) return { ok: false, reason: "campaign_not_activated" };

  let inbox: InboxRow | null = null;
  if (r.channel === "email") {
    inbox = await deps.loadInbox(r.inbox_id!);
    if (!inbox || !inbox.active) return { ok: false, reason: "inbox_inactive" };
    if (campaign.inbox_ids.length && !campaign.inbox_ids.includes(inbox.id)) {
      return { ok: false, reason: "inbox_not_in_campaign" };
    }
  }

  // Content (and template) rules before the database gate, so a refused
  // message never reaches a provider.
  let template: string | null = null;
  let subject = "";
  let text = "";
  if (r.channel === "email") {
    subject = r.subject!.trim();
    text = r.body!.trim();
    const content = checkOutreachContent(subject, text, {
      step: r.step,
      hasAttachment: false,
      businessName: lead.business_name,
      city: lead.city ?? undefined,
    });
    const problems = [...content.problems];
    if (r.step === 1 && hasBrochureLink(`${subject}\n${text}`)) problems.push("brochure_in_first_email");
    if (problems.length) return { ok: false, reason: `content_check_failed:${problems.join(",")}`, problems };
  } else {
    const t = checkWhatsAppTemplate(r.whatsapp_template, deps.approvedTemplates);
    if (!t.ok) return t;
    template = t.name;
    if (!normalizeWhatsAppPhone(lead.phone)) return { ok: false, reason: "no_phone" };
  }

  // The database gate decides last, right before sending.
  const gate = await deps.canSend(lead.id, r.channel, inbox?.id ?? null);
  if (!gate.allowed) return { ok: false, reason: gate.reason };

  let providerMessageId: string;
  let recipient: string;
  if (r.channel === "email") {
    const unsub = deps.unsubscribeUrl(lead.unsubscribe_token);
    const footer = buildFooter(id, unsub);
    const foot = checkFooter(footer, id, unsub);
    if (!foot.ok) {
      return { ok: false, reason: `footer_check_failed:${foot.problems.join(",")}`, problems: foot.problems };
    }
    recipient = lead.email!;
    try {
      providerMessageId = (await deps.email.send({
        from: { email: inbox!.email, name: inbox!.display_name },
        to: recipient,
        replyTo: deps.replyTo ?? inbox!.email,
        subject,
        text: `${text}\n${footer}`,
        headers: listUnsubscribeHeaders(unsub, deps.unsubscribeMailto),
        tags: { campaign: String(campaign.id), step: String(r.step), via: "send_one" },
      })).providerMessageId;
    } catch (e) {
      console.error("send_one email failed", lead.id, e);
      return { ok: false, reason: "send_failed" };
    }
  } else {
    recipient = lead.phone!;
    try {
      providerMessageId = (await deps.whatsapp.sendTemplate({
        to: recipient,
        template: template!,
        language: deps.whatsappLanguage,
      }))
        .providerMessageId;
    } catch (e) {
      console.error("send_one whatsapp failed", lead.id, e);
      return { ok: false, reason: "send_failed" };
    }
  }

  let eventId: string;
  try {
    eventId = await deps.recordSend({
      leadId: lead.id,
      campaignId: campaign.id,
      inboxId: inbox?.id ?? null,
      channel: r.channel,
      step: r.step,
      variant: typeof r.variant === "number" ? r.variant : 0,
      subject: r.channel === "email" ? subject : `template:${template}`,
      bodyPreview: r.channel === "email" ? text : `template:${template}`,
      recipient,
      providerMessageId,
    });
  } catch (e) {
    // The provider accepted the message but the database refused to record it.
    console.error("send_one record failed after provider send", lead.id, providerMessageId, e);
    return { ok: false, reason: "sent_not_recorded" };
  }
  const meta = {
    via: "send_one",
    confirmed_by_admin: true,
    category_id: r.category_id ?? null,
    whatsapp_template: template,
    provider: r.channel === "email" ? deps.email.name : deps.whatsapp.name,
  };
  await deps.annotate(eventId, admin.id, meta);
  await deps.audit({
    actorId: admin.id,
    actorEmail: admin.email,
    leadId: lead.id,
    details: {
      ...meta,
      event_id: eventId,
      channel: r.channel,
      step: r.step,
      campaign_id: campaign.id,
      inbox_id: inbox?.id ?? null,
    },
  });
  return { ok: true, event_id: eventId, provider_message_id: providerMessageId };
}
