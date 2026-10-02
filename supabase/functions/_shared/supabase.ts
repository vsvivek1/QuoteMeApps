// Supabase clients and caller authentication.
//
// - adminClient(): service_role client (bypasses RLS). Only for trusted work.
// - userClient(req): acts as the caller (RLS + RPC checks apply).
// - requireUser / requireAdmin: verify the caller's JWT with GoTrue.
// - requireWebhookSecret: pg_net / cron calls send x-webhook-secret = EDGE_WEBHOOK_SECRET
//   (the same value is stored in Vault as `edge_webhook_secret`).
import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { decodeJwtPayload, timingSafeEqual } from "./crypto.ts";
import { env, requireEnv } from "./env.ts";
import { fromPostgrestError, HttpError } from "./http.ts";

let _admin: SupabaseClient | undefined;

export function adminClient(): SupabaseClient {
  if (!_admin) {
    _admin = createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_SERVICE_ROLE_KEY"), {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { headers: { "x-client-info": "iwant-edge" } },
    });
  }
  return _admin;
}

export function bearer(req: Request): string | undefined {
  const h = req.headers.get("Authorization") ?? "";
  const m = /^Bearer\s+(.+)$/i.exec(h);
  return m?.[1];
}

export function userClient(req: Request): SupabaseClient {
  const token = bearer(req);
  if (!token) throw new HttpError(401, "not_authenticated");
  return clientForToken(token);
}

/** Client acting as the holder of `token` (an access token from GoTrue). */
export function clientForToken(token: string): SupabaseClient {
  return createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
}

/** Anonymous client (anon key, no session) e.g. for GoTrue OTP send / verify. */
export function anonClient(): SupabaseClient {
  return createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  });
}

export async function requireUser(req: Request): Promise<{ user: User; token: string; claims: Record<string, unknown> }> {
  const token = bearer(req);
  if (!token) throw new HttpError(401, "not_authenticated");
  const { data, error } = await adminClient().auth.getUser(token);
  if (error || !data?.user) throw new HttpError(401, "invalid_token");
  return { user: data.user, token, claims: decodeJwtPayload(token) };
}

/** Admin = `admin` in the token's roles claim AND in profiles.roles (same rule as private.require_admin()). */
export async function requireAdmin(req: Request) {
  const ctx = await requireUser(req);
  const claimRoles = Array.isArray(ctx.claims.roles) ? (ctx.claims.roles as string[]) : [];
  if (!claimRoles.includes("admin")) throw new HttpError(403, "admin_only");
  const { data, error } = await adminClient().from("profiles").select("roles,status").eq("id", ctx.user.id)
    .maybeSingle();
  if (error) throw fromPostgrestError(error);
  if (!data || data.status !== "active" || !(data.roles as string[]).includes("admin")) {
    throw new HttpError(403, "admin_only");
  }
  return ctx;
}

export function hasValidWebhookSecret(req: Request, url?: URL): boolean {
  const expected = env("EDGE_WEBHOOK_SECRET");
  if (!expected) return false;
  const got = req.headers.get("x-webhook-secret") ?? url?.searchParams.get("secret") ?? "";
  return timingSafeEqual(got, expected);
}

export function requireWebhookSecret(req: Request, url?: URL) {
  if (!hasValidWebhookSecret(req, url)) throw new HttpError(401, "invalid_webhook_secret");
}

/** Internal callers: webhook secret, or the service_role key as bearer (e.g. manual invoke). */
export function isServiceCaller(req: Request): boolean {
  if (hasValidWebhookSecret(req)) return true;
  const token = bearer(req);
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  return !!token && !!key && timingSafeEqual(token, key);
}

/** Unwraps a supabase-js result, converting RPC errors into HttpErrors. */
// deno-lint-ignore no-explicit-any
export function unwrap<T = any>(res: { data: unknown; error: any }): T {
  if (res.error) throw fromPostgrestError(res.error);
  return res.data as T;
}
