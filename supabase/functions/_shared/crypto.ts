// Small WebCrypto helpers shared by signature checks and JWT signing.

const enc = new TextEncoder();

/** TS 5.7+ distinguishes Uint8Array<ArrayBufferLike>; WebCrypto wants BufferSource. */
const bs = (b: Uint8Array): BufferSource => b as unknown as BufferSource;

export function toHex(buf: ArrayBuffer | Uint8Array): string {
  const b = buf instanceof Uint8Array ? buf : new Uint8Array(buf);
  return Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
}

export function base64Encode(buf: ArrayBuffer | Uint8Array): string {
  const b = buf instanceof Uint8Array ? buf : new Uint8Array(buf);
  let s = "";
  for (let i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return btoa(s);
}

export function base64Decode(s: string): Uint8Array {
  const bin = atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "="));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export function base64UrlEncode(buf: ArrayBuffer | Uint8Array | string): string {
  const b = typeof buf === "string" ? enc.encode(buf) : buf;
  return base64Encode(b).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function hmacSha256(key: string | Uint8Array, data: string | Uint8Array): Promise<Uint8Array> {
  const k = await crypto.subtle.importKey(
    "raw",
    bs(typeof key === "string" ? enc.encode(key) : key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return new Uint8Array(await crypto.subtle.sign("HMAC", k, bs(typeof data === "string" ? enc.encode(data) : data)));
}

export async function hmacSha256Hex(key: string | Uint8Array, data: string | Uint8Array): Promise<string> {
  return toHex(await hmacSha256(key, data));
}

export async function sha256Hex(data: string | Uint8Array): Promise<string> {
  return toHex(await crypto.subtle.digest("SHA-256", bs(typeof data === "string" ? enc.encode(data) : data)));
}

/** Constant-time string comparison (length leak only). */
export function timingSafeEqual(a: string, b: string): boolean {
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) diff |= ab[i] ^ bb[i];
  return diff === 0;
}

/** PEM (PKCS#8) -> DER bytes. Accepts literal "\n" sequences from env vars. */
export function pemToDer(pem: string): Uint8Array {
  const body = pem.replace(/\\n/g, "\n").replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return base64Decode(body);
}

async function signJwt(
  alg: "RS256" | "ES256",
  privateKeyPem: string,
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
): Promise<string> {
  const der = pemToDer(privateKeyPem);
  const key = alg === "RS256"
    ? await crypto.subtle.importKey("pkcs8", bs(der), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"])
    : await crypto.subtle.importKey("pkcs8", bs(der), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const input = `${base64UrlEncode(JSON.stringify({ alg, typ: "JWT", ...header }))}.${
    base64UrlEncode(JSON.stringify(payload))
  }`;
  const sig = alg === "RS256"
    ? await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(input))
    : await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, enc.encode(input)); // raw r||s, as JWS wants
  return `${input}.${base64UrlEncode(sig)}`;
}

export const signRs256Jwt = (pem: string, header: Record<string, unknown>, payload: Record<string, unknown>) =>
  signJwt("RS256", pem, header, payload);
export const signEs256Jwt = (pem: string, header: Record<string, unknown>, payload: Record<string, unknown>) =>
  signJwt("ES256", pem, header, payload);

/** Decodes a JWT payload WITHOUT verifying it (only for tokens already verified by the gateway). */
export function decodeJwtPayload(token: string): Record<string, unknown> {
  const part = token.split(".")[1];
  if (!part) throw new Error("invalid_jwt");
  return JSON.parse(new TextDecoder().decode(base64Decode(part)));
}

/** Hex token from the CSPRNG (bytes * 2 characters). */
export function randomToken(bytes = 32): string {
  return toHex(crypto.getRandomValues(new Uint8Array(bytes)));
}
