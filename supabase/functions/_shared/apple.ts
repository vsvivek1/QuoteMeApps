// Sign in with Apple token revocation (App Store Guideline 5.1.1(v): account
// deletion must revoke Apple tokens). Client secret = ES256 JWT signed with the
// Sign in with Apple key (.p8): iss = team id, sub = client id (bundle id for
// native sign-in), aud = https://appleid.apple.com, max 6 months.
import { signEs256Jwt } from "./crypto.ts";
import { env } from "./env.ts";

export interface AppleConfig {
  teamId: string;
  keyId: string;
  privateKey: string;
  clientId: string;
}

export function appleConfig(clientId?: string): AppleConfig | null {
  const teamId = env("APPLE_TEAM_ID"), keyId = env("APPLE_SIGNIN_KEY_ID"), privateKey = env("APPLE_SIGNIN_PRIVATE_KEY");
  const cid = clientId ?? env("APPLE_SIGNIN_CLIENT_ID");
  if (!teamId || !keyId || !privateKey || !cid) return null;
  return { teamId, keyId, privateKey, clientId: cid };
}

export function appleClientSecretClaims(cfg: AppleConfig, nowSeconds = Math.floor(Date.now() / 1000)) {
  return { iss: cfg.teamId, iat: nowSeconds, exp: nowSeconds + 300, aud: "https://appleid.apple.com", sub: cfg.clientId };
}

export function appleClientSecret(cfg: AppleConfig, nowSeconds?: number): Promise<string> {
  return signEs256Jwt(cfg.privateKey, { kid: cfg.keyId }, appleClientSecretClaims(cfg, nowSeconds));
}

/** Exchanges a fresh authorization code (from a re-auth on the delete screen) for a refresh token. */
export async function appleExchangeCode(cfg: AppleConfig, code: string): Promise<string | null> {
  const res = await fetch("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: cfg.clientId,
      client_secret: await appleClientSecret(cfg),
      code,
      grant_type: "authorization_code",
    }),
  });
  if (!res.ok) {
    console.warn("apple token exchange failed", res.status, await res.text());
    return null;
  }
  const body = await res.json() as { refresh_token?: string; access_token?: string };
  return body.refresh_token ?? body.access_token ?? null;
}

export async function appleRevoke(
  cfg: AppleConfig,
  token: string,
  hint: "refresh_token" | "access_token" = "refresh_token",
): Promise<boolean> {
  const res = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: cfg.clientId,
      client_secret: await appleClientSecret(cfg),
      token,
      token_type_hint: hint,
    }),
  });
  if (!res.ok) console.warn("apple revoke failed", res.status, await res.text());
  return res.ok;
}
