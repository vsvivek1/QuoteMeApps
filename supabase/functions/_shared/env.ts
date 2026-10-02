// Environment helpers. Every secret is listed in supabase/.env.example.

export function env(name: string): string | undefined {
  const v = Deno.env.get(name);
  return v === undefined || v === "" ? undefined : v;
}

export function requireEnv(name: string): string {
  const v = env(name);
  if (!v) throw new Error(`missing_env:${name}`);
  return v;
}

export function envBool(name: string, fallback = false): boolean {
  const v = env(name);
  if (v === undefined) return fallback;
  return ["1", "true", "yes", "on"].includes(v.toLowerCase());
}

export function envInt(name: string, fallback: number): number {
  const v = env(name);
  const n = v === undefined ? NaN : Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/** "IN" or "US": from APP_COUNTRY, else derived from the project (set per project). */
export function appCountry(): "IN" | "US" {
  const v = (env("APP_COUNTRY") ?? "IN").toUpperCase();
  return v === "US" || v === "USA" ? "US" : "IN";
}
