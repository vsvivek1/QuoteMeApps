// Upstash Redis sliding-window rate limiting for Edge Functions.
// No-op (always allowed) when UPSTASH_REDIS_REST_URL / _TOKEN are not set,
// so local development and tests need no Redis. Database-level limits
// (private.rate_limit_hit) still protect the RPCs either way.
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";
import { env } from "./env.ts";
import { HttpError } from "./http.ts";
import { adminClient } from "./supabase.ts";

export interface RateLimitResult {
  success: boolean;
  limit: number;
  remaining: number;
  reset: number;
  enforced: boolean;
}

const limiters = new Map<string, Ratelimit>();
let redis: Redis | null | undefined;

function getRedis(): Redis | null {
  if (redis === undefined) {
    const url = env("UPSTASH_REDIS_REST_URL");
    const token = env("UPSTASH_REDIS_REST_TOKEN");
    redis = url && token ? new Redis({ url, token }) : null;
  }
  return redis;
}

/**
 * Stable key: `iwant:<country>:<scope>:<identifier>`. Identifiers are
 * lower-cased and trimmed; IPs keep only the first X-Forwarded-For hop.
 */
export function rateLimitKey(scope: string, identifier: string, country = env("APP_COUNTRY") ?? "xx"): string {
  const id = identifier.split(",")[0].trim().toLowerCase() || "anonymous";
  const sc = scope.trim().toLowerCase().replace(/[^a-z0-9_-]/g, "_");
  return `iwant:${country.toLowerCase()}:${sc}:${id}`;
}

export function clientIp(req: Request): string {
  return req.headers.get("x-forwarded-for") ?? req.headers.get("cf-connecting-ip") ?? "unknown";
}

export async function rateLimit(
  scope: string,
  identifier: string,
  limit: number,
  windowSeconds: number,
): Promise<RateLimitResult> {
  const r = getRedis();
  if (!r) return { success: true, limit, remaining: limit, reset: 0, enforced: false };
  const cacheKey = `${scope}:${limit}:${windowSeconds}`;
  let rl = limiters.get(cacheKey);
  if (!rl) {
    rl = new Ratelimit({
      redis: r,
      limiter: Ratelimit.slidingWindow(limit, `${windowSeconds} s`),
      prefix: "rl",
      analytics: false,
    });
    limiters.set(cacheKey, rl);
  }
  try {
    const res = await rl.limit(rateLimitKey(scope, identifier));
    return { success: res.success, limit: res.limit, remaining: res.remaining, reset: res.reset, enforced: true };
  } catch (e) {
    // Fail open: Redis trouble must not take the API down (DB limits still apply).
    console.warn("ratelimit unavailable", e);
    return { success: true, limit, remaining: limit, reset: 0, enforced: false };
  }
}

export async function enforceRateLimit(scope: string, identifier: string, limit: number, windowSeconds: number) {
  const res = await rateLimit(scope, identifier, limit, windowSeconds);
  if (!res.success) {
    throw new HttpError(429, "rate_limited", { retry_after_ms: Math.max(res.reset - Date.now(), 0) });
  }
  return res;
}

/**
 * Upstash sliding window when configured, otherwise the Postgres fixed-window
 * fallback (public.edge_rate_limit_hit, service role). Returns Retry-After seconds.
 */
export async function rateLimitWithFallback(
  scope: string,
  identifier: string,
  limit: number,
  windowSeconds: number,
): Promise<{ success: boolean; retryAfterSeconds: number; backend: "upstash" | "postgres" | "none" }> {
  const up = await rateLimit(scope, identifier, limit, windowSeconds);
  if (up.enforced) {
    return {
      success: up.success,
      retryAfterSeconds: Math.max(1, Math.ceil((up.reset - Date.now()) / 1000)),
      backend: "upstash",
    };
  }
  try {
    const { data, error } = await adminClient().rpc("edge_rate_limit_hit", {
      p_key: rateLimitKey(scope, identifier),
      p_limit: limit,
      p_window_seconds: windowSeconds,
    });
    if (error) throw error;
    const r = data as { allowed: boolean; retry_after_seconds: number };
    return { success: r.allowed, retryAfterSeconds: Math.max(1, r.retry_after_seconds), backend: "postgres" };
  } catch (e) {
    console.warn("postgres rate limit unavailable", e);
    return { success: true, retryAfterSeconds: 0, backend: "none" };
  }
}
