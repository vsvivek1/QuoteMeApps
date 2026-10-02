// Webhook signature checks against vectors computed independently (Python hmac).
import { assert, assertEquals, assertFalse } from "@std/assert";
import {
  stripeSignatureHeader,
  svixSignatureHeader,
  verifyRazorpaySignature,
  verifyStripeSignature,
  verifySvixSignature,
} from "../_shared/signatures.ts";
import { hmacSha256Hex, timingSafeEqual } from "../_shared/crypto.ts";

const body = '{"id":"evt_1","type":"checkout.session.completed"}';
const T = 1700000000;

Deno.test("Stripe: known vector", async () => {
  const header = `t=${T},v1=a13d4b1f9003bc2fb6c06224e878b6056185eaa50d40e1e7dc05517f8af41d7b`;
  assert(await verifyStripeSignature(body, header, "whsec_test_secret", 300, T + 10));
  assertEquals(await stripeSignatureHeader(body, "whsec_test_secret", T), header);
});

Deno.test("Stripe: tampered body, wrong secret, stale timestamp, garbage header", async () => {
  const header = await stripeSignatureHeader(body, "whsec_test_secret", T);
  assertFalse(await verifyStripeSignature(body.replace("evt_1", "evt_2"), header, "whsec_test_secret", 300, T));
  assertFalse(await verifyStripeSignature(body, header, "whsec_other", 300, T));
  assertFalse(await verifyStripeSignature(body, header, "whsec_test_secret", 300, T + 301));
  assertFalse(await verifyStripeSignature(body, "nonsense", "whsec_test_secret", 300, T));
  assertFalse(await verifyStripeSignature(body, null, "whsec_test_secret", 300, T));
});

Deno.test("Stripe: any of several v1 signatures (secret rotation)", async () => {
  const good = await stripeSignatureHeader(body, "whsec_test_secret", T);
  const header = `t=${T},v1=${"0".repeat(64)},${good.split(",")[1]}`;
  assert(await verifyStripeSignature(body, header, "whsec_test_secret", 300, T));
});

Deno.test("Razorpay: known vector and tamper", async () => {
  const rb = '{"event":"subscription.charged"}';
  const sig = "95f1242fc512e8c50d452ead3cec4976bc6e244af5d8a1a9e328e1003dd93dfe";
  assert(await verifyRazorpaySignature(rb, sig, "rzp_webhook_secret"));
  assertFalse(await verifyRazorpaySignature(rb + " ", sig, "rzp_webhook_secret"));
  assertFalse(await verifyRazorpaySignature(rb, sig, "other"));
  assertFalse(await verifyRazorpaySignature(rb, null, "rzp_webhook_secret"));
});

Deno.test("Svix / Resend: known vector, rotation list, tamper, stale", async () => {
  const secret = "whsec_c3ZpeC10ZXN0LWtleS0wMTIzNDU2Nzg5YWJjZGVm";
  const sig = "v1,KGYddeU0/F1wJXwovrJ7aX3rVtAxoEUDHIQlqm58XO8=";
  const h = { id: "msg_123", timestamp: String(T), signature: sig };
  assert(await verifySvixSignature(body, h, secret, 300, T));
  assertEquals(await svixSignatureHeader(body, "msg_123", T, secret), sig);
  assert(await verifySvixSignature(body, { ...h, signature: `v1,AAAA ${sig}` }, secret, 300, T));
  assertFalse(await verifySvixSignature(body + "x", h, secret, 300, T));
  assertFalse(await verifySvixSignature(body, { ...h, id: "msg_124" }, secret, 300, T));
  assertFalse(await verifySvixSignature(body, h, secret, 300, T + 1000));
});

Deno.test("timing-safe compare and HMAC hex", async () => {
  assert(timingSafeEqual("abc", "abc"));
  assertFalse(timingSafeEqual("abc", "abd"));
  assertFalse(timingSafeEqual("abc", "abcd"));
  assertEquals((await hmacSha256Hex("key", "The quick brown fox jumps over the lazy dog")),
    "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"); // RFC 4231-style public vector
});
