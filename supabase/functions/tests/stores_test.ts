// Product ids, store status mapping, FCM message shape, lead import mapping, Apple client secret.
import { assert, assertEquals } from "@std/assert";
import { appStoreStatus, envKeyFor, playSubscriptionStatus, productInfo, razorpaySubscriptionStatus, stripeSubscriptionStatus } from "../_shared/products.ts";
import { buildFcmMessage, isInvalidTokenError } from "../_shared/fcm.ts";
import { businessKey, buildOverpassQuery, normalizePhone, osmElementToLead, placesBudgetAllows } from "../_shared/leads.ts";
import { stripeFormEncode } from "../_shared/payments.ts";
import { appleClientSecret, appleClientSecretClaims } from "../_shared/apple.ts";
import { signupUrl } from "../_shared/brochure.ts";
import { base64Encode } from "../_shared/crypto.ts";
import { decodeJwtPayload } from "../_shared/crypto.ts";

Deno.test("product ids", () => {
  assertEquals(productInfo("seller_pro_monthly"), { productId: "seller_pro_monthly", tier: "pro", credits: 0, interval: "month" });
  assertEquals(productInfo("seller_pro_annual")?.interval, "year");
  assertEquals(productInfo("credits_10"), { productId: "credits_10", tier: "credits", credits: 10 });
  assertEquals(productInfo("credits_50")?.credits, 50);
  assertEquals(productInfo("seller_onboarding"), { productId: "seller_onboarding", tier: "onboarding", credits: 0 });
  assertEquals(productInfo("something_else"), null);
  assertEquals(envKeyFor("STRIPE_PRICE", "seller_pro_monthly"), "STRIPE_PRICE_SELLER_PRO_MONTHLY");
});

Deno.test("store states map onto entitlements.status", () => {
  assertEquals(stripeSubscriptionStatus("trialing"), "active");
  assertEquals(stripeSubscriptionStatus("past_due"), "grace");
  assertEquals(stripeSubscriptionStatus("canceled"), "cancelled");
  assertEquals(razorpaySubscriptionStatus("subscription.charged"), "active");
  assertEquals(razorpaySubscriptionStatus("subscription.halted"), "on_hold");
  assertEquals(playSubscriptionStatus("SUBSCRIPTION_STATE_IN_GRACE_PERIOD"), "grace");
  assertEquals(playSubscriptionStatus("SUBSCRIPTION_STATE_CANCELED"), "active"); // paid until expiry
  assertEquals(playSubscriptionStatus("SUBSCRIPTION_STATE_EXPIRED"), "expired");
  assertEquals(appStoreStatus("DID_FAIL_TO_RENEW", "GRACE_PERIOD"), "grace");
  assertEquals(appStoreStatus("REFUND"), "refunded");
  assertEquals(appStoreStatus("TEST"), null);
});

Deno.test("Stripe form encoding", () => {
  const p = stripeFormEncode({ mode: "subscription", line_items: [{ price: "price_1", quantity: 1 }], metadata: { seller_id: "s" }, skip: undefined });
  assertEquals(p.toString(), "mode=subscription&line_items%5B0%5D%5Bprice%5D=price_1&line_items%5B0%5D%5Bquantity%5D=1&metadata%5Bseller_id%5D=s");
});

Deno.test("FCM v1 message and invalid-token detection", () => {
  const m = buildFcmMessage({ token: "tok", title: "T", body: "B", data: { route: "/r/1", n: 5 as unknown as string }, collapseKey: "quotes:r1", channel: "quotes" });
  const msg = (m as any).message;
  assertEquals(msg.token, "tok");
  assertEquals(msg.data, { route: "/r/1", n: "5" });
  assertEquals(msg.android.notification.channel_id, "quotes");
  assertEquals(msg.apns.headers["apns-collapse-id"], "quotes:r1");
  assert(isInvalidTokenError(404, ""));
  assert(isInvalidTokenError(400, '{"error":{"status":"INVALID_ARGUMENT","message":"The registration token is not a valid FCM registration token"}}'));
  assert(!isInvalidTokenError(500, "UNREGISTERED"));
});

Deno.test("lead import: business key, phones, OSM mapping, Places budget", () => {
  assertEquals(businessKey({ website: "https://www.CoolFridge.example/contact", phone: "+15555550100" }), "domain:coolfridge.example");
  assertEquals(businessKey({ website: "https://facebook.com/coolfridge", phone: "+15555550100" }), "phone:+15555550100");
  assertEquals(businessKey({ placeId: "ChIJ1" }), "place:ChIJ1");
  assertEquals(normalizePhone("080-2345 6789", "IN"), "+918023456789");
  assertEquals(normalizePhone("(214) 555-0100", "US"), "+12145550100");
  const city = { name: "Dallas", state: "TX", lat: 32.78, lng: -96.8, timezone: "America/Chicago" };
  const q = buildOverpassQuery(city, 15000, ["shop=appliance", "craft=plumber"], 100);
  assert(q.includes('nwr["shop"="appliance"](around:15000,32.78,-96.8);'));
  const slugs = new Map([["refrigerators", 11], ["plumbing", 22]]);
  const lead = osmElementToLead({ type: "node", id: 42, lat: 32.8, lon: -96.7, tags: { name: "Cool Fridge", shop: "appliance", email: "Info@CoolFridge.example", website: "coolfridge.example" } }, city, "US", slugs)!;
  assertEquals(lead.matched_category_ids, [11]);
  assertEquals(lead.business_key, "domain:coolfridge.example");
  assertEquals(lead.email, "info@coolfridge.example");
  assertEquals(lead.address_source, "https://www.openstreetmap.org/node/42");
  assertEquals(lead.lawful_basis, "legitimate_interest");
  assertEquals(osmElementToLead({ type: "node", id: 1, tags: { name: "Cafe", amenity: "cafe" } }, city, "US", slugs), null); // relevance only
  assert(placesBudgetAllows(4000, 687, 0.032, 150));
  assert(!placesBudgetAllows(4000, 688, 0.032, 150));
});

Deno.test("signup link carries UTM + token", () => {
  const u = new URL(signupUrl({ baseUrl: "https://iwantindia.example/sell", source: "email", campaign: "Bengaluru Fridges", city: "Bengaluru", category: "Refrigerators", language: "hi", signupToken: "abc", step: 2 }));
  assertEquals(u.searchParams.get("utm_source"), "email");
  assertEquals(u.searchParams.get("utm_campaign"), "bengaluru-fridges");
  assertEquals(u.searchParams.get("utm_content"), "bengaluru_refrigerators_s2");
  assertEquals(u.searchParams.get("t"), "abc");
});

Deno.test("Apple client secret is an ES256 JWT with the right claims", async () => {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", kp.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${base64Encode(pkcs8)}\n-----END PRIVATE KEY-----`;
  const cfg = { teamId: "TEAM123456", keyId: "KEY1234567", privateKey: pem, clientId: "com.calecute.iwant.usa" };
  const jwt = await appleClientSecret(cfg, 1700000000);
  const [h, p, s] = jwt.split(".");
  assertEquals(JSON.parse(atob(h.replace(/-/g, "+").replace(/_/g, "/"))), { alg: "ES256", typ: "JWT", kid: "KEY1234567" });
  assertEquals(decodeJwtPayload(jwt), appleClientSecretClaims(cfg, 1700000000));
  const sig = Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/") + "=="), (c) => c.charCodeAt(0));
  assertEquals(sig.length, 64); // raw r||s
  assert(await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, kp.publicKey, sig, new TextEncoder().encode(`${h}.${p}`)));
});
