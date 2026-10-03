// appstore-notifications: App Store Server Notifications V2 + StoreKit 2
// client verification -> entitlements.
//
// Notification: POST { signedPayload } (JWS, ES256, x5c chain in the header)
// Client verify: POST (user JWT) { action: "verify", signed_transaction }  (StoreKit 2 jwsRepresentation)
// The app must set appAccountToken = the user's uuid on purchase.
//
// JWS verification status: the signature is verified with the leaf
// certificate from the x5c header.
// TODO(before launch): verify the x5c chain up to Apple Root CA - G3 (pin its
// SHA-256 fingerprint in APPLE_ROOT_CA_G3_SHA256), check the Apple OIDs
// (leaf 1.2.840.113635.100.6.11.1, intermediate 1.2.840.113635.100.6.2.1) and
// validity dates; or use Apple's App Store Server Library. Until then set
// APPSTORE_ALLOW_UNVERIFIED_CHAIN=true only on staging; production refuses
// notifications while the chain check is missing.
import { compactVerify, decodeProtectedHeader, importX509 } from "jose";
import { applyEntitlement, beginBillingEvent, finishBillingEvent } from "../_shared/billing.ts";
import { env, envBool } from "../_shared/env.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { appStoreStatus, productInfo } from "../_shared/products.ts";
import { requireUser } from "../_shared/supabase.ts";

function derToPem(b64: string): string {
  return `-----BEGIN CERTIFICATE-----\n${b64.match(/.{1,64}/g)!.join("\n")}\n-----END CERTIFICATE-----`;
}

async function verifyAppleJws<T = any>(jws: string): Promise<T> {
  const header = decodeProtectedHeader(jws);
  if (header.alg !== "ES256" || !Array.isArray(header.x5c) || header.x5c.length < 2) {
    throw new HttpError(400, "invalid_jws_header");
  }
  if (!envBool("APPSTORE_ALLOW_UNVERIFIED_CHAIN", false)) {
    // See TODO above: refuse rather than trust an unchecked chain.
    throw new HttpError(503, "appstore_chain_verification_not_implemented");
  }
  const key = await importX509(derToPem(header.x5c[0]), "ES256");
  const { payload } = await compactVerify(jws, key);
  return JSON.parse(new TextDecoder().decode(payload)) as T;
}

interface TransactionInfo {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  bundleId: string;
  appAccountToken?: string;
  expiresDate?: number;
  revocationDate?: number;
  type?: string;
  environment?: string;
}

function checkApp(bundleId?: string, environment?: string) {
  const bundle = env("APPLE_BUNDLE_ID");
  if (bundle && bundleId && bundleId !== bundle) throw new HttpError(400, "wrong_bundle_id");
  const want = env("APPSTORE_ENVIRONMENT"); // Production | Sandbox | unset = both
  if (want && environment && want !== environment) throw new HttpError(400, "wrong_environment");
}

async function applyTransaction(tx: TransactionInfo, status: string, expectedUser?: string) {
  const sellerId = tx.appAccountToken?.toLowerCase();
  if (!sellerId) throw new HttpError(422, "missing_app_account_token");
  if (expectedUser && sellerId !== expectedUser) throw new HttpError(403, "purchase_belongs_to_another_user");
  const product = productInfo(tx.productId);
  if (!product || product.tier === "onboarding") throw new HttpError(422, "unknown_product");
  if (product.tier === "pro") {
    await applyEntitlement({
      p_seller_id: sellerId,
      p_store: "apple",
      p_provider: "app_store",
      p_product_id: product.productId,
      p_tier: "pro",
      p_status: tx.revocationDate ? "revoked" : status,
      p_original_transaction_id: `apple:${tx.originalTransactionId}`,
      p_renews_at: status === "active" && tx.expiresDate ? new Date(tx.expiresDate).toISOString() : null,
      p_expires_at: tx.expiresDate ? new Date(tx.expiresDate).toISOString() : null,
      p_raw: { transaction: tx.transactionId, environment: tx.environment },
    });
    return sellerId;
  }
  // Consumable credit pack: once per transactionId.
  const once = await beginBillingEvent("app_store", `tx:${tx.transactionId}:${status}`, "consumable", sellerId, tx);
  if (once === "duplicate") return sellerId;
  const delta = status === "refunded" || status === "revoked" ? -product.credits : product.credits;
  await applyEntitlement({
    p_seller_id: sellerId,
    p_store: "apple",
    p_provider: "app_store",
    p_product_id: product.productId,
    p_tier: "credits",
    p_status: "active",
    p_original_transaction_id: `apple-credits:${sellerId}`,
    p_credits_delta: delta,
    p_raw: { transaction: tx.transactionId },
  });
  await finishBillingEvent("app_store", `tx:${tx.transactionId}:${status}`);
  return sellerId;
}

serve(async (req) => {
  requireMethod(req, "POST");
  const body = await readJson<{ signedPayload?: string; action?: string; signed_transaction?: string }>(req);

  if (body.action === "verify") {
    const { user } = await requireUser(req);
    if (!body.signed_transaction) throw new HttpError(400, "signed_transaction_required");
    const tx = await verifyAppleJws<TransactionInfo>(body.signed_transaction);
    checkApp(tx.bundleId, tx.environment);
    const isSub = productInfo(tx.productId)?.tier === "pro";
    const active = !tx.revocationDate && (!isSub || (tx.expiresDate ?? 0) > Date.now());
    return json({ seller_id: await applyTransaction(tx, active ? "active" : "expired", user.id) });
  }

  if (!body.signedPayload) throw new HttpError(400, "signed_payload_required");
  const n = await verifyAppleJws<any>(body.signedPayload);
  const data = n.data ?? {};
  checkApp(data.bundleId, data.environment);
  if (n.notificationType === "TEST") return json({ ok: true, test: true });

  const state = await beginBillingEvent("app_store", n.notificationUUID, n.notificationType, null, {
    type: n.notificationType,
    subtype: n.subtype,
  });
  if (state === "duplicate") return json({ ok: true, duplicate: true });
  try {
    const status = appStoreStatus(n.notificationType, n.subtype);
    let seller: string | null = null;
    if (status && data.signedTransactionInfo) {
      const tx = await verifyAppleJws<TransactionInfo>(data.signedTransactionInfo);
      seller = await applyTransaction(tx, status);
    }
    await finishBillingEvent("app_store", n.notificationUUID);
    return json({ ok: true, seller_id: seller });
  } catch (e) {
    await finishBillingEvent("app_store", n.notificationUUID, e);
    if (e instanceof HttpError && e.status < 500) return json({ ok: false, error: e.code });
    throw e; // Apple retries non-200 responses
  }
});
