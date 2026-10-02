// Section 21.8 anti-spam rules that live in code (content, identity, opt-out,
// address hygiene). Volume caps, business hours, max touches and suppression
// are enforced in Postgres (outreach_can_send + the outreach_events trigger)
// and re-checked by outreach-send. Pure functions, unit tested.

export interface SequenceVariant {
  subject: string;
  body: string;
}

export interface SequenceStep {
  step: number;
  delay_days?: number;
  include_brochure?: boolean;
  variants: SequenceVariant[];
}

export interface OutreachIdentity {
  senderName: string;
  senderRole: string;
  companyName: string;
  physicalAddress: string;
  websiteUrl: string;
  privacyUrl: string;
  /** Country-specific advertisement notice (CAN-SPAM); may be empty. */
  adNotice?: string;
}

export const MAX_BODY_WORDS = 120;
export const MAX_SUBJECT_CHARS = 70;
export const ACRONYMS = new Set(["AC", "GST", "USA", "US", "LLC", "OPC", "TV", "LED", "HVAC", "CCTV", "UPI", "PIN", "ZIP", "OK", "RO", "PC"]);

export const SPAM_PHRASES = [
  "act now", "click here", "buy now", "limited time", "100% free", "free money", "guaranteed income",
  "earn $", "make money", "winner", "you have been selected", "urgent", "risk free trial", "no cost to you!!",
  "dear friend", "once in a lifetime", "cash bonus", "double your", "$$$", "call now", "order now",
  "special promotion", "this is not spam", "unsubscribe below to stop",
];

const URL_RE = /\bhttps?:\/\/[^\s<>()]+/gi;
const PLACEHOLDER_RE = /\{\{\s*([a-z_]+)\s*\}\}/gi;

export function renderTemplate(tpl: string, vars: Record<string, string | number | null | undefined>): string {
  return tpl.replace(PLACEHOLDER_RE, (whole, key: string) => {
    const v = vars[key.toLowerCase()];
    return v === undefined || v === null || v === "" ? whole : String(v);
  });
}

export function wordCount(text: string): number {
  return text.replace(URL_RE, " link ").split(/\s+/).filter((w) => /[\p{L}\p{N}]/u.test(w)).length;
}

export function countLinks(text: string): number {
  return (text.match(URL_RE) ?? []).length;
}

/** Deterministic template rotation so identical emails are not sent to everyone. */
export function pickVariant(leadId: string, step: number, nVariants: number): number {
  if (nVariants <= 1) return 0;
  let h = 2166136261;
  for (const ch of `${leadId}:${step}`) {
    h ^= ch.charCodeAt(0);
    h = Math.imul(h, 16777619);
  }
  return (h >>> 0) % nVariants;
}

export interface EmailCheck {
  ok: boolean;
  problems: string[];
}

/** Content rules (21.8 rule 4) on the rendered subject + body (footer excluded). */
export function checkOutreachContent(
  subject: string,
  body: string,
  opts: { step: number; hasAttachment?: boolean; businessName?: string; city?: string },
): EmailCheck {
  const problems: string[] = [];
  const all = `${subject}\n${body}`;
  if (PLACEHOLDER_RE.test(all)) problems.push("unrendered_placeholder");
  PLACEHOLDER_RE.lastIndex = 0;
  if (!subject.trim()) problems.push("empty_subject");
  if (subject.length > MAX_SUBJECT_CHARS) problems.push("subject_too_long");
  if (opts.step === 1 && /^\s*(re|fwd?|fw)\s*:/i.test(subject)) problems.push("misleading_subject_prefix");
  if (wordCount(body) >= MAX_BODY_WORDS) problems.push("body_too_long");
  if (countLinks(body) > 1) problems.push("too_many_links");
  if (opts.step === 1 && opts.hasAttachment) problems.push("attachment_in_first_email");
  if (/<img|<html|<a\s|<table|<div/i.test(body)) problems.push("not_plain_text");
  if (!body.replace(URL_RE, " ").includes("?")) problems.push("no_question_cta");
  if ((all.match(/!/g) ?? []).length > 1) problems.push("too_many_exclamations");
  const caps = all.match(/\b[A-Z]{4,}\b/g)?.filter((w) => !ACRONYMS.has(w)) ?? [];
  if (caps.length > 0) problems.push("all_caps_words");
  const lower = all.toLowerCase();
  for (const p of SPAM_PHRASES) {
    if (lower.includes(p)) problems.push(`spam_phrase:${p}`);
  }
  if (opts.businessName && !body.includes(opts.businessName)) problems.push("not_personalised_business");
  if (opts.city && !all.toLowerCase().includes(opts.city.toLowerCase())) problems.push("not_personalised_city");
  return { ok: problems.length === 0, problems };
}

/** Footer with honest identity (rule 8) and the opt-out lines (rule 5). */
export function buildFooter(id: OutreachIdentity, unsubscribeUrl: string): string {
  const lines = [
    "",
    "--",
    `${id.senderName}, ${id.senderRole}`,
    id.companyName,
    id.physicalAddress,
    `${id.websiteUrl} | Privacy: ${id.privacyUrl}`,
    id.adNotice ?? "",
    `Reply "no thanks" and we won't contact you again, or unsubscribe: ${unsubscribeUrl}`,
    `Not now? Reply "later" and we'll check back in 3 months.`,
  ];
  return lines.filter((l, i) => l !== "" || i === 0).join("\n");
}

export function checkFooter(footer: string, id: OutreachIdentity, unsubscribeUrl: string): EmailCheck {
  const problems: string[] = [];
  for (const [k, v] of Object.entries({
    company: id.companyName,
    address: id.physicalAddress,
    website: id.websiteUrl,
    privacy: id.privacyUrl,
    unsubscribe: unsubscribeUrl,
    sender: id.senderName,
  })) {
    if (!v || !footer.includes(v)) problems.push(`footer_missing_${k}`);
  }
  if (!/no thanks/i.test(footer)) problems.push("footer_missing_reply_opt_out");
  return { ok: problems.length === 0, problems };
}

/** RFC 8058 one-click unsubscribe headers. */
export function listUnsubscribeHeaders(unsubscribeUrl: string, mailto?: string): Record<string, string> {
  const parts = [`<${unsubscribeUrl}>`];
  if (mailto) parts.push(`<mailto:${mailto}?subject=unsubscribe>`);
  return { "List-Unsubscribe": parts.join(", "), "List-Unsubscribe-Post": "List-Unsubscribe=One-Click" };
}

// --- address hygiene (rule 3) ---------------------------------------------------------------

const EMAIL_RE = /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$/i;

export const DISPOSABLE_DOMAINS = new Set([
  "mailinator.com", "guerrillamail.com", "10minutemail.com", "tempmail.com", "temp-mail.org", "yopmail.com",
  "trashmail.com", "getnada.com", "sharklasers.com", "maildrop.cc", "dispostable.com", "fakeinbox.com",
  "throwawaymail.com", "mintemail.com", "mohmal.com", "emailondeck.com",
]);

/** Free-mail domains are allowed only when the business itself published the address (address_source). */
export const FREEMAIL_DOMAINS = new Set(["gmail.com", "yahoo.com", "yahoo.co.in", "outlook.com", "hotmail.com", "rediffmail.com", "icloud.com"]);

export function emailDomain(email: string): string {
  return email.split("@")[1]?.toLowerCase() ?? "";
}

export function checkEmailSyntax(email: string | null | undefined):
  | { ok: true; normalized: string; domain: string }
  | { ok: false; reason: string } {
  if (!email) return { ok: false, reason: "no_email" };
  const e = email.trim().toLowerCase();
  if (e.length > 254 || !EMAIL_RE.test(e)) return { ok: false, reason: "invalid_syntax" };
  const domain = emailDomain(e);
  if (DISPOSABLE_DOMAINS.has(domain)) return { ok: false, reason: "disposable" };
  if (/^(noreply|no-reply|donotreply|postmaster|abuse|mailer-daemon)@/.test(e)) {
    return { ok: false, reason: "non_human_mailbox" };
  }
  return { ok: true, normalized: e, domain };
}

// --- reply classification (rule 5) ----------------------------------------------------------

const NEGATIVE = [
  /\bno,? thanks?\b/i, /\bnot interested\b/i, /\bunsubscribe\b/i, /\bremove me\b/i, /\bstop\b/i,
  /\bdo not (contact|email)\b/i, /\bdon'?t (contact|email)\b/i, /\bspam\b/i, /\bleave me alone\b/i,
  /नहीं चाहिए/, /रुचि नहीं/, /\bno me interesa\b/i, /\bno gracias\b/i,
];
const NOT_NOW = [/\bnot now\b/i, /\blater\b/i, /\bin (a few|3|three) months\b/i, /\bremind me\b/i, /\bnext (month|quarter|year)\b/i, /बाद में/];

export type ReplyClass = "negative_reply" | "not_now" | "replied";

/** Keyword classifier; quoted history (lines starting with ">") is ignored. */
export function classifyReply(text: string): ReplyClass {
  const fresh = text.split(/\r?\n/).filter((l) => !l.trim().startsWith(">")).join("\n")
    .split(/\n-{2,}\s*\n|\nOn .+wrote:/)[0];
  if (NEGATIVE.some((r) => r.test(fresh))) return "negative_reply";
  if (NOT_NOW.some((r) => r.test(fresh))) return "not_now";
  return "replied";
}

// --- business address (rule 8) and manual sends -----------------------------------------------

/**
 * The CAN-SPAM postal address lives in app_settings.outreach_business_address.
 * Same rule as private.outreach_business_address_ready(): a string of at least
 * 10 characters with no {{...}} placeholder.
 */
export function businessAddressReady(v: unknown): v is string {
  return typeof v === "string" && v.trim().length >= 10 && !/\{\{|\}\}/.test(v);
}

const BROCHURE_LINK_RE = /\/(?:storage\/v1\/object\/public\/)?brochures\//i;

/** True when the text links to a stored brochure (only allowed from touch 2, rule 4). */
export function hasBrochureLink(text: string): boolean {
  return (text.match(URL_RE) ?? []).some((u) => BROCHURE_LINK_RE.test(u));
}
