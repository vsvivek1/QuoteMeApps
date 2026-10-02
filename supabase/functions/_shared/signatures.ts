// Webhook signature verification (Stripe, Razorpay, Svix/Resend). Pure + WebCrypto; unit tested.
import { base64Decode, base64Encode, hmacSha256, hmacSha256Hex, timingSafeEqual } from "./crypto.ts";

/**
 * Stripe: header `Stripe-Signature: t=<unix>,v1=<hex>[,v1=...]`,
 * signed payload = `${t}.${rawBody}`, HMAC-SHA256 with the endpoint secret (whsec_...).
 */
export async function verifyStripeSignature(
  rawBody: string,
  header: string | null,
  secret: string,
  toleranceSeconds = 300,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<boolean> {
  if (!header || !secret) return false;
  let t: number | undefined;
  const v1: string[] = [];
  for (const part of header.split(",")) {
    const [k, v] = part.split("=", 2).map((s) => s.trim());
    if (k === "t") t = Number(v);
    if (k === "v1" && v) v1.push(v);
  }
  if (!t || !Number.isFinite(t) || v1.length === 0) return false;
  if (Math.abs(nowSeconds - t) > toleranceSeconds) return false;
  const expected = await hmacSha256Hex(secret, `${t}.${rawBody}`);
  return v1.some((sig) => timingSafeEqual(sig, expected));
}

export async function stripeSignatureHeader(rawBody: string, secret: string, t: number): Promise<string> {
  return `t=${t},v1=${await hmacSha256Hex(secret, `${t}.${rawBody}`)}`;
}

/** Razorpay webhooks: `X-Razorpay-Signature` = hex HMAC-SHA256(rawBody, webhook secret). */
export async function verifyRazorpaySignature(rawBody: string, signature: string | null, secret: string): Promise<boolean> {
  if (!signature || !secret) return false;
  return timingSafeEqual(signature, await hmacSha256Hex(secret, rawBody));
}

/** Razorpay Checkout / subscription callback: HMAC(`${payment_id}|${subscription_id or order_id}`). */
export async function verifyRazorpayPaymentSignature(
  paymentId: string,
  orderOrSubscriptionId: string,
  signature: string,
  keySecret: string,
  isSubscription = false,
): Promise<boolean> {
  const payload = isSubscription ? `${paymentId}|${orderOrSubscriptionId}` : `${orderOrSubscriptionId}|${paymentId}`;
  return timingSafeEqual(signature, await hmacSha256Hex(keySecret, payload));
}

/**
 * Svix (used by Resend webhooks): headers svix-id, svix-timestamp, svix-signature
 * ("v1,<base64> v1,<base64>"); signed content = `${id}.${timestamp}.${body}`;
 * key = base64-decoded secret without the "whsec_" prefix.
 */
export async function verifySvixSignature(
  rawBody: string,
  headers: { id: string | null; timestamp: string | null; signature: string | null },
  secret: string,
  toleranceSeconds = 300,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<boolean> {
  const { id, timestamp, signature } = headers;
  if (!id || !timestamp || !signature || !secret) return false;
  const ts = Number(timestamp);
  if (!Number.isFinite(ts) || Math.abs(nowSeconds - ts) > toleranceSeconds) return false;
  const key = base64Decode(secret.startsWith("whsec_") ? secret.slice(6) : secret);
  const expected = base64Encode(await hmacSha256(key, `${id}.${timestamp}.${rawBody}`));
  return signature.split(" ").some((s) => {
    const [ver, sig] = s.split(",", 2);
    return ver === "v1" && !!sig && timingSafeEqual(sig, expected);
  });
}

export async function svixSignatureHeader(rawBody: string, id: string, timestamp: number, secret: string): Promise<string> {
  const key = base64Decode(secret.startsWith("whsec_") ? secret.slice(6) : secret);
  return `v1,${base64Encode(await hmacSha256(key, `${id}.${timestamp}.${rawBody}`))}`;
}
