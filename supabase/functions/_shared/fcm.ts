// FCM HTTP v1 sender (service-account JWT -> OAuth token -> messages:send).
// Without FIREBASE_SERVICE_ACCOUNT it runs in dry-run mode (logs, reports "skipped").
import { env } from "./env.ts";
import { googleAccessToken, type ServiceAccount, serviceAccountFromEnv } from "./google.ts";

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

export interface PushMessage {
  token: string;
  title: string;
  body: string;
  /** String-only data map; `route` is the deep link the app opens. */
  data?: Record<string, string>;
  collapseKey?: string;
  badge?: number;
  /** Android channel id (app defines: leads, chat, quotes, orders, account). */
  channel?: string;
}

export type PushOutcome = "sent" | "invalid_token" | "failed" | "skipped";

export interface PushResult {
  token: string;
  outcome: PushOutcome;
  error?: string;
}

/** Builds the FCM v1 message body. Pure, unit tested. */
export function buildFcmMessage(m: PushMessage): Record<string, unknown> {
  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries(m.data ?? {})) if (v !== undefined && v !== null) data[k] = String(v);
  return {
    message: {
      token: m.token,
      notification: { title: m.title.slice(0, 120), body: m.body.slice(0, 400) },
      data,
      android: {
        priority: "HIGH",
        collapse_key: m.collapseKey,
        notification: { channel_id: m.channel ?? "default", tag: m.collapseKey },
      },
      apns: {
        headers: { "apns-priority": "10", ...(m.collapseKey ? { "apns-collapse-id": m.collapseKey.slice(0, 64) } : {}) },
        payload: { aps: { sound: "default", ...(m.badge !== undefined ? { badge: m.badge } : {}) } },
      },
    },
  };
}

/** FCM errors meaning "delete this token": UNREGISTERED (404) or an invalid registration token (400). */
export function isInvalidTokenError(status: number, body: string): boolean {
  if (status === 404) return true;
  if (status !== 400) return false;
  return /UNREGISTERED|registration token is not a valid|INVALID_ARGUMENT.*token/i.test(body);
}

let sa: ServiceAccount | null | undefined;

export function fcmConfigured(): boolean {
  if (sa === undefined) sa = serviceAccountFromEnv("FIREBASE_SERVICE_ACCOUNT");
  return !!sa;
}

export async function sendPush(m: PushMessage): Promise<PushResult> {
  if (!fcmConfigured()) {
    console.log("[fcm dry-run]", m.title, "->", m.token.slice(0, 12));
    return { token: m.token, outcome: "skipped", error: "fcm_not_configured" };
  }
  const projectId = env("FIREBASE_PROJECT_ID") ?? sa!.project_id;
  const access = await googleAccessToken(sa!, [SCOPE]);
  for (let attempt = 0; attempt < 3; attempt++) {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${access}`, "Content-Type": "application/json" },
      body: JSON.stringify(buildFcmMessage(m)),
    });
    if (res.ok) {
      await res.body?.cancel();
      return { token: m.token, outcome: "sent" };
    }
    const text = await res.text();
    if (isInvalidTokenError(res.status, text)) return { token: m.token, outcome: "invalid_token", error: text };
    if (res.status === 429 || res.status >= 500) {
      await new Promise((r) => setTimeout(r, 250 * 2 ** attempt));
      continue;
    }
    return { token: m.token, outcome: "failed", error: `${res.status}:${text.slice(0, 300)}` };
  }
  return { token: m.token, outcome: "failed", error: "retries_exhausted" };
}

/** Sends with bounded concurrency (FCM v1 has no multicast; ~20 parallel requests is safe). */
export async function sendPushBatch(messages: PushMessage[], concurrency = 20): Promise<PushResult[]> {
  const results: PushResult[] = new Array(messages.length);
  let next = 0;
  async function worker() {
    while (next < messages.length) {
      const i = next++;
      try {
        results[i] = await sendPush(messages[i]);
      } catch (e) {
        results[i] = { token: messages[i].token, outcome: "failed", error: String(e) };
      }
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, messages.length) }, worker));
  return results;
}
