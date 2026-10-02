// web-forms contract (web/README.md): validation, consents, CORS allow-list, Turnstile result checks.
import { assert, assertEquals } from "@std/assert";
import { corsHeadersFor, normalizePhoneDigits, validateForm } from "../_shared/webforms.ts";
import { checkTurnstileResult } from "../_shared/turnstile.ts";

const seller = {
  form: "seller_signup", country: "india", page: "/sellers", submitted_at: "2026-10-02T10:00:00Z",
  fields: { business_name: "Cool Fridge", contact_name: "Asha", email: "Asha@CoolFridge.example", phone: "+91 98450 00000",
    city: "Bengaluru", postal_code: "560001", category: "refrigerators", website: "https://coolfridge.example", junk: "x" },
  consents: [{ key: "consent_contact", text: "I agree that ... may contact me" }, { key: "consent_whatsapp", text: "Send me updates on WhatsApp" }],
  honeypot: "", turnstile_token: "tok",
};

Deno.test("seller sign-up validates, normalises and maps consents", () => {
  const v = validateForm(seller, "india");
  assert(v.ok);
  if (!v.ok) return;
  assertEquals(v.fields.email, "asha@coolfridge.example");
  assertEquals(v.fields.junk, undefined); // unknown fields dropped
  assertEquals(v.consents.map((c) => c.document), ["seller_contact", "whatsapp"]);
});

Deno.test("required consent, required fields, field types, country", () => {
  assertEquals(validateForm({ ...seller, consents: [] }, "india"), { ok: false, code: "consent_required", field: "consent_contact" });
  assertEquals(validateForm({ ...seller, fields: { ...seller.fields, city: "" } }, "india"), { ok: false, code: "missing_field", field: "city" });
  assertEquals(validateForm({ ...seller, fields: { ...seller.fields, email: "nope" } }, "india"), { ok: false, code: "invalid_email", field: "email" });
  assertEquals(validateForm({ ...seller, fields: { ...seller.fields, website: "javascript:alert(1)" } }, "india"), { ok: false, code: "invalid_url", field: "website" });
  assertEquals(validateForm({ ...seller, fields: { ...seller.fields, business_name: "x".repeat(121) } }, "india"), { ok: false, code: "field_too_long", field: "business_name" });
  assertEquals(validateForm(seller, "usa"), { ok: false, code: "wrong_country" });
  assertEquals(validateForm({ ...seller, form: "hack" }, "india"), { ok: false, code: "unknown_form" });
});

Deno.test("account deletion needs email or phone plus the confirmation", () => {
  const base = { form: "account_deletion", country: "usa", consents: [{ key: "confirm_delete", text: "I understand ..." }] };
  assertEquals(validateForm({ ...base, fields: { reason: "bye" } }, "usa"), { ok: false, code: "missing_field", field: "email|phone" });
  assert(validateForm({ ...base, fields: { phone: "+1 555 555 0100" } }, "usa").ok);
  assertEquals(validateForm({ ...base, consents: [], fields: { phone: "+15555550100" } }, "usa").ok, false);
});

Deno.test("waitlist and trends contact", () => {
  assert(validateForm({ form: "waitlist", country: "usa", fields: { email: "a@b.example", city: "Dallas" }, consents: [{ key: "consent_email", text: "Email me" }] }, "usa").ok);
  assert(validateForm({ form: "trends_contact", country: "", fields: { topic: "correction", message: "Typo" } }, "usa").ok);
});

Deno.test("CORS: only allow-listed origins", () => {
  const allowed = ["https://iwantusa.com", "https://www.iwantusa.com"];
  assertEquals(corsHeadersFor("https://iwantusa.com", allowed)?.["Access-Control-Allow-Origin"], "https://iwantusa.com");
  assertEquals(corsHeadersFor("https://evil.example", allowed), null);
  assertEquals(corsHeadersFor(null, allowed), null);
});

Deno.test("phone normalisation matches GoTrue / profiles.phone (digits, no +)", () => {
  assertEquals(normalizePhoneDigits("+1 (555) 555-0100", "US"), "15555550100");
  assertEquals(normalizePhoneDigits("98450 00000", "IN"), "919845000000");
  assertEquals(normalizePhoneDigits("+91 0000000001", "IN"), "910000000001");
  assertEquals(normalizePhoneDigits("123", "IN"), null);
});

Deno.test("Turnstile result checks", () => {
  assertEquals(checkTurnstileResult({ success: true, action: "waitlist", hostname: "iwantusa.com" }, { action: "waitlist", hostnames: ["iwantusa.com"] }), { ok: true });
  assertEquals(checkTurnstileResult({ success: false, "error-codes": ["timeout-or-duplicate"] }).reason, "timeout-or-duplicate");
  assertEquals(checkTurnstileResult({ success: true, action: "contact" }, { action: "waitlist" }).reason, "action_mismatch");
  assertEquals(checkTurnstileResult({ success: true, hostname: "evil.example" }, { hostnames: ["iwantusa.com"] }).reason, "hostname_mismatch");
  assertEquals(checkTurnstileResult({ success: true, challenge_ts: "2026-10-02T10:00:00Z" }, { maxAgeSeconds: 300, now: new Date("2026-10-02T10:10:00Z") }).reason, "token_too_old");
});
