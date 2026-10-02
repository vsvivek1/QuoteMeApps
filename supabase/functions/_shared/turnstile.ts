// Cloudflare Turnstile server-side verification (Section 20.5).
import { env } from "./env.ts";

export interface TurnstileResult {
  success: boolean;
  "error-codes"?: string[];
  hostname?: string;
  action?: string;
  challenge_ts?: string;
}

/** Pure check of a siteverify response: success, optional expected action and hostname allow-list. */
export function checkTurnstileResult(
  r: TurnstileResult,
  opts: { action?: string; hostnames?: string[]; maxAgeSeconds?: number; now?: Date } = {},
): { ok: boolean; reason?: string } {
  if (!r.success) return { ok: false, reason: (r["error-codes"] ?? ["failed"]).join(",") };
  if (opts.action && r.action && r.action !== opts.action) return { ok: false, reason: "action_mismatch" };
  if (opts.hostnames?.length && r.hostname && !opts.hostnames.includes(r.hostname)) {
    return { ok: false, reason: "hostname_mismatch" };
  }
  if (opts.maxAgeSeconds && r.challenge_ts) {
    const age = ((opts.now ?? new Date()).getTime() - new Date(r.challenge_ts).getTime()) / 1000;
    if (age > opts.maxAgeSeconds) return { ok: false, reason: "token_too_old" };
  }
  return { ok: true };
}

export async function verifyTurnstile(
  token: string,
  ip: string | null,
  opts: { action?: string; hostnames?: string[] } = {},
): Promise<{ ok: boolean; reason?: string }> {
  const secret = env("TURNSTILE_SECRET_KEY");
  if (!secret) return { ok: false, reason: "turnstile_not_configured" };
  if (!token || token.length > 2048) return { ok: false, reason: "missing_token" };
  const form = new URLSearchParams({ secret, response: token, idempotency_key: crypto.randomUUID() });
  if (ip) form.set("remoteip", ip);
  try {
    const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", { method: "POST", body: form });
    if (!res.ok) return { ok: false, reason: `siteverify_${res.status}` };
    return checkTurnstileResult(await res.json() as TurnstileResult, { ...opts, maxAgeSeconds: 300 });
  } catch (e) {
    return { ok: false, reason: `siteverify_error:${(e as Error).message}` };
  }
}
