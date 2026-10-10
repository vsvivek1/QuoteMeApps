// Seller billing products, identical ids in Play, App Store, Stripe and Razorpay
// so every store feeds the same `entitlements` rows (Sections 7 and 12).
//   seller_pro_monthly / seller_pro_annual  -> tier "pro" (subscription)
//   credits_10 / credits_50                 -> tier "credits" (consumable pack)
//   seller_onboarding                       -> tier "onboarding" (one-time fee: Play Billing non-consumable
//                                              in the Android apps, Stripe Checkout on the USA web,
//                                              web amount from app_settings.onboarding_fee_minor)
// Store-specific price ids come from env (see .env.example):
//   STRIPE_PRICE_<PRODUCT_ID_UPPER>, RAZORPAY_PLAN_<PRODUCT_ID_UPPER>, RAZORPAY_AMOUNT_<PRODUCT_ID_UPPER>
import { env } from "./env.ts";

export interface ProductInfo {
  productId: string;
  tier: "pro" | "credits" | "onboarding";
  credits: number;
  interval?: "month" | "year";
}

export const KNOWN_PRODUCTS = [
  "seller_pro_monthly",
  "seller_pro_annual",
  "credits_10",
  "credits_50",
  "seller_onboarding",
] as const;

/** Classifies any product id (store ids may carry a base-plan suffix, e.g. "seller_pro:monthly"). */
export function productInfo(productId: string): ProductInfo | null {
  const id = productId.trim().toLowerCase();
  if (id === "seller_onboarding") return { productId: id, tier: "onboarding", credits: 0 };
  const credits = /(?:^|[._:-])credits?[._:-]?(\d{1,4})(?:$|[._:-])/.exec(id);
  if (credits) return { productId: id, tier: "credits", credits: Number(credits[1]) };
  if (/(^|[._:-])(seller_)?pro($|[._:-])/.test(id) || id.startsWith("seller_pro")) {
    const interval = /annual|year|yearly/.test(id) ? "year" : "month";
    return { productId: id, tier: "pro", credits: 0, interval };
  }
  return null;
}

export function envKeyFor(prefix: string, productId: string): string {
  return `${prefix}_${productId.toUpperCase().replace(/[^A-Z0-9]/g, "_")}`;
}

export function stripePriceFor(productId: string): string | undefined {
  return env(envKeyFor("STRIPE_PRICE", productId));
}

export function razorpayPlanFor(productId: string): string | undefined {
  return env(envKeyFor("RAZORPAY_PLAN", productId));
}

export function razorpayAmountFor(productId: string): number | undefined {
  const v = env(envKeyFor("RAZORPAY_AMOUNT", productId));
  return v ? Number(v) : undefined;
}

// Store status -> entitlements.status ---------------------------------------------------------

export function stripeSubscriptionStatus(s: string): string {
  switch (s) {
    case "active":
    case "trialing":
      return "active";
    case "past_due":
      return "grace";
    case "unpaid":
      return "on_hold";
    case "paused":
      return "paused";
    case "canceled":
      return "cancelled";
    case "incomplete":
      return "pending";
    case "incomplete_expired":
      return "expired";
    default:
      return "pending";
  }
}

export function razorpaySubscriptionStatus(eventOrStatus: string): string {
  const s = eventOrStatus.replace(/^subscription\./, "");
  switch (s) {
    case "activated":
    case "charged":
    case "resumed":
    case "active":
    case "authenticated":
      return "active";
    case "pending":
      return "grace";
    case "halted":
      return "on_hold";
    case "paused":
      return "paused";
    case "cancelled":
      return "cancelled";
    case "completed":
    case "expired":
      return "expired";
    default:
      return "pending";
  }
}

/** Play subscriptionsv2 `subscriptionState`. */
export function playSubscriptionStatus(state: string): string {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return "active";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "grace";
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return "on_hold";
    case "SUBSCRIPTION_STATE_PAUSED":
      return "paused";
    case "SUBSCRIPTION_STATE_CANCELED":
      // Auto-renew off: still entitled until expiryTime (quote_entitlement checks expires_at).
      return "active";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expired";
    case "SUBSCRIPTION_STATE_PENDING":
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED":
      return "pending";
    default:
      return "pending";
  }
}

/** App Store Server Notifications V2 notificationType (+ subtype). */
export function appStoreStatus(type: string, subtype?: string): string | null {
  switch (type) {
    case "SUBSCRIBED":
    case "DID_RENEW":
    case "OFFER_REDEEMED":
    case "RENEWAL_EXTENDED":
      return "active";
    case "DID_CHANGE_RENEWAL_STATUS":
      // Auto-renew off keeps access until expiresDate (expires_at enforces the end).
      return "active";
    case "DID_FAIL_TO_RENEW":
      return subtype === "GRACE_PERIOD" ? "grace" : "on_hold";
    case "GRACE_PERIOD_EXPIRED":
      return "on_hold";
    case "EXPIRED":
      return "expired";
    case "REFUND":
      return "refunded";
    case "REVOKE":
      return "revoked";
    case "ONE_TIME_CHARGE":
      return "active";
    default:
      return null; // informational (TEST, PRICE_INCREASE, CONSUMPTION_REQUEST, ...)
  }
}
