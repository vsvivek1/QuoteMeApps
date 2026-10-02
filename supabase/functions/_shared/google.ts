// Google service-account OAuth (JWT bearer grant) for FCM HTTP v1 and the
// Play Developer API. FIREBASE_SERVICE_ACCOUNT / PLAY_SERVICE_ACCOUNT hold the
// service-account JSON (raw or base64).
import { base64Decode } from "./crypto.ts";
import { signRs256Jwt } from "./crypto.ts";
import { env } from "./env.ts";

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  private_key_id?: string;
  token_uri?: string;
}

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  const text = raw.trim().startsWith("{") ? raw : new TextDecoder().decode(base64Decode(raw.trim()));
  const sa = JSON.parse(text) as ServiceAccount;
  if (!sa.client_email || !sa.private_key || !sa.project_id) throw new Error("invalid_service_account");
  return sa;
}

export function serviceAccountFromEnv(name: string): ServiceAccount | null {
  return parseServiceAccount(env(name));
}

const cache = new Map<string, { token: string; exp: number }>();

export async function googleAccessToken(sa: ServiceAccount, scopes: string[]): Promise<string> {
  const key = `${sa.client_email}|${scopes.join(" ")}`;
  const now = Math.floor(Date.now() / 1000);
  const hit = cache.get(key);
  if (hit && hit.exp - 60 > now) return hit.token;
  const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
  const assertion = await signRs256Jwt(sa.private_key, sa.private_key_id ? { kid: sa.private_key_id } : {}, {
    iss: sa.client_email,
    scope: scopes.join(" "),
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  });
  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!res.ok) throw new Error(`google_oauth_failed:${res.status}:${await res.text()}`);
  const body = await res.json() as { access_token: string; expires_in: number };
  cache.set(key, { token: body.access_token, exp: now + body.expires_in });
  return body.access_token;
}
