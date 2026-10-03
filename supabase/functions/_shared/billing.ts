// Webhook idempotency around public.record_billing_event / billing_events.
// "duplicate" only when the earlier delivery was processed successfully; a
// delivery that failed (processed_at null) is processed again on retry.
import { adminClient, unwrap } from "./supabase.ts";

export type BillingEventState = "new" | "retry" | "duplicate";

export async function beginBillingEvent(
  provider: string,
  eventId: string,
  eventType: string | null,
  sellerId: string | null,
  payload: unknown,
): Promise<BillingEventState> {
  const db = adminClient();
  const fresh = unwrap(await db.rpc("record_billing_event", {
    p_provider: provider,
    p_event_id: eventId,
    p_event_type: eventType,
    p_seller_id: sellerId,
    p_payload: payload,
  }));
  if (fresh) return "new";
  const row = unwrap(
    await db.from("billing_events").select("processed_at").eq("provider", provider).eq("event_id", eventId)
      .maybeSingle(),
  ) as { processed_at: string | null } | null;
  return row?.processed_at ? "duplicate" : "retry";
}

export async function finishBillingEvent(provider: string, eventId: string, error?: unknown) {
  await adminClient().from("billing_events").update(
    error
      ? { error: String(error).slice(0, 500) }
      : { processed_at: new Date().toISOString(), error: null },
  ).eq("provider", provider).eq("event_id", eventId);
}

export async function applyEntitlement(args: {
  p_seller_id: string;
  p_store: "play" | "apple" | "web" | "manual";
  p_provider: "google_play" | "app_store" | "stripe" | "razorpay" | "admin";
  p_product_id: string;
  p_tier: "pro" | "credits" | "onboarding";
  p_status: string;
  p_original_transaction_id: string | null;
  p_credits_delta?: number;
  p_renews_at?: string | null;
  p_expires_at?: string | null;
  p_external_customer_id?: string | null;
  p_raw?: unknown;
}) {
  return unwrap(await adminClient().rpc("apply_entitlement", args));
}
