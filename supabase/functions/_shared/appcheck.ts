// Firebase App Check for the mobile apps (Section 20.5).
//
// Stub-level by design: enforcement is OFF unless APP_CHECK_ENFORCE=true.
// When enforced, the X-Firebase-AppCheck token is verified against Firebase's
// JWKS (RS256, issuer https://firebaseappcheck.googleapis.com/<project number>,
// audience projects/<project number>). Web/admin callers use Turnstile instead.
// TODO(launch): turn on APP_CHECK_ENFORCE per project once both apps ship the
// App Check provider (Play Integrity / App Attest) and monitor rejections first.
import { createRemoteJWKSet, jwtVerify } from "jose";
import { env, envBool } from "./env.ts";
import { HttpError } from "./http.ts";

const JWKS_URL = "https://firebaseappcheck.googleapis.com/v1/jwks";
let jwks: ReturnType<typeof createRemoteJWKSet> | undefined;

export interface AppCheckResult {
  ok: boolean;
  enforced: boolean;
  appId?: string;
  reason?: string;
}

export async function verifyAppCheck(req: Request): Promise<AppCheckResult> {
  const enforced = envBool("APP_CHECK_ENFORCE", false);
  const token = req.headers.get("X-Firebase-AppCheck");
  const projectNumber = env("FIREBASE_PROJECT_NUMBER");
  if (!token || !projectNumber) {
    return { ok: !enforced, enforced, reason: token ? "app_check_not_configured" : "missing_app_check_token" };
  }
  try {
    jwks ??= createRemoteJWKSet(new URL(JWKS_URL));
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
      audience: `projects/${projectNumber}`,
      algorithms: ["RS256"],
    });
    return { ok: true, enforced, appId: String(payload.sub ?? "") };
  } catch (e) {
    return { ok: !enforced, enforced, reason: `invalid_app_check_token:${(e as Error).message}` };
  }
}

export async function requireAppCheck(req: Request) {
  const res = await verifyAppCheck(req);
  if (!res.ok) throw new HttpError(401, "app_check_failed", res.reason);
  return res;
}
