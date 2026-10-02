// brochure-link: admin helper for the brochure generator, WhatsApp click-to-chat
// and field kit (Section 21.3 / 21.4). Returns the tracked signup URL and the
// best stored brochure for a city x category x language.
//
// POST (admin JWT) { city?, category_id?, category_slug?, language?: "en"|"hi"|"es",
//                    format?: "pdf"|"image"|"onepager" (default pdf; "png" is accepted as an alias of "image"),
//                    source?: "brochure"|"qr"|"whatsapp"|"field"|"email", campaign?, lead_id? }
// -> { signup_url, brochure: { url, version, storage_path, format } | null }
// With lead_id, the lead's signup token is added so a sign-up links back to the CRM lead.
import { findBrochure, normalizeBrochureFormat, signupUrl } from "../_shared/brochure.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import { adminClient, requireAdmin, unwrap } from "../_shared/supabase.ts";

serve(async (req) => {
  requireMethod(req, "POST");
  await requireAdmin(req);
  const b = await readJson<{
    city?: string;
    category_id?: number;
    category_slug?: string;
    language?: string;
    format?: string;
    source?: "brochure" | "qr" | "whatsapp" | "field" | "email";
    campaign?: string;
    lead_id?: string;
  }>(req);
  const format = normalizeBrochureFormat(b.format);
  if (!format) throw new HttpError(400, "invalid_format", { allowed: ["pdf", "image", "onepager"] });
  const db = adminClient();

  let categoryId = b.category_id ?? null, categorySlug = b.category_slug ?? null;
  if (!categoryId && categorySlug) {
    categoryId = (unwrap(await db.from("categories").select("id").eq("slug", categorySlug).maybeSingle()) as any)?.id ?? null;
  } else if (categoryId && !categorySlug) {
    categorySlug = (unwrap(await db.from("categories").select("slug").eq("id", categoryId).maybeSingle()) as any)?.slug ?? null;
  }
  let token: string | null = null, city = b.city ?? null;
  if (b.lead_id) {
    const lead = unwrap(await db.from("outreach_leads").select("signup_token,city").eq("id", b.lead_id).maybeSingle()) as any;
    if (!lead) throw new HttpError(404, "lead_not_found");
    token = lead.signup_token;
    city ??= lead.city;
  }

  const url = signupUrl({
    source: b.source ?? "brochure",
    campaign: b.campaign ?? null,
    city,
    category: categorySlug,
    language: b.language ?? "en",
    signupToken: token,
  });
  const brochure = await findBrochure(db, {
    city,
    categoryIds: categoryId ? [categoryId] : [],
    language: b.language ?? "en",
    format,
  });
  return json({
    signup_url: url,
    brochure: brochure
      ? { url: brochure.url, version: brochure.version, storage_path: brochure.storage_path, format: brochure.format }
      : null,
  });
});
