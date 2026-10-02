// outreach-send action "send_one": request validation, gate order, server-built
// footer and headers, recording and audit (fakes instead of a database).
import { assert, assertEquals, assertFalse, assertStringIncludes } from "@std/assert";
import { normalizeBrochureFormat } from "../_shared/brochure.ts";
import { DryRunProvider } from "../_shared/email.ts";
import { businessAddressReady, hasBrochureLink } from "../_shared/outreach.ts";
import {
  type CampaignRow,
  type InboxRow,
  type LeadRow,
  parseSendOne,
  sendOne,
  type SendOneDeps,
} from "../_shared/send_one.ts";
import {
  checkWhatsAppTemplate,
  DryRunWhatsAppProvider,
  normalizeWhatsAppPhone,
} from "../_shared/whatsapp.ts";

const LEAD = "00000000-0000-4000-8000-00000000000a";
const CAMPAIGN = "00000000-0000-4000-8000-0000000000c1";
const INBOX = "00000000-0000-4000-8000-0000000000e1";
const ADMIN = { id: "00000000-0000-4000-8000-0000000000ad", email: "admin@iwant.example" };

const goodBody =
  "Hi Cool Fridge Store team,\n\nI saw your 4.6-star rating for refrigerators in Dallas. Buyers near you post " +
  "what they want on I Want USA and local shops send quotes. It's free for founding partners until April 2027.\n\n" +
  "Shall I set up your shop? https://iwantusa.example/sell?t=abc\n\nVivek";

function request(over: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    action: "send_one",
    lead_id: LEAD,
    campaign_id: CAMPAIGN,
    inbox_id: INBOX,
    channel: "email",
    step: 1,
    variant: 0,
    category_id: 4,
    subject: "Quick question for Cool Fridge Store",
    body: goodBody,
    footer: "CLIENT FOOTER (preview only)",
    whatsapp_template: null,
    confirmed_by_admin: true,
    ...over,
  };
}

interface World {
  deps: SendOneDeps;
  email: DryRunProvider;
  whatsapp: DryRunWhatsAppProvider;
  recorded: any[];
  annotated: any[];
  audited: any[];
  gateCalls: any[];
}

function world(o: {
  lead?: Partial<LeadRow>;
  campaign?: Partial<CampaignRow> | null;
  inbox?: Partial<InboxRow> | null;
  gate?: { allowed: boolean; reason: string };
  address?: unknown;
  enabled?: boolean;
  approvedTemplates?: string[] | null;
} = {}): World {
  const email = new DryRunProvider();
  const whatsapp = new DryRunWhatsAppProvider();
  const recorded: any[] = [], annotated: any[] = [], audited: any[] = [], gateCalls: any[] = [];
  const lead: LeadRow = {
    id: LEAD,
    business_name: "Cool Fridge Store",
    email: "info@coolfridge.example",
    phone: "+1 214 555 0100",
    city: "Dallas",
    stage: "sourced",
    touches_sent: 0,
    campaign_id: CAMPAIGN,
    matched_category_ids: [4, 7],
    unsubscribe_token: "tok123",
    ...o.lead,
  };
  const campaign: CampaignRow | null = o.campaign === null
    ? null
    : { id: CAMPAIGN, status: "active", activated_by: ADMIN.id, inbox_ids: [INBOX], ...o.campaign };
  const inbox: InboxRow | null = o.inbox === null
    ? null
    : { id: INBOX, email: "vivek@try-iwant.example", display_name: "Vivek", active: true, ...o.inbox };
  const deps: SendOneDeps = {
    settings: () =>
      Promise.resolve({
        outreachEnabled: o.enabled ?? true,
        businessAddress: "address" in o ? o.address : "1 Main St, Dover, DE 19901",
      }),
    loadLead: (id) => Promise.resolve(id === lead.id ? lead : null),
    loadCampaign: (id) => Promise.resolve(campaign && id === campaign.id ? campaign : null),
    loadInbox: (id) => Promise.resolve(inbox && id === inbox.id ? inbox : null),
    canSend: (leadId, channel, inboxId) => {
      gateCalls.push({ leadId, channel, inboxId });
      return Promise.resolve(o.gate ?? { allowed: true, reason: "ok" });
    },
    recordSend: (a) => {
      recorded.push(a);
      return Promise.resolve("event-1");
    },
    annotate: (eventId, adminId, meta) => {
      annotated.push({ eventId, adminId, meta });
      return Promise.resolve();
    },
    audit: (row) => {
      audited.push(row);
      return Promise.resolve();
    },
    email,
    whatsapp,
    identity: {
      senderName: "Vivek",
      senderRole: "Founder",
      companyName: "Calecute Technologies LLC",
      websiteUrl: "https://iwantusa.example",
      privacyUrl: "https://iwantusa.example/legal/privacy",
    },
    unsubscribeUrl: (t) =>
      `https://x.supabase.co/functions/v1/outreach-webhook?action=unsubscribe&token=${t}`,
    unsubscribeMailto: "unsub@try-iwant.example",
    approvedTemplates: o.approvedTemplates ?? null,
    whatsappLanguage: "en_US",
  };
  return { deps, email, whatsapp, recorded, annotated, audited, gateCalls };
}

Deno.test("send_one: refuses unless the admin confirmed this exact message", async () => {
  const w = world();
  assertEquals(await sendOne(w.deps, ADMIN, request({ confirmed_by_admin: false })), {
    ok: false,
    reason: "not_confirmed_by_admin",
  });
  assertEquals(await sendOne(w.deps, ADMIN, request({ confirmed_by_admin: "true" })), {
    ok: false,
    reason: "not_confirmed_by_admin",
  });
  assertEquals(w.email.sent.length, 0);
  assertEquals(w.gateCalls.length, 0);
});

Deno.test("send_one: request shape", () => {
  assert(parseSendOne(request()).ok);
  assertEquals(parseSendOne(request({ lead_id: "x" })), { ok: false, reason: "invalid_lead_id" });
  assertEquals(parseSendOne(request({ channel: "sms" })), { ok: false, reason: "channel_not_allowed" });
  assertEquals(parseSendOne(request({ step: 4 })), { ok: false, reason: "invalid_step" });
  assertEquals(parseSendOne(request({ inbox_id: null })), { ok: false, reason: "inbox_required" });
  assertEquals(parseSendOne(request({ body: null })), { ok: false, reason: "subject_and_body_required" });
  assertEquals(parseSendOne(request({ campaign_id: "nope" })), { ok: false, reason: "invalid_campaign_id" });
  assert(parseSendOne(request({ channel: "whatsapp", inbox_id: null, subject: null, body: null })).ok);
});

Deno.test("send_one: happy path sends once, with the server footer and one-click unsubscribe, then records", async () => {
  const w = world();
  const res = await sendOne(w.deps, ADMIN, request());
  assert(res.ok);
  assertEquals(res.event_id, "event-1");
  assertEquals(w.gateCalls, [{ leadId: LEAD, channel: "email", inboxId: INBOX }]);
  assertEquals(w.email.sent.length, 1);
  const m = w.email.sent[0];
  assertEquals(m.to, "info@coolfridge.example");
  assertEquals(m.from, { email: "vivek@try-iwant.example", name: "Vivek" });
  assertFalse(m.text.includes("CLIENT FOOTER"), "the client footer is never sent");
  assertStringIncludes(m.text, "1 Main St, Dover, DE 19901");
  assertStringIncludes(m.text, "token=tok123");
  assertEquals(m.headers?.["List-Unsubscribe-Post"], "List-Unsubscribe=One-Click");
  assertStringIncludes(m.headers?.["List-Unsubscribe"] ?? "", "token=tok123");
  assertEquals(w.recorded.length, 1);
  assertEquals(w.recorded[0].campaignId, CAMPAIGN);
  assertEquals(w.recorded[0].step, 1);
  assertEquals(w.recorded[0].recipient, "info@coolfridge.example");
  assertFalse(w.recorded[0].bodyPreview.includes("CLIENT FOOTER"));
  assertEquals(w.annotated[0].adminId, ADMIN.id);
  assertEquals(w.annotated[0].meta.via, "send_one");
  assertEquals(w.audited[0].actorId, ADMIN.id);
  assertEquals(w.audited[0].details.event_id, "event-1");
});

Deno.test("send_one: the database gate refuses -> nothing is sent or recorded", async () => {
  for (
    const reason of [
      "suppressed",
      "max_touches",
      "domain_daily_cap",
      "outside_business_hours",
      "business_address_missing",
    ]
  ) {
    const w = world({ gate: { allowed: false, reason } });
    assertEquals(await sendOne(w.deps, ADMIN, request()), { ok: false, reason });
    assertEquals(w.email.sent.length, 0);
    assertEquals(w.recorded.length, 0);
  }
});

Deno.test("send_one: content rules run on the edited text", async () => {
  const w = world();
  const long = await sendOne(w.deps, ADMIN, request({ body: goodBody + " word".repeat(120) }));
  assertFalse(long.ok);
  assert(
    !long.ok && long.reason.startsWith("content_check_failed:") && long.problems?.includes("body_too_long"),
  );
  const caps = await sendOne(w.deps, ADMIN, request({ subject: "FREE LEADS for Cool Fridge Store" }));
  assert(!caps.ok && caps.problems?.includes("all_caps_words"));
  const brochure = await sendOne(
    w.deps,
    ADMIN,
    request({
      body: goodBody.replace(
        "https://iwantusa.example/sell?t=abc",
        "https://x.supabase.co/storage/v1/object/public/brochures/dallas/fridge-v1.pdf",
      ),
    }),
  );
  assert(!brochure.ok && brochure.problems?.includes("brochure_in_first_email"));
  assertEquals(w.email.sent.length, 0);
  assertEquals(w.gateCalls.length, 0, "content is checked before the gate and the provider");
});

Deno.test("send_one: business address placeholder, disabled flag, identity", async () => {
  for (const address of ["{{US_BUSINESS_ADDRESS}}", "", null, undefined, "short"]) {
    const w = world({ address });
    assertEquals(await sendOne(w.deps, ADMIN, request()), { ok: false, reason: "business_address_missing" });
  }
  assertEquals(await sendOne(world({ enabled: false }).deps, ADMIN, request()), {
    ok: false,
    reason: "outreach_disabled",
  });
  const w = world();
  w.deps.identity = { ...w.deps.identity, privacyUrl: "" };
  assertEquals(await sendOne(w.deps, ADMIN, request()), {
    ok: false,
    reason: "outreach_identity_not_configured",
  });
});

Deno.test("send_one: lead, step, campaign and inbox must match", async () => {
  assertEquals(
    await sendOne(world().deps, ADMIN, request({ lead_id: "00000000-0000-4000-8000-0000000000ff" })),
    {
      ok: false,
      reason: "lead_not_found",
    },
  );
  assertEquals(await sendOne(world({ lead: { touches_sent: 1 } }).deps, ADMIN, request()), {
    ok: false,
    reason: "step_mismatch",
  });
  assertEquals(await sendOne(world({ lead: { campaign_id: null } }).deps, ADMIN, request()), {
    ok: false,
    reason: "no_campaign",
  });
  assertEquals(
    await sendOne(world().deps, ADMIN, request({ campaign_id: "00000000-0000-4000-8000-0000000000c2" })),
    { ok: false, reason: "campaign_mismatch" },
  );
  assertEquals(
    await sendOne(world({ campaign: { status: "draft", activated_by: null } }).deps, ADMIN, request()),
    {
      ok: false,
      reason: "campaign_draft",
    },
  );
  assertEquals(await sendOne(world({ campaign: { activated_by: null } }).deps, ADMIN, request()), {
    ok: false,
    reason: "campaign_not_activated",
  });
  assertEquals(await sendOne(world({ inbox: { active: false } }).deps, ADMIN, request()), {
    ok: false,
    reason: "inbox_inactive",
  });
  assertEquals(
    await sendOne(
      world({ campaign: { inbox_ids: ["00000000-0000-4000-8000-0000000000e2"] } }).deps,
      ADMIN,
      request(),
    ),
    {
      ok: false,
      reason: "inbox_not_in_campaign",
    },
  );
  assertEquals(await sendOne(world().deps, ADMIN, request({ category_id: 99 })), {
    ok: false,
    reason: "not_relevant",
  });
});

Deno.test("send_one: WhatsApp sends only an approved template to an opted-in phone (gate)", async () => {
  const wa = {
    channel: "whatsapp",
    inbox_id: null,
    subject: null,
    body: "preview",
    whatsapp_template: "seller_welcome",
  };
  const w = world({ approvedTemplates: ["seller_welcome"] });
  const res = await sendOne(w.deps, ADMIN, request(wa));
  assert(res.ok);
  assertEquals(w.whatsapp.sent, [{ to: "+1 214 555 0100", template: "seller_welcome", language: "en_US" }]);
  assertEquals(w.gateCalls, [{ leadId: LEAD, channel: "whatsapp", inboxId: null }]);
  assertEquals(w.recorded[0].subject, "template:seller_welcome");
  assertEquals(w.email.sent.length, 0);

  assertEquals(await sendOne(world({ approvedTemplates: ["other"] }).deps, ADMIN, request(wa)), {
    ok: false,
    reason: "whatsapp_template_not_approved",
  });
  assertEquals(await sendOne(world().deps, ADMIN, request({ ...wa, whatsapp_template: "" })), {
    ok: false,
    reason: "whatsapp_template_required",
  });
  assertEquals(await sendOne(world({ lead: { phone: null } }).deps, ADMIN, request(wa)), {
    ok: false,
    reason: "no_phone",
  });
  const gated = world({ gate: { allowed: false, reason: "no_opt_in" } });
  assertEquals(await sendOne(gated.deps, ADMIN, request(wa)), { ok: false, reason: "no_opt_in" });
  assertEquals(gated.whatsapp.sent.length, 0);
});

Deno.test("send_one: provider and record failures are reported, never 'ok'", async () => {
  const w = world();
  w.deps.email = { name: "broken", send: () => Promise.reject(new Error("boom")) };
  assertEquals(await sendOne(w.deps, ADMIN, request()), { ok: false, reason: "send_failed" });
  assertEquals(w.recorded.length, 0);
  const r = world();
  r.deps.recordSend = () => Promise.reject(new Error("PT409 outreach_suppressed"));
  assertEquals(await sendOne(r.deps, ADMIN, request()), { ok: false, reason: "sent_not_recorded" });
  assertEquals(r.audited.length, 0);
});

Deno.test("helpers: business address, brochure links, WhatsApp, brochure formats", () => {
  assert(businessAddressReady("1 Main St, Dover, DE 19901"));
  assertFalse(businessAddressReady("{{US_BUSINESS_ADDRESS}}"));
  assertFalse(businessAddressReady("12 Road {{CITY}}"));
  assertFalse(businessAddressReady("   "));
  assertFalse(businessAddressReady(42));
  assert(hasBrochureLink("see https://x.supabase.co/storage/v1/object/public/brochures/a/b.pdf"));
  assertFalse(hasBrochureLink("https://iwantusa.example/sell?utm_source=brochure"));
  assertEquals(normalizeWhatsAppPhone("+91 98765 43210"), "919876543210");
  assertEquals(normalizeWhatsAppPhone("12345"), null);
  assertEquals(checkWhatsAppTemplate("Seller Welcome"), { ok: false, reason: "invalid_whatsapp_template" });
  assertEquals(checkWhatsAppTemplate("seller_welcome"), { ok: true, name: "seller_welcome" });
  assertEquals(normalizeBrochureFormat("png"), "image");
  assertEquals(normalizeBrochureFormat("image"), "image");
  assertEquals(normalizeBrochureFormat(undefined), "pdf");
  assertEquals(normalizeBrochureFormat("one_pager"), "onepager");
  assertEquals(normalizeBrochureFormat("gif"), null);
});
