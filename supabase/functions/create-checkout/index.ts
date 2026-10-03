// create-checkout: web purchase links for seller plans and credit packs.
//   USA   -> Stripe Checkout (subscription or one-time payment) / Customer Portal
//            seller_onboarding: one-time fee, amount from app_settings.onboarding_fee_minor
//   India -> Razorpay Subscription (short_url) or Payment Link (credit packs)
// The store webhooks (stripe-webhook / razorpay-webhook) grant the entitlement;
// this function never does.
//
// POST (seller JWT) body:
//   { product_id: "seller_pro_monthly" | "seller_pro_annual" | "credits_10" | "credits_50" | "seller_onboarding",
//     success_url?, cancel_url? }            -> { url, provider, product_id }
//   { action: "portal", return_url? }        -> { url }  (Stripe only)
import { appCountry, env } from "../_shared/env.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { razorpayRequest, stripeRequest } from "../_shared/payments.ts";
import { KNOWN_PRODUCTS, productInfo, razorpayAmountFor, razorpayPlanFor, stripePriceFor } from "../_shared/products.ts";
import { enforceRateLimit } from "../_shared/ratelimit.ts";
import { adminClient, requireUser, unwrap } from "../_shared/supabase.ts";

function safeReturnUrl(url: string | undefined, fallbackPath: string): string {
  const base = env("CHECKOUT_RETURN_BASE_URL") ?? "https://example.com/seller/billing";
  const allowed = (env("CHECKOUT_ALLOWED_ORIGINS") ?? new URL(base).origin).split(",").map((s) => s.trim());
  if (url) {
    try {
      const u = new URL(url);
      if (allowed.includes(u.origin) || /^com\.calecute\.iwant\.(usa|india):$/.test(u.protocol)) return u.toString();
    } catch { /* fall through */ }
  }
  return `${base}${fallbackPath}`;
}

serve(async (req) => {
  requireMethod(req, "POST");
  const { user } = await requireUser(req);
  await enforceRateLimit("create-checkout", user.id, 10, 600);
  const body = await readJson<{ product_id?: string; action?: string; success_url?: string; cancel_url?: string; return_url?: string }>(req);

  const db = adminClient();
  const seller = unwrap(await db.from("sellers").select("id,business_name").eq("id", user.id).maybeSingle());
  if (!seller) throw new HttpError(403, "not_a_seller");
  const country = appCountry();

  if (body.action === "portal") {
    if (country !== "US") throw new HttpError(400, "portal_not_available");
    const ent = unwrap(
      await db.from("entitlements").select("external_customer_id").eq("seller_id", user.id).eq("provider", "stripe")
        .not("external_customer_id", "is", null).order("updated_at", { ascending: false }).limit(1).maybeSingle(),
    );
    if (!ent?.external_customer_id) throw new HttpError(404, "no_billing_account");
    const portal = await stripeRequest("POST", "billing_portal/sessions", {
      customer: ent.external_customer_id,
      return_url: safeReturnUrl(body.return_url, ""),
    });
    return json({ url: portal.url, provider: "stripe" });
  }

  const productId = (body.product_id ?? "").toLowerCase();
  const product = productInfo(productId);
  if (!product || !(KNOWN_PRODUCTS as readonly string[]).includes(productId)) throw new HttpError(400, "unknown_product");
  const meta = { seller_id: user.id, product_id: productId };

  if (product.tier === "onboarding") {
    if (country !== "US") throw new HttpError(400, "product_not_available");
    const fee = unwrap(await db.rpc("onboarding_fee_status", { p_seller_id: user.id })) as {
      due: boolean;
      amount_minor: number;
      currency: string;
    };
    if (!fee?.due) throw new HttpError(409, "onboarding_fee_not_due");
    const session = await stripeRequest("POST", "checkout/sessions", {
      mode: "payment",
      line_items: [{
        quantity: 1,
        price_data: {
          currency: (fee.currency || "USD").toLowerCase(),
          unit_amount: fee.amount_minor,
          product_data: { name: "I Want seller onboarding (one-time)" },
        },
      }],
      client_reference_id: user.id,
      customer_email: user.email || undefined,
      customer_creation: "always",
      metadata: meta,
      payment_intent_data: { metadata: meta },
      automatic_tax: { enabled: env("STRIPE_AUTOMATIC_TAX") === "true" },
      success_url: safeReturnUrl(body.success_url, "?status=success&session_id={CHECKOUT_SESSION_ID}"),
      cancel_url: safeReturnUrl(body.cancel_url, "?status=cancelled"),
    }, `checkout:${user.id}:${productId}:${Math.floor(Date.now() / 60000)}`);
    return json({ url: session.url, provider: "stripe", product_id: productId });
  }

  if (country === "US") {
    const price = stripePriceFor(productId);
    if (!price) throw new HttpError(503, "product_not_configured");
    const subscription = product.tier === "pro";
    const session = await stripeRequest("POST", "checkout/sessions", {
      mode: subscription ? "subscription" : "payment",
      line_items: [{ price, quantity: 1 }],
      client_reference_id: user.id,
      customer_email: user.email || undefined,
      metadata: meta,
      ...(subscription ? { subscription_data: { metadata: meta } } : { payment_intent_data: { metadata: meta } }),
      allow_promotion_codes: true,
      automatic_tax: { enabled: env("STRIPE_AUTOMATIC_TAX") === "true" },
      success_url: safeReturnUrl(body.success_url, "?status=success&session_id={CHECKOUT_SESSION_ID}"),
      cancel_url: safeReturnUrl(body.cancel_url, "?status=cancelled"),
    }, `checkout:${user.id}:${productId}:${Math.floor(Date.now() / 60000)}`);
    return json({ url: session.url, provider: "stripe", product_id: productId });
  }

  // India: Razorpay
  if (product.tier === "pro") {
    const planId = razorpayPlanFor(productId);
    if (!planId) throw new HttpError(503, "product_not_configured");
    const sub = await razorpayRequest("POST", "subscriptions", {
      plan_id: planId,
      total_count: product.interval === "year" ? 5 : 60, // renewals before Razorpay needs a new mandate
      quantity: 1,
      customer_notify: 1,
      notes: meta,
    });
    return json({ url: sub.short_url, provider: "razorpay", product_id: productId, subscription_id: sub.id });
  }
  const amount = razorpayAmountFor(productId);
  if (!amount) throw new HttpError(503, "product_not_configured");
  const link = await razorpayRequest("POST", "payment_links", {
    amount,
    currency: "INR",
    description: `${seller.business_name}: ${product.credits} quote credits`,
    reference_id: `${user.id.slice(0, 8)}-${productId}-${Date.now()}`.slice(0, 40),
    customer: { name: seller.business_name, email: user.email || undefined, contact: user.phone || undefined },
    notify: { sms: false, email: false },
    reminder_enable: false,
    notes: meta,
    callback_url: safeReturnUrl(body.success_url, "?status=success"),
    callback_method: "get",
    expire_by: Math.floor(Date.now() / 1000) + 24 * 3600,
  });
  return json({ url: link.short_url, provider: "razorpay", product_id: productId, payment_link_id: link.id });
});
