// stripe-webhook (USA): Stripe -> entitlements.
// Verifies Stripe-Signature (STRIPE_WEBHOOK_SECRET), records the event once
// (record_billing_event = idempotency), then apply_entitlement.
// Seller id + product id travel in metadata set by create-checkout:
//   checkout session metadata, subscription_data.metadata, payment_intent_data.metadata.
// Handled: checkout.session.completed, customer.subscription.created|updated|deleted|paused|resumed,
//          invoice.paid (renewal date), charge.refunded (credit packs).
import { HttpError, json, requireMethod, serve } from "../_shared/http.ts";
import { requireEnv } from "../_shared/env.ts";
import { productInfo, stripeSubscriptionStatus } from "../_shared/products.ts";
import { stripeRequest, unixToIso } from "../_shared/payments.ts";
import { verifyStripeSignature } from "../_shared/signatures.ts";
import { applyEntitlement, beginBillingEvent, finishBillingEvent } from "../_shared/billing.ts";

serve(async (req) => {
  requireMethod(req, "POST");
  const raw = await req.text();
  if (!await verifyStripeSignature(raw, req.headers.get("Stripe-Signature"), requireEnv("STRIPE_WEBHOOK_SECRET"))) {
    throw new HttpError(400, "invalid_signature");
  }
  const event = JSON.parse(raw) as { id: string; type: string; data: { object: any } };
  const obj = event.data.object ?? {};
  const meta = obj.metadata ?? obj.subscription_details?.metadata ?? {};
  const sellerId: string | undefined = meta.seller_id ?? obj.client_reference_id ?? undefined;

  const state = await beginBillingEvent("stripe", event.id, event.type, sellerId ?? null, event);
  if (state === "duplicate") return json({ received: true, duplicate: true });
  try {
    const applied = await handle(event.type, obj, sellerId);
    await finishBillingEvent("stripe", event.id);
    return json({ received: true, applied });
  } catch (e) {
    await finishBillingEvent("stripe", event.id, e);
    console.error("stripe webhook failed", event.type, e);
    throw new HttpError(500, "webhook_processing_failed"); // Stripe retries; the retry is reprocessed
  }
});

const apply = applyEntitlement;

async function handle(type: string, obj: any, sellerId?: string): Promise<boolean> {
  switch (type) {
    case "checkout.session.completed": {
      if (!sellerId) return false;
      const product = productInfo(obj.metadata?.product_id ?? "");
      if (!product) return false;
      if (obj.mode === "subscription" && obj.subscription) {
        const sub = await stripeRequest("GET", `subscriptions/${obj.subscription}`);
        return applySubscription(sub, sellerId, product.productId);
      }
      if (obj.mode === "payment" && obj.payment_status === "paid" && product.tier === "credits") {
        await apply({
          p_seller_id: sellerId, p_store: "web", p_provider: "stripe", p_product_id: product.productId,
          p_tier: "credits", p_status: "active", p_original_transaction_id: `stripe:${obj.payment_intent ?? obj.id}`,
          p_credits_delta: product.credits, p_external_customer_id: obj.customer ?? null,
          p_raw: { checkout_session: obj.id },
        });
        return true;
      }
      return false;
    }
    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted":
    case "customer.subscription.paused":
    case "customer.subscription.resumed": {
      const sid = obj.metadata?.seller_id;
      const pid = obj.metadata?.product_id;
      if (!sid || !pid) return false;
      return applySubscription(obj, sid, pid);
    }
    case "invoice.paid": {
      const subId = obj.subscription ?? obj.parent?.subscription_details?.subscription;
      if (!subId) return false;
      const sub = await stripeRequest("GET", `subscriptions/${subId}`);
      if (!sub.metadata?.seller_id || !sub.metadata?.product_id) return false;
      return applySubscription(sub, sub.metadata.seller_id, sub.metadata.product_id);
    }
    case "charge.refunded": {
      const sid = obj.metadata?.seller_id;
      const product = productInfo(obj.metadata?.product_id ?? "");
      if (!sid || !product || product.tier !== "credits" || !obj.refunded) return false;
      await apply({
        p_seller_id: sid, p_store: "web", p_provider: "stripe", p_product_id: product.productId, p_tier: "credits",
        p_status: "refunded", p_original_transaction_id: `stripe:${obj.payment_intent}`,
        p_credits_delta: -product.credits, p_raw: { charge: obj.id },
      });
      return true;
    }
    default:
      return false;
  }
}

async function applySubscription(sub: any, sellerId: string, productId: string): Promise<boolean> {
  const product = productInfo(productId);
  if (!product || product.tier !== "pro") return false;
  // API >= 2025-03 moved current_period_end onto the subscription item.
  const periodEnd = sub.current_period_end ?? sub.items?.data?.[0]?.current_period_end;
  const status = stripeSubscriptionStatus(sub.status);
  await apply({
    p_seller_id: sellerId,
    p_store: "web",
    p_provider: "stripe",
    p_product_id: product.productId,
    p_tier: "pro",
    p_status: status,
    p_original_transaction_id: `stripe:${sub.id}`,
    p_renews_at: sub.cancel_at_period_end ? null : unixToIso(periodEnd),
    p_expires_at: sub.status === "canceled" ? unixToIso(sub.ended_at ?? periodEnd) : unixToIso(periodEnd),
    p_external_customer_id: sub.customer ?? null,
    p_raw: { subscription: sub.id, status: sub.status, cancel_at_period_end: sub.cancel_at_period_end ?? false },
  });
  return true;
}
