// delete-account: in-app account deletion (Play + App Store requirement).
//  1. public.delete_my_account() as the caller (anonymises the profile, cancels
//     open requests, withdraws quotes, removes tokens; orders/reviews are kept
//     anonymised for the other party).
//  2. Soft-deletes the auth user (GoTrue keeps a tombstone; phone/email freed).
//  3. Revokes Sign in with Apple tokens when the user signed in with Apple.
//
// POST (user JWT) body: { apple_authorization_code?: string, apple_refresh_token?: string,
//                         apple_client_id?: string }  // bundle id that issued the code
// The app should re-authenticate with Apple on the confirm screen and send the
// fresh authorization code; Supabase does not keep Apple refresh tokens.
// Response: { deleted: true, apple_revoked: boolean | null, summary }
import { appleConfig, appleExchangeCode, appleRevoke } from "../_shared/apple.ts";
import { verifyAppCheck } from "../_shared/appcheck.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { enforceRateLimit } from "../_shared/ratelimit.ts";
import { adminClient, requireUser, unwrap, userClient } from "../_shared/supabase.ts";

serve(async (req) => {
  requireMethod(req, "POST");
  const app = await verifyAppCheck(req);
  if (!app.ok) throw new HttpError(401, "app_check_failed", app.reason);
  const { user } = await requireUser(req);
  await enforceRateLimit("delete-account", user.id, 3, 3600);
  const body = await readJson<{ apple_authorization_code?: string; apple_refresh_token?: string; apple_client_id?: string }>(
    req,
  );

  const summary = unwrap(await userClient(req).rpc("delete_my_account"));

  let appleRevoked: boolean | null = null;
  const usesApple = (user.identities ?? []).some((i) => i.provider === "apple") ||
    user.app_metadata?.provider === "apple";
  if (usesApple && (body.apple_authorization_code || body.apple_refresh_token)) {
    const cfg = appleConfig(body.apple_client_id);
    if (cfg) {
      try {
        const token = body.apple_refresh_token ?? await appleExchangeCode(cfg, body.apple_authorization_code!);
        appleRevoked = token ? await appleRevoke(cfg, token) : false;
      } catch (e) {
        console.warn("apple revoke error", e);
        appleRevoked = false;
      }
    } else {
      console.warn("apple revoke skipped: APPLE_* env not configured");
      appleRevoked = false;
    }
  }

  const { error } = await adminClient().auth.admin.deleteUser(user.id, true);
  if (error) {
    console.error("auth soft delete failed", error);
    throw new HttpError(500, "auth_delete_failed");
  }
  return json({ deleted: true, apple_revoked: appleRevoked, summary });
});
