import type { APIRoute } from 'astro';
import { PLACEHOLDER, site, warnOnce } from '../../lib/site';

// Android App Links verification (https://<domain>/.well-known/assetlinks.json).
// ANDROID_SHA256_FINGERPRINTS: comma-separated SHA-256 cert fingerprints, normally the
// Play App Signing key plus the upload key (Play Console > Setup > App signing).
export const GET: APIRoute = () => {
  let fingerprints = site.android.sha256.map((f) => f.toUpperCase());
  const bad = fingerprints.filter((f) => !/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/.test(f));
  if (bad.length) throw new Error(`ANDROID_SHA256_FINGERPRINTS has malformed values: ${bad.join(', ')}`);
  if (!fingerprints.length) {
    warnOnce('ANDROID_SHA256_FINGERPRINTS unset: assetlinks.json uses a placeholder, App Links will not verify.');
    fingerprints = [PLACEHOLDER.sha256];
  }
  const body = site.android.packages.map((pkg) => ({
    relation: ['delegate_permission/common.handle_all_urls'],
    target: { namespace: 'android_app', package_name: pkg, sha256_cert_fingerprints: fingerprints },
  }));
  return new Response(JSON.stringify(body, null, 2) + '\n', { headers: { 'Content-Type': 'application/json' } });
};
