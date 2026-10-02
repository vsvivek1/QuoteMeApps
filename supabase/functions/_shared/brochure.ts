// Brochure / signup link helper (Section 21.4): one tracked signup URL per
// city x category x language x campaign, and the matching brochure in Storage.
import type { SupabaseClient } from "@supabase/supabase-js";
import { env } from "./env.ts";

export interface SignupLinkInput {
  baseUrl?: string; // default SELLER_SIGNUP_URL, e.g. https://iwantindia.com/sell
  source: "email" | "whatsapp" | "brochure" | "qr" | "field" | "seo";
  campaign?: string | null;
  city?: string | null;
  category?: string | null;
  language?: string | null;
  signupToken?: string | null;
  step?: number | null;
}

export function slugify(s: string): string {
  return s.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function signupUrl(i: SignupLinkInput): string {
  const base = i.baseUrl ?? env("SELLER_SIGNUP_URL") ?? "https://example.com/sell";
  const u = new URL(base);
  u.searchParams.set("utm_source", i.source);
  u.searchParams.set("utm_medium", i.source === "email" ? "outreach_email" : i.source);
  if (i.campaign) u.searchParams.set("utm_campaign", slugify(i.campaign));
  const content = [i.city && slugify(i.city), i.category && slugify(i.category), i.step ? `s${i.step}` : null]
    .filter(Boolean).join("_");
  if (content) u.searchParams.set("utm_content", content);
  if (i.language) u.searchParams.set("lang", i.language);
  if (i.signupToken) u.searchParams.set("t", i.signupToken); // pre-fills the CRM lead + attribution
  return u.toString();
}

export interface BrochureRow {
  id: string;
  city_name: string;
  category_id: number | null;
  language: string;
  format: string;
  storage_path: string;
  public_url: string | null;
  signup_url: string | null;
  version: number;
}

/** Best brochure for a lead: exact city+category, then city-wide, then category-wide, then generic. */
export async function findBrochure(
  db: SupabaseClient,
  o: { city?: string | null; categoryIds?: number[]; language?: string; format?: string },
): Promise<(BrochureRow & { url: string }) | null> {
  const { data, error } = await db.from("brochures").select("*")
    .eq("format", o.format ?? "pdf").eq("language", o.language ?? "en")
    .order("version", { ascending: false }).limit(200);
  if (error || !data?.length) return null;
  const rows = data as BrochureRow[];
  const city = o.city?.toLowerCase();
  const cats = new Set(o.categoryIds ?? []);
  const generic = (n: string) => ["*", "all", "nationwide"].includes(n.toLowerCase());
  // city: exact match +2, generic 0, another city -10; category: match +1, generic 0, other -10
  const score = (b: BrochureRow) =>
    (generic(b.city_name) ? 0 : city && b.city_name.toLowerCase() === city ? 2 : -10) +
    (b.category_id == null ? 0 : cats.has(b.category_id) ? 1 : -10);
  const best = rows.sort((a, b) => score(b) - score(a))[0];
  if (score(best) < 0) return null;
  const url = best.public_url ?? db.storage.from("brochures").getPublicUrl(best.storage_path).data.publicUrl;
  return { ...best, url };
}
