// Minimal Stripe and Razorpay REST clients (fetch only, no SDK needed in Deno).
import { base64Encode } from "./crypto.ts";
import { requireEnv } from "./env.ts";

/** Stripe form encoding: nested objects/arrays -> a[b][0]=c. */
export function stripeFormEncode(obj: Record<string, unknown>, prefix = "", out = new URLSearchParams()): URLSearchParams {
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null) continue;
    const key = prefix ? `${prefix}[${k}]` : k;
    if (Array.isArray(v)) {
      v.forEach((item, i) => {
        if (item !== null && typeof item === "object") stripeFormEncode(item as Record<string, unknown>, `${key}[${i}]`, out);
        else out.append(`${key}[${i}]`, String(item));
      });
    } else if (typeof v === "object") {
      stripeFormEncode(v as Record<string, unknown>, key, out);
    } else {
      out.append(key, String(v));
    }
  }
  return out;
}

export async function stripeRequest<T = any>(
  method: "GET" | "POST",
  path: string,
  params?: Record<string, unknown>,
  idempotencyKey?: string,
): Promise<T> {
  const key = requireEnv("STRIPE_SECRET_KEY");
  const qs = params && method === "GET" ? `?${stripeFormEncode(params)}` : "";
  const res = await fetch(`https://api.stripe.com/v1/${path}${qs}`, {
    method,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "Stripe-Version": "2024-06-20",
      ...(idempotencyKey ? { "Idempotency-Key": idempotencyKey } : {}),
    },
    body: method === "POST" && params ? stripeFormEncode(params) : undefined,
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`stripe_${res.status}:${body?.error?.message ?? "error"}`);
  return body as T;
}

export async function razorpayRequest<T = any>(method: "GET" | "POST", path: string, body?: unknown): Promise<T> {
  const auth = base64Encode(new TextEncoder().encode(`${requireEnv("RAZORPAY_KEY_ID")}:${requireEnv("RAZORPAY_KEY_SECRET")}`));
  const res = await fetch(`https://api.razorpay.com/v1/${path}`, {
    method,
    headers: { Authorization: `Basic ${auth}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`razorpay_${res.status}:${json?.error?.description ?? "error"}`);
  return json as T;
}

export const unixToIso = (s: number | null | undefined) => (s ? new Date(s * 1000).toISOString() : null);
