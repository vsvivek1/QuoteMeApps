// Outreach email providers behind one interface (Resend, Amazon SES v2, Brevo)
// plus a dry-run provider. Plain-text only, no tracking pixels (21.8 rule 4):
// also turn OFF open/click tracking for the outreach domain in the provider.
// OUTREACH_PROVIDER = resend | ses | brevo | dry_run (default dry_run).
import { hmacSha256, sha256Hex, toHex } from "./crypto.ts";
import { env, requireEnv } from "./env.ts";

export interface OutgoingEmail {
  from: { email: string; name: string };
  to: string;
  replyTo?: string;
  subject: string;
  text: string;
  headers?: Record<string, string>;
  tags?: Record<string, string>;
}

export interface SendResult {
  providerMessageId: string;
}

export interface EmailProvider {
  name: string;
  send(msg: OutgoingEmail): Promise<SendResult>;
}

function fromHeader(f: OutgoingEmail["from"]) {
  return `${f.name.replace(/[<>"]/g, "")} <${f.email}>`;
}

export class ResendProvider implements EmailProvider {
  name = "resend";
  constructor(private apiKey = requireEnv("RESEND_API_KEY")) {}
  async send(m: OutgoingEmail): Promise<SendResult> {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${this.apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: fromHeader(m.from),
        to: [m.to],
        reply_to: m.replyTo,
        subject: m.subject,
        text: m.text,
        headers: m.headers,
        tags: Object.entries(m.tags ?? {}).map(([name, value]) => ({ name, value: value.replace(/[^\w-]/g, "_") })),
      }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(`resend_${res.status}:${JSON.stringify(body).slice(0, 300)}`);
    return { providerMessageId: String(body.id) };
  }
}

export class BrevoProvider implements EmailProvider {
  name = "brevo";
  constructor(private apiKey = requireEnv("BREVO_API_KEY")) {}
  async send(m: OutgoingEmail): Promise<SendResult> {
    const res = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: { "api-key": this.apiKey, "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({
        sender: { name: m.from.name, email: m.from.email },
        to: [{ email: m.to }],
        replyTo: m.replyTo ? { email: m.replyTo } : undefined,
        subject: m.subject,
        textContent: m.text,
        headers: m.headers,
        tags: Object.values(m.tags ?? {}),
      }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(`brevo_${res.status}:${JSON.stringify(body).slice(0, 300)}`);
    return { providerMessageId: String(body.messageId) };
  }
}

/** Amazon SES v2 SendEmail (Raw is not needed: Simple content + custom headers). Signed with SigV4. */
export class SesProvider implements EmailProvider {
  name = "ses";
  constructor(
    private region = requireEnv("AWS_SES_REGION"),
    private accessKeyId = requireEnv("AWS_ACCESS_KEY_ID"),
    private secretAccessKey = requireEnv("AWS_SECRET_ACCESS_KEY"),
    private configurationSet = env("AWS_SES_CONFIGURATION_SET"),
  ) {}
  async send(m: OutgoingEmail): Promise<SendResult> {
    const host = `email.${this.region}.amazonaws.com`;
    const path = "/v2/email/outbound-emails";
    const payload = JSON.stringify({
      FromEmailAddress: fromHeader(m.from),
      Destination: { ToAddresses: [m.to] },
      ReplyToAddresses: m.replyTo ? [m.replyTo] : undefined,
      Content: {
        Simple: {
          Subject: { Data: m.subject, Charset: "UTF-8" },
          Body: { Text: { Data: m.text, Charset: "UTF-8" } },
          Headers: Object.entries(m.headers ?? {}).map(([Name, Value]) => ({ Name, Value })),
        },
      },
      EmailTags: Object.entries(m.tags ?? {}).map(([Name, Value]) => ({ Name, Value: Value.replace(/[^\w-]/g, "_") })),
      ConfigurationSetName: this.configurationSet,
    });
    const headers = await sigV4Headers({
      method: "POST",
      host,
      path,
      region: this.region,
      service: "ses",
      body: payload,
      accessKeyId: this.accessKeyId,
      secretAccessKey: this.secretAccessKey,
    });
    const res = await fetch(`https://${host}${path}`, { method: "POST", headers, body: payload });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(`ses_${res.status}:${JSON.stringify(body).slice(0, 300)}`);
    return { providerMessageId: String(body.MessageId) };
  }
}

export class DryRunProvider implements EmailProvider {
  name = "dry_run";
  sent: OutgoingEmail[] = [];
  send(m: OutgoingEmail): Promise<SendResult> {
    this.sent.push(m);
    console.log("[outreach dry-run]", m.to, "|", m.subject);
    return Promise.resolve({ providerMessageId: `dry-${crypto.randomUUID()}` });
  }
}

export function providerFromEnv(): EmailProvider {
  switch ((env("OUTREACH_PROVIDER") ?? "dry_run").toLowerCase()) {
    case "resend":
      return new ResendProvider();
    case "brevo":
      return new BrevoProvider();
    case "ses":
      return new SesProvider();
    default:
      return new DryRunProvider();
  }
}

// --- SigV4 -------------------------------------------------------------------------------------

export async function sigV4Headers(o: {
  method: string;
  host: string;
  path: string;
  region: string;
  service: string;
  body: string;
  accessKeyId: string;
  secretAccessKey: string;
  now?: Date;
}): Promise<Record<string, string>> {
  const now = o.now ?? new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const date = amzDate.slice(0, 8);
  const payloadHash = await sha256Hex(o.body);
  const canonicalHeaders = `content-type:application/json\nhost:${o.host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`;
  const signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date";
  const canonicalRequest = [o.method, o.path, "", canonicalHeaders, signedHeaders, payloadHash].join("\n");
  const scope = `${date}/${o.region}/${o.service}/aws4_request`;
  const stringToSign = ["AWS4-HMAC-SHA256", amzDate, scope, await sha256Hex(canonicalRequest)].join("\n");
  let key = await hmacSha256(`AWS4${o.secretAccessKey}`, date);
  key = await hmacSha256(key, o.region);
  key = await hmacSha256(key, o.service);
  key = await hmacSha256(key, "aws4_request");
  const signature = toHex(await hmacSha256(key, stringToSign));
  return {
    "Content-Type": "application/json",
    "X-Amz-Date": amzDate,
    "X-Amz-Content-Sha256": payloadHash,
    Authorization: `AWS4-HMAC-SHA256 Credential=${o.accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
  };
}

// --- MX check (DNS over HTTPS works in the Edge runtime) --------------------------------------

const mxCache = new Map<string, boolean>();

/** true = has MX, false = no MX (NXDOMAIN / null MX), null = lookup failed (retry later). */
export async function hasMxRecord(domain: string): Promise<boolean | null> {
  const d = domain.toLowerCase();
  if (mxCache.has(d)) return mxCache.get(d)!;
  let ok = false;
  try {
    const res = await fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(d)}&type=MX`, {
      headers: { Accept: "application/dns-json" },
    });
    if (!res.ok) return null;
    const body = await res.json() as { Status: number; Answer?: { type: number; data: string }[] };
    if (body.Status !== 0 && body.Status !== 3) return null; // SERVFAIL etc.
    ok = body.Status === 0 && (body.Answer ?? []).some((a) => a.type === 15 && !/^0 \.$/.test(a.data));
  } catch (e) {
    console.warn("mx lookup failed", d, e);
    return null;
  }
  mxCache.set(d, ok);
  return ok;
}

// --- transactional mail (main app domain, NOT the outreach domain) -------------------------------
// TRANSACTIONAL_EMAIL_PROVIDER = resend | brevo | ses | stub (default stub: logs, sends nothing).
// From: TRANSACTIONAL_FROM_EMAIL / TRANSACTIONAL_FROM_NAME. Used for waitlist confirmation mails.

export function transactionalProviderFromEnv(): EmailProvider | null {
  switch ((env("TRANSACTIONAL_EMAIL_PROVIDER") ?? "stub").toLowerCase()) {
    case "resend":
      return new ResendProvider();
    case "brevo":
      return new BrevoProvider();
    case "ses":
      return new SesProvider();
    default:
      return null;
  }
}

export function transactionalFrom(): { email: string; name: string } | null {
  const email = env("TRANSACTIONAL_FROM_EMAIL");
  return email ? { email, name: env("TRANSACTIONAL_FROM_NAME") ?? "I Want" } : null;
}
