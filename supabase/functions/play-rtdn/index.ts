// play-rtdn: Google Play Real-time Developer Notifications (Pub/Sub push) and
// client purchase verification -> entitlements. Never trusts the client:
// every state comes from the Play Developer API (service account in
// PLAY_SERVICE_ACCOUNT with "View financial data" + "Manage orders").
//
// Pub/Sub push: POST { message: { data: base64(DeveloperNotification), messageId }, subscription }
//   auth: Pub/Sub OIDC token (Authorization: Bearer, aud = PLAY_RTDN_AUDIENCE,
//   email = PLAY_RTDN_PUSH_SERVICE_ACCOUNT) or ?secret=EDGE_WEBHOOK_SECRET.
// Client verify: POST (user JWT) { action: "verify", product_id, purchase_token, kind: "subs" | "inapp" }
//   inapp = credit packs and the seller_onboarding fee.
//   The app must set obfuscatedAccountId = the user's uuid when launching the purchase.
import { createRemoteJWKSet, jwtVerify } from "jose";
import { applyEntitlement, beginBillingEvent, finishBillingEvent } from "../_shared/billing.ts";
import { base64Decode } from "../_shared/crypto.ts";
import { env, requireEnv } from "../_shared/env.ts";
import { googleAccessToken, serviceAccountFromEnv } from "../_shared/google.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { playSubscriptionStatus, productInfo } from "../_shared/products.ts";
import { adminClient, bearer, hasValidWebhookSecret, requireUser } from "../_shared/supabase.ts";

const API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";
const SCOPE = "https://www.googleapis.com/auth/androidpublisher";
const googleJwks = createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs"));

async function playFetch(path: string, method = "GET"): Promise<any> {
  const sa = serviceAccountFromEnv("PLAY_SERVICE_ACCOUNT");
  if (!sa) throw new Error("play_not_configured");
  const token = await googleAccessToken(sa, [SCOPE]);
  const res = await fetch(`${API}/${path}`, { method, headers: { Authorization: `Bearer ${token}` } });
  const text = await res.text();
  if (!res.ok) throw new Error(`play_api_${res.status}:${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : {};
}

async function verifyPubSub(req: Request, url: URL): Promise<boolean> {
  if (hasValidWebhookSecret(req, url)) return true;
  const token = bearer(req);
  const aud = env("PLAY_RTDN_AUDIENCE");
  if (!token || !aud) return false;
  try {
    const { payload } = await jwtVerify(token, googleJwks, {
      issuer: ["https://accounts.google.com", "accounts.google.com"],
      audience: aud,
    });
    const expected = env("PLAY_RTDN_PUSH_SERVICE_ACCOUNT");
    return !expected || (payload.email === expected && payload.email_verified === true);
  } catch {
    return false;
  }
}

/** Fetches a subscription purchase and upserts the entitlement. Returns the seller id. */
async function syncSubscription(pkg: string, purchaseToken: string, expectedUser?: string) {
  const sub = await playFetch(`${pkg}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`);
  const sellerId: string | undefined = sub.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  if (!sellerId) throw new HttpError(422, "missing_obfuscated_account_id");
  if (expectedUser && sellerId !== expectedUser) throw new HttpError(403, "purchase_belongs_to_another_user");
  const line = sub.lineItems?.[0] ?? {};
  const product = productInfo(line.productId ?? "");
  if (!product || product.tier !== "pro") throw new HttpError(422, "unknown_product");
  await applyEntitlement({
    p_seller_id: sellerId,
    p_store: "play",
    p_provider: "google_play",
    p_product_id: product.productId,
    p_tier: "pro",
    p_status: playSubscriptionStatus(sub.subscriptionState),
    p_original_transaction_id: `play:${purchaseToken}`,
    p_renews_at: line.autoRenewingPlan?.autoRenewEnabled ? line.expiryTime ?? null : null,
    p_expires_at: line.expiryTime ?? null,
    p_raw: { state: sub.subscriptionState, order: sub.latestOrderId, linked: sub.linkedPurchaseToken ?? null },
  });
  if (sub.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING" && sub.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE") {
    // Unacknowledged purchases are refunded by Play after 3 days.
    await playFetch(`${pkg}/purchases/subscriptions/${line.productId}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`, "POST");
  }
  return sellerId;
}

/**
 * One-time products. Credit packs: grant once per purchase token, then consume
 * so the pack can be bought again. Onboarding fee: grant once, then acknowledge
 * (never consume, it is bought only once).
 */
async function syncOneTime(pkg: string, productId: string, purchaseToken: string, expectedUser?: string) {
  const p = await playFetch(`${pkg}/purchases/products/${productId}/tokens/${encodeURIComponent(purchaseToken)}`);
  const sellerId: string | undefined = p.obfuscatedExternalAccountId;
  if (!sellerId) throw new HttpError(422, "missing_obfuscated_account_id");
  if (expectedUser && sellerId !== expectedUser) throw new HttpError(403, "purchase_belongs_to_another_user");
  const product = productInfo(productId);
  if (!product || product.tier === "pro") throw new HttpError(422, "unknown_product");
  if (p.purchaseState !== 0) return { sellerId, granted: false, state: p.purchaseState };
  const once = await beginBillingEvent("google_play", `otp:${purchaseToken}`, "one_time_purchase", sellerId, {
    ...p,
    productId,
  });
  if (once !== "duplicate") {
    if (product.tier === "onboarding") {
      await applyEntitlement({
        p_seller_id: sellerId,
        p_store: "play",
        p_provider: "google_play",
        p_product_id: product.productId,
        p_tier: "onboarding",
        p_status: "active",
        p_original_transaction_id: `play:${purchaseToken}`,
        p_raw: { order: p.orderId },
      });
    } else {
      await applyEntitlement({
        p_seller_id: sellerId,
        p_store: "play",
        p_provider: "google_play",
        p_product_id: product.productId,
        p_tier: "credits",
        p_status: "active",
        p_original_transaction_id: `play-credits:${sellerId}`, // one running credit balance per seller
        p_credits_delta: product.credits,
        p_raw: { order: p.orderId },
      });
    }
    await finishBillingEvent("google_play", `otp:${purchaseToken}`);
  }
  // Unacknowledged purchases are refunded by Play after 3 days.
  if (product.tier === "onboarding") {
    if (p.acknowledgementState === 0) {
      await playFetch(`${pkg}/purchases/products/${productId}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`, "POST");
    }
  } else if (p.consumptionState === 0) {
    await playFetch(`${pkg}/purchases/products/${productId}/tokens/${encodeURIComponent(purchaseToken)}:consume`, "POST");
  }
  return { sellerId, granted: once !== "duplicate" };
}

serve(async (req) => {
  requireMethod(req, "POST");
  const url = new URL(req.url);
  const pkg = requireEnv("PLAY_PACKAGE_NAME"); // com.calecute.iwant.india | com.calecute.iwant.usa
  const body = await readJson<any>(req);

  if (body.action === "verify") {
    const { user } = await requireUser(req);
    if (!body.purchase_token || !body.product_id) throw new HttpError(400, "purchase_token_required");
    if (body.kind === "inapp") {
      return json(await syncOneTime(pkg, body.product_id, body.purchase_token, user.id));
    }
    return json({ seller_id: await syncSubscription(pkg, body.purchase_token, user.id) });
  }

  if (!await verifyPubSub(req, url)) throw new HttpError(401, "invalid_push_auth");
  const msg = body.message;
  if (!msg?.data) throw new HttpError(400, "invalid_pubsub_message");
  const n = JSON.parse(new TextDecoder().decode(base64Decode(msg.data)));
  if (n.packageName && n.packageName !== pkg) return json({ ignored: "other_package" });
  if (n.testNotification) return json({ ok: true, test: true });

  const eventId = `rtdn:${msg.messageId ?? msg.message_id}`;
  const state = await beginBillingEvent("google_play", eventId, Object.keys(n).find((k) => k.endsWith("Notification")) ?? null, null, n);
  if (state === "duplicate") return json({ ok: true, duplicate: true });
  try {
    let result: unknown = null;
    if (n.subscriptionNotification) {
      result = await syncSubscription(pkg, n.subscriptionNotification.purchaseToken);
    } else if (n.oneTimeProductNotification) {
      const o = n.oneTimeProductNotification; // type 1 = PURCHASED, 2 = CANCELED
      if (o.notificationType === 1) result = await syncOneTime(pkg, o.sku, o.purchaseToken);
    } else if (n.voidedPurchaseNotification) {
      result = await handleVoided(pkg, n.voidedPurchaseNotification);
    }
    await finishBillingEvent("google_play", eventId);
    return json({ ok: true, result });
  } catch (e) {
    await finishBillingEvent("google_play", eventId, e);
    if (e instanceof HttpError && e.status < 500) return json({ ok: false, error: e.code }); // ack: retry won't help
    throw e; // 5xx -> Pub/Sub redelivers
  }
});

async function handleVoided(pkg: string, v: { purchaseToken: string; orderId: string; productType: number }) {
  if (v.productType === 1) {
    // Subscription refund/revocation: re-read the purchase for the final state.
    try {
      return await syncSubscription(pkg, v.purchaseToken);
    } catch {
      return null;
    }
  }
  // One-time product refunded: the onboarding fee is due again; credit packs
  // lose their credits (never below zero).
  const { data } = await adminClient().from("billing_events").select("seller_id,payload")
    .eq("provider", "google_play").eq("event_id", `otp:${v.purchaseToken}`).maybeSingle();
  if (!data?.seller_id) return null;
  const productId = (data.payload as any)?.productId ?? "";
  const product = productInfo(productId);
  if (product?.tier === "onboarding") {
    await applyEntitlement({
      p_seller_id: data.seller_id,
      p_store: "play",
      p_provider: "google_play",
      p_product_id: product.productId,
      p_tier: "onboarding",
      p_status: "refunded",
      p_original_transaction_id: `play:${v.purchaseToken}`,
      p_raw: { voided_order: v.orderId },
    });
    return data.seller_id;
  }
  if (!product || product.tier !== "credits") return null;
  await applyEntitlement({
    p_seller_id: data.seller_id,
    p_store: "play",
    p_provider: "google_play",
    p_product_id: product.productId,
    p_tier: "credits",
    p_status: "active",
    p_original_transaction_id: `play-credits:${data.seller_id}`,
    p_credits_delta: -product.credits,
    p_raw: { voided_order: v.orderId },
  });
  return data.seller_id;
}
