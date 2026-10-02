// Pure helpers for the web-forms Edge Function (validation, CORS, consents).
// Contract: web/README.md "Form endpoint contract".
import { checkEmailSyntax } from "./outreach.ts";

export const FORM_KINDS = ["seller_signup", "contact", "waitlist", "account_deletion", "trends_contact"] as const;
export type FormKind = typeof FORM_KINDS[number];

export interface FormPayload {
  form: string;
  country?: string;
  page?: string;
  submitted_at?: string;
  fields?: Record<string, string | string[]>;
  consents?: { key: string; text: string }[];
  honeypot?: string;
  turnstile_token?: string;
}

interface FieldRule {
  max: number;
  required?: boolean;
  type?: "email" | "phone" | "url" | "postal";
}

export const FORM_RULES: Record<FormKind, { fields: Record<string, FieldRule>; requiredConsents: string[]; requireOne?: string[] }> = {
  seller_signup: {
    fields: {
      business_name: { max: 120, required: true },
      contact_name: { max: 80, required: true },
      email: { max: 160, required: true, type: "email" },
      phone: { max: 20, required: true, type: "phone" },
      city: { max: 80, required: true },
      postal_code: { max: 10, required: true, type: "postal" },
      category: { max: 80, required: true },
      website: { max: 200, type: "url" },
    },
    requiredConsents: ["consent_contact"],
  },
  contact: {
    fields: {
      name: { max: 80, required: true },
      email: { max: 160, required: true, type: "email" },
      topic: { max: 60, required: true },
      message: { max: 4000, required: true },
    },
    requiredConsents: [],
  },
  waitlist: {
    fields: {
      email: { max: 160, required: true, type: "email" },
      city: { max: 80, required: true },
      postal_code: { max: 10, type: "postal" },
      whatsapp: { max: 20, type: "phone" },
      source: { max: 60 },
    },
    requiredConsents: ["consent_email"],
  },
  account_deletion: {
    fields: {
      email: { max: 160, type: "email" },
      phone: { max: 20, type: "phone" },
      reason: { max: 1000 },
    },
    requiredConsents: ["confirm_delete"],
    requireOne: ["email", "phone"],
  },
  trends_contact: {
    fields: {
      topic: { max: 60, required: true },
      article: { max: 300 },
      email: { max: 160, type: "email" },
      message: { max: 4000, required: true },
    },
    requiredConsents: [],
  },
};

/** consent key on the form -> consents.document */
export const CONSENT_DOCUMENT: Record<string, string> = {
  consent_contact: "seller_contact",
  consent_whatsapp: "whatsapp",
  consent_email: "email_marketing",
  confirm_delete: "account_deletion",
};

export type Validated = {
  ok: true;
  form: FormKind;
  fields: Record<string, string>;
  consents: { key: string; text: string; document: string }[];
} | { ok: false; code: string; field?: string };

export function validateForm(p: FormPayload, expectedCountry?: "usa" | "india"): Validated {
  if (!FORM_KINDS.includes(p.form as FormKind)) return { ok: false, code: "unknown_form" };
  const form = p.form as FormKind;
  if (form !== "trends_contact" && expectedCountry && p.country && p.country !== expectedCountry) {
    return { ok: false, code: "wrong_country" };
  }
  const rules = FORM_RULES[form];
  const fields: Record<string, string> = {};
  for (const [k, raw] of Object.entries(p.fields ?? {})) {
    const rule = rules.fields[k];
    if (!rule) continue; // unknown fields are dropped, never stored
    const v = (Array.isArray(raw) ? raw.join(", ") : String(raw ?? "")).trim();
    if (!v) continue;
    if (v.length > rule.max) return { ok: false, code: "field_too_long", field: k };
    if (rule.type === "email") {
      const e = checkEmailSyntax(v);
      if (!e.ok) return { ok: false, code: "invalid_email", field: k };
      fields[k] = e.normalized;
      continue;
    }
    if (rule.type === "phone" && !/^\+?[\d\s().-]{7,20}$/.test(v)) return { ok: false, code: "invalid_phone", field: k };
    if (rule.type === "postal" && !/^[A-Za-z0-9 -]{3,10}$/.test(v)) return { ok: false, code: "invalid_postal_code", field: k };
    if (rule.type === "url") {
      try {
        const u = new URL(v);
        if (!/^https?:$/.test(u.protocol)) throw new Error();
      } catch {
        return { ok: false, code: "invalid_url", field: k };
      }
    }
    fields[k] = v;
  }
  for (const [k, rule] of Object.entries(rules.fields)) {
    if (rule.required && !fields[k]) return { ok: false, code: "missing_field", field: k };
  }
  if (rules.requireOne && !rules.requireOne.some((k) => fields[k])) {
    return { ok: false, code: "missing_field", field: rules.requireOne.join("|") };
  }
  const consents = (p.consents ?? [])
    .filter((c) => c && typeof c.key === "string" && typeof c.text === "string" && c.text.trim().length > 0)
    .map((c) => ({ key: c.key, text: c.text.slice(0, 2000), document: CONSENT_DOCUMENT[c.key] ?? "web_form" }));
  for (const k of rules.requiredConsents) {
    if (!consents.some((c) => c.key === k)) return { ok: false, code: "consent_required", field: k };
  }
  return { ok: true, form, fields, consents };
}

/** Allowed-origin CORS: echoes the origin only when it is on the list. */
export function corsHeadersFor(origin: string | null, allowed: string[]): Record<string, string> | null {
  if (!origin || !allowed.includes(origin)) return null;
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

/** Digits-only E.164 without "+", the format GoTrue / profiles.phone use. */
export function normalizePhoneDigits(phone: string, country: "IN" | "US"): string | null {
  let d = phone.replace(/[^\d+]/g, "");
  if (d.startsWith("+")) return d.slice(1).length >= 8 ? d.slice(1) : null;
  d = d.replace(/^0+/, "");
  if (d.length === 10) return (country === "IN" ? "91" : "1") + d;
  if (country === "US" && d.length === 11 && d.startsWith("1")) return d;
  if (country === "IN" && d.length === 12 && d.startsWith("91")) return d;
  return null;
}

export function countryParam(c: "IN" | "US"): "usa" | "india" {
  return c === "US" ? "usa" : "india";
}
