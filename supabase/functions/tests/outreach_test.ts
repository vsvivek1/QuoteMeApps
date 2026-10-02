// Section 21.8 anti-spam rules enforced in code.
import { assert, assertArrayIncludes, assertEquals, assertFalse } from "@std/assert";
import {
  buildFooter,
  checkEmailSyntax,
  checkFooter,
  checkOutreachContent,
  classifyReply,
  listUnsubscribeHeaders,
  type OutreachIdentity,
  pickVariant,
  renderTemplate,
  wordCount,
} from "../_shared/outreach.ts";

const good = {
  subject: "Quick question for Cool Fridge Store",
  body: "Hi Cool Fridge Store team,\n\nI saw your 4.6-star rating for refrigerators in Dallas. Buyers near you post " +
    "what they want on I Want USA and local shops send quotes. It's free for founding partners until April 2027.\n\n" +
    "Shall I set up your shop? https://iwantusa.example/sell?t=abc\n\nVivek",
};
const opts = { step: 1, businessName: "Cool Fridge Store", city: "Dallas" };

Deno.test("a short, personal, plain-text email passes", () => {
  const r = checkOutreachContent(good.subject, good.body, opts);
  assertEquals(r.problems, []);
  assert(r.ok);
});

Deno.test("too long, too many links, no question", () => {
  const long = good.body + " word".repeat(120);
  assertArrayIncludes(checkOutreachContent(good.subject, long, opts).problems, ["body_too_long"]);
  const links = good.body + " https://a.example https://b.example";
  assertArrayIncludes(checkOutreachContent(good.subject, links, opts).problems, ["too_many_links"]);
  const noQ = good.body.replace("Shall I set up your shop?", "Reply to set up your shop.");
  assertArrayIncludes(checkOutreachContent(good.subject, noQ, opts).problems, ["no_question_cta"]);
});

Deno.test("first email: no attachment, no fake Re:", () => {
  assertArrayIncludes(checkOutreachContent(good.subject, good.body, { ...opts, hasAttachment: true }).problems, [
    "attachment_in_first_email",
  ]);
  assertArrayIncludes(checkOutreachContent("Re: your order", good.body, opts).problems, ["misleading_subject_prefix"]);
  assertEquals(checkOutreachContent("Re: quick question", good.body, { ...opts, step: 2 }).ok, true);
});

Deno.test("caps, spam phrases, html, exclamations, placeholders, personalisation", () => {
  assertArrayIncludes(checkOutreachContent("FREE LEADS NOW", good.body, opts).problems, ["all_caps_words"]);
  assert(checkOutreachContent("GST and HVAC buyers", good.body, opts).problems.every((p) => p !== "all_caps_words"));
  assertArrayIncludes(checkOutreachContent(good.subject, good.body + " Act now!", opts).problems, ["spam_phrase:act now"]);
  assertArrayIncludes(checkOutreachContent(good.subject, good.body + '<img src="x">', opts).problems, ["not_plain_text"]);
  assertArrayIncludes(checkOutreachContent(good.subject, good.body + " Wow! Great!", opts).problems, ["too_many_exclamations"]);
  assertArrayIncludes(checkOutreachContent(good.subject, good.body + " {{rating}}", opts).problems, ["unrendered_placeholder"]);
  assertArrayIncludes(checkOutreachContent(good.subject, good.body, { ...opts, businessName: "Other Shop" }).problems, [
    "not_personalised_business",
  ]);
});

Deno.test("$$$ is matched literally (not as a regex anchor)", () => {
  assertFalse(checkOutreachContent(good.subject, good.body, opts).problems.includes("spam_phrase:$$$"));
  assertArrayIncludes(checkOutreachContent(good.subject, good.body + " $$$", opts).problems, ["spam_phrase:$$$"]);
});

Deno.test("template rendering and rotation", () => {
  assertEquals(renderTemplate("Hi {{ business_name }} in {{city}}", { business_name: "A1", city: "Pune" }), "Hi A1 in Pune");
  assertEquals(renderTemplate("Hi {{missing}}", {}), "Hi {{missing}}");
  const v = pickVariant("lead-1", 1, 3);
  assertEquals(pickVariant("lead-1", 1, 3), v);
  assert(v >= 0 && v < 3);
  const spread = new Set(Array.from({ length: 50 }, (_, i) => pickVariant(`lead-${i}`, 1, 3)));
  assertEquals(spread.size, 3);
  assertEquals(wordCount("one two https://x.example three"), 4);
});

Deno.test("honest identity footer + one-click unsubscribe", () => {
  const id: OutreachIdentity = {
    senderName: "Vivek", senderRole: "Founder", companyName: "Calecute Technologies LLC",
    physicalAddress: "1 Main St, Dover, DE 19901", websiteUrl: "https://iwantusa.example",
    privacyUrl: "https://iwantusa.example/legal/privacy",
  };
  const unsub = "https://x.supabase.co/functions/v1/outreach-webhook?action=unsubscribe&token=ab";
  const footer = buildFooter(id, unsub);
  assert(checkFooter(footer, id, unsub).ok);
  assertArrayIncludes(checkFooter(footer, { ...id, physicalAddress: "" }, unsub).problems, ["footer_missing_address"]);
  const h = listUnsubscribeHeaders(unsub, "unsub@try-iwant.example");
  assertEquals(h["List-Unsubscribe-Post"], "List-Unsubscribe=One-Click");
  assert(h["List-Unsubscribe"].startsWith(`<${unsub}>`));
});

Deno.test("address hygiene", () => {
  assert(checkEmailSyntax("Info@CoolFridge.example").ok);
  assertEquals(checkEmailSyntax("x@mailinator.com"), { ok: false, reason: "disposable" });
  assertEquals(checkEmailSyntax("noreply@shop.example"), { ok: false, reason: "non_human_mailbox" });
  assertEquals(checkEmailSyntax("not-an-email"), { ok: false, reason: "invalid_syntax" });
  assertEquals(checkEmailSyntax(null), { ok: false, reason: "no_email" });
});

Deno.test("reply classification: negative, not now, real reply, quoted text ignored", () => {
  assertEquals(classifyReply("No thanks, not interested."), "negative_reply");
  assertEquals(classifyReply("Please remove me from your list"), "negative_reply");
  assertEquals(classifyReply("STOP"), "negative_reply");
  assertEquals(classifyReply("नहीं चाहिए"), "negative_reply");
  assertEquals(classifyReply("Not now, maybe in 3 months"), "not_now");
  assertEquals(classifyReply("Sounds good, how do I start?"), "replied");
  assertEquals(classifyReply("Yes please call me\n> Reply 'no thanks' and we won't contact you again"), "replied");
});
