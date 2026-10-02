// razorpay-webhook (India): Razorpay Subscriptions + Payment Links -> entitlements.
// Verifies X-Razorpay-Signature (hex HMAC-SHA256 of the raw body with
// RAZORPAY_WEBHOOK_SECRET); idempotent on X-Razorpay-Event-Id.
// notes.seller_id + notes.product_id are set by create-checkout.
// Handled: subscription.* (activated, charged, pending, halted, paused, resumed,
//          cancelled, completed), payment_link.paid (credit packs), refund.processed.
import { applyEntitlement, beginBillingEvent, finishBillingEvent } from "../_shared/billing.ts";
import { sha256Hex } from "../_shared/crypto.ts";
import { requireEnv } from "../_shared/env.ts";
import { HttpError, json, requireMethod, serve } from "../_shared/http.ts";
import { unixToIso } from "../_shared/payments.ts";
import { productInfo, razorpaySubscriptionStatus } from "../_shared/products.ts";
import { verifyRazorpaySignature } from "../_shared/signatures.ts";

serve(async (req) => {
  requireMethod(req, "POST");
  const raw = await req.text();
  const ok = await verifyRazorpaySignature(raw, req.headers.get("X-Razorpay-Signature"), requireEnv("RAZORPAY_WEBHOOK_SECRET"));
  if (!ok) throw new HttpError(400, "invalid_signature");
  const event = JSON.parse(raw) as { event: string; payload: Record<string, { entity: any }>; created_at?: number };
  const eventId = req.headers.get("X-Razorpay-Event-Id") ?? `sha256:${await sha256Hex(raw)}`;

  const sub = event.payload.subscription?.entity;
  const payment = event.payload.payment?.entity;
  const link = event.payload.payment_link?.entity;
  const notes = sub?.notes ?? link?.notes ?? payment?.notes ?? {};
  const sellerId: string | null = notes.seller_id ?? null;

  const state = await beginBillingEvent("razorpay", eventId, event.event, sellerId, event);
  if (state === "duplicate") return json({ received: true, duplicate: true });
  try {
    const applied = sellerId ? await handle(event.event, sellerId, notes.product_id, sub, payment, link) : false;
    await finishBillingEvent("razorpay", eventId);
    return json({ received: true, applied });
  } catch (e) {
    await finishBillingEvent("razorpay", eventId, e);
    console.error("razorpay webhook failed", event.event, e);
    throw new HttpError(500, "webhook_processing_failed");
  }
});

async function handle(type: string, sellerId: string, productId: string | undefined, sub: any, payment: any, link: any) {
  const product = productInfo(productId ?? "");
  if (!product) return false;
  if (type.startsWith("subscription.") && sub && product.tier === "pro") {
    await applyEntitlement({
      p_seller_id: sellerId,
      p_store: "web",
      p_provider: "razorpay",
      p_product_id: product.productId,
      p_tier: "pro",
      p_status: razorpaySubscriptionStatus(type),
      p_original_transaction_id: `razorpay:${sub.id}`,
      p_renews_at: ["cancelled", "completed"].includes(sub.status) ? null : unixToIso(sub.charge_at ?? sub.current_end),
      p_expires_at: unixToIso(sub.current_end ?? sub.end_at),
      p_external_customer_id: sub.customer_id ?? null,
      p_raw: { subscription: sub.id, status: sub.status, plan_id: sub.plan_id, payment: payment?.id ?? null },
    });
    return true;
  }
  if (type === "payment_link.paid" && product.tier === "credits") {
    await applyEntitlement({
      p_seller_id: sellerId,
      p_store: "web",
      p_provider: "razorpay",
      p_product_id: product.productId,
      p_tier: "credits",
      p_status: "active",
      p_original_transaction_id: `razorpay:${payment?.id ?? link?.id}`,
      p_credits_delta: product.credits,
      p_external_customer_id: link?.customer?.contact ?? null,
      p_raw: { payment_link: link?.id, payment: payment?.id },
    });
    return true;
  }
  if (type === "refund.processed" && product.tier === "credits" && payment?.id) {
    await applyEntitlement({
      p_seller_id: sellerId,
      p_store: "web",
      p_provider: "razorpay",
      p_product_id: product.productId,
      p_tier: "credits",
      p_status: "refunded",
      p_original_transaction_id: `razorpay:${payment.id}`,
      p_credits_delta: -product.credits,
      p_raw: { refund_of: payment.id },
    });
    return true;
  }
  return false;
}
