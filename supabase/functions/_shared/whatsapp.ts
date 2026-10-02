// WhatsApp Business Platform (Cloud API) template sender for opted-in sellers
// only (Section 21.3, rule 21.8-9). Only Meta-approved templates are sent;
// free-form marketing text is never sent on WhatsApp.
// WHATSAPP_PROVIDER = cloud | dry_run (default dry_run).
import { env, requireEnv } from "./env.ts";

export interface WhatsAppTemplateMessage {
  /** Recipient phone, any format; sent as digits only (E.164 without "+"). */
  to: string;
  template: string;
  language: string;
}

export interface WhatsAppProvider {
  name: string;
  sendTemplate(m: WhatsAppTemplateMessage): Promise<{ providerMessageId: string }>;
}

/** E.164 digits without "+", or null when it cannot be a full international number. */
export function normalizeWhatsAppPhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const digits = phone.replace(/[^\d]/g, "");
  return digits.length >= 10 && digits.length <= 15 ? digits : null;
}

const TEMPLATE_RE = /^[a-z0-9_]{1,512}$/;

/**
 * Template names are Meta's lowercase identifiers. When an allow-list is
 * configured (WHATSAPP_APPROVED_TEMPLATES, comma separated) the name must be on it.
 */
export function checkWhatsAppTemplate(name: string | null | undefined, allowList?: string[] | null):
  | { ok: true; name: string }
  | { ok: false; reason: string } {
  const n = (name ?? "").trim();
  if (!n) return { ok: false, reason: "whatsapp_template_required" };
  if (!TEMPLATE_RE.test(n)) return { ok: false, reason: "invalid_whatsapp_template" };
  if (allowList && allowList.length && !allowList.includes(n)) {
    return { ok: false, reason: "whatsapp_template_not_approved" };
  }
  return { ok: true, name: n };
}

export function approvedTemplatesFromEnv(): string[] | null {
  const v = env("WHATSAPP_APPROVED_TEMPLATES");
  return v ? v.split(",").map((s) => s.trim()).filter(Boolean) : null;
}

export class CloudApiProvider implements WhatsAppProvider {
  name = "whatsapp_cloud";
  constructor(
    private phoneNumberId = requireEnv("WHATSAPP_PHONE_NUMBER_ID"),
    private accessToken = requireEnv("WHATSAPP_ACCESS_TOKEN"),
    private graphVersion = env("WHATSAPP_GRAPH_VERSION") ?? "v21.0",
  ) {}
  async sendTemplate(m: WhatsAppTemplateMessage) {
    const to = normalizeWhatsAppPhone(m.to);
    if (!to) throw new Error("whatsapp_invalid_phone");
    const res = await fetch(
      `https://graph.facebook.com/${this.graphVersion}/${this.phoneNumberId}/messages`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${this.accessToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          messaging_product: "whatsapp",
          to,
          type: "template",
          template: { name: m.template, language: { code: m.language } },
        }),
      },
    );
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(`whatsapp_${res.status}:${JSON.stringify(body).slice(0, 300)}`);
    return { providerMessageId: String(body?.messages?.[0]?.id ?? `wa-${crypto.randomUUID()}`) };
  }
}

export class DryRunWhatsAppProvider implements WhatsAppProvider {
  name = "dry_run";
  sent: WhatsAppTemplateMessage[] = [];
  sendTemplate(m: WhatsAppTemplateMessage) {
    this.sent.push(m);
    console.log("[whatsapp dry-run]", m.template, "->", normalizeWhatsAppPhone(m.to));
    return Promise.resolve({ providerMessageId: `dry-wa-${crypto.randomUUID()}` });
  }
}

export function whatsappProviderFromEnv(): WhatsAppProvider {
  return (env("WHATSAPP_PROVIDER") ?? "dry_run").toLowerCase() === "cloud"
    ? new CloudApiProvider()
    : new DryRunWhatsAppProvider();
}
