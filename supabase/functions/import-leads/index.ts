// import-leads: seller lead import per city x category (Section 21.1).
// Sources: OpenStreetMap Overpass (default, free) and Google Places API (New)
// Text Search under a hard monthly budget (places_monthly_budget_usd /
// places_cost_per_request_usd in app_settings; spend tracked in
// app_settings.places_spend = {"month":"YYYY-MM","requests":n}).
// Leads go to outreach_leads at stage "sourced" via outreach_upsert_lead
// (dedupe by business key / phone / domain / place / osm id; suppression wins).
// Never creates public seller profiles.
//
// Callers: admin JWT (panel button) or x-webhook-secret (pg_cron).
// POST {
//   source: "osm" | "places",
//   city: { name, state?, city_id?, lat, lng, timezone?, priority? }   // or city_id only (looked up in cities)
//   radius_m?: 15000, category_slugs?: string[], max_results?: 200, dry_run?: false
// }
import { appCountry, env } from "../_shared/env.ts";
import { HttpError, json, readJson, requireMethod, serve } from "../_shared/http.ts";
import {
  buildOverpassQuery,
  type CityTarget,
  type LeadInput,
  OSM_TAG_CATEGORIES,
  osmElementToLead,
  PLACES_FIELD_MASK,
  placesBudgetAllows,
  placeToLead,
} from "../_shared/leads.ts";
import { enforceRateLimit } from "../_shared/ratelimit.ts";
import { adminClient, isServiceCaller, requireAdmin, unwrap } from "../_shared/supabase.ts";

const OVERPASS_URL = env("OVERPASS_URL") ?? "https://overpass-api.de/api/interpreter";
const USER_AGENT = env("LEAD_IMPORT_USER_AGENT") ?? "IWantLeadImport/1.0 (+contact: admin@example.com)";

interface Body {
  source?: "osm" | "places";
  city?: Partial<CityTarget> & { city_id?: number };
  radius_m?: number;
  category_slugs?: string[];
  max_results?: number;
  dry_run?: boolean;
}

serve(async (req) => {
  requireMethod(req, "POST");
  let caller = "service";
  if (!isServiceCaller(req)) caller = (await requireAdmin(req)).user.id;
  await enforceRateLimit("import-leads", caller, 30, 3600);
  const body = await readJson<Body>(req);
  const db = adminClient();
  const country = appCountry();

  const city = await resolveCity(body.city);
  const radius = Math.min(Math.max(body.radius_m ?? 15000, 1000), 50000);
  const maxResults = Math.min(body.max_results ?? 200, 1000);

  const cats = unwrap(await db.from("categories").select("id,slug,names,policy,parent_id").eq("active", true)) as {
    id: number;
    slug: string;
    names: Record<string, string>;
    policy: string;
  }[];
  // Blocked categories are never targeted.
  const slugToId = new Map(cats.filter((c) => c.policy !== "blocked").map((c) => [c.slug, c.id]));
  const wanted = body.category_slugs?.length ? new Set(body.category_slugs) : null;

  let leads: LeadInput[] = [];
  let requestsUsed = 0;
  if ((body.source ?? "osm") === "osm") {
    const tags = Object.entries(OSM_TAG_CATEGORIES)
      .filter(([, slugs]) => slugs.some((s) => slugToId.has(s) && (!wanted || wanted.has(s))))
      .map(([t]) => t);
    if (!tags.length) throw new HttpError(400, "no_matching_categories");
    const res = await fetch(OVERPASS_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", "User-Agent": USER_AGENT },
      body: new URLSearchParams({ data: buildOverpassQuery(city, radius, tags, maxResults) }),
    });
    if (!res.ok) throw new HttpError(502, "overpass_failed", res.status);
    const data = await res.json() as { elements: any[] };
    const filtered = wanted ? new Map([...slugToId].filter(([s]) => wanted.has(s))) : slugToId;
    leads = data.elements.map((el) => osmElementToLead(el, city, country, filtered)).filter((x): x is LeadInput => !!x);
  } else {
    const key = env("GOOGLE_PLACES_API_KEY");
    if (!key) throw new HttpError(503, "places_not_configured");
    const targets = cats.filter((c) => slugToId.has(c.slug) && (!wanted || wanted.has(c.slug)));
    if (!targets.length) throw new HttpError(400, "no_matching_categories");
    const budget = await placesBudget();
    for (const cat of targets) {
      if (leads.length >= maxResults) break;
      if (!placesBudgetAllows(budget.requests + requestsUsed, 1, budget.costPerRequest, budget.budgetUsd)) {
        break; // hard cap: stop, never overspend
      }
      const query = `${cat.names.en ?? cat.slug} in ${city.name}${city.state ? `, ${city.state}` : ""}`;
      const res = await fetch("https://places.googleapis.com/v1/places:searchText", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": key, "X-Goog-FieldMask": PLACES_FIELD_MASK },
        body: JSON.stringify({
          textQuery: query,
          pageSize: 20,
          locationBias: { circle: { center: { latitude: city.lat, longitude: city.lng }, radius } },
          regionCode: country,
        }),
      });
      requestsUsed++;
      if (!res.ok) {
        console.warn("places failed", res.status, await res.text());
        continue;
      }
      const data = await res.json() as { places?: any[] };
      for (const p of data.places ?? []) {
        const l = placeToLead(p, city, country, [cat.id], query);
        if (l) leads.push(l);
      }
    }
    if (requestsUsed && !body.dry_run) await recordPlacesSpend(budget.month, budget.requests + requestsUsed);
  }

  leads = leads.slice(0, maxResults);
  if (body.dry_run) return json({ source: body.source ?? "osm", city: city.name, found: leads.length, sample: leads.slice(0, 10), places_requests: requestsUsed });

  let inserted = 0, duplicates = 0;
  for (const l of leads) {
    const id = unwrap(await db.rpc("outreach_upsert_lead", { p_lead: l }));
    if (id) inserted++;
    else duplicates++;
  }
  return json({ source: body.source ?? "osm", city: city.name, found: leads.length, upserted: inserted, duplicates, places_requests: requestsUsed });
});

async function resolveCity(c: Body["city"]): Promise<CityTarget> {
  if (!c) throw new HttpError(400, "city_required");
  let base: Partial<CityTarget> = { ...c };
  if (c.city_id && (typeof c.lat !== "number" || typeof c.lng !== "number")) {
    const row = unwrap(
      await adminClient().from("cities").select("id,name,state,timezone,priority,centroid").eq("id", c.city_id).maybeSingle(),
    ) as any;
    if (!row) throw new HttpError(404, "city_not_found");
    // PostgREST returns geography as GeoJSON ({ type: "Point", coordinates: [lng, lat] }).
    const coords = row.centroid?.coordinates;
    if (!Array.isArray(coords)) throw new HttpError(400, "city_lat_lng_required", { name: row.name });
    base = { name: row.name, state: row.state, city_id: row.id, timezone: row.timezone, priority: row.priority, lng: coords[0], lat: coords[1], ...c };
  }
  if (!base.name || typeof base.lat !== "number" || typeof base.lng !== "number") {
    throw new HttpError(400, "city_name_lat_lng_required");
  }
  return {
    name: base.name,
    state: base.state ?? null,
    city_id: base.city_id ?? null,
    lat: base.lat,
    lng: base.lng,
    timezone: base.timezone ?? null,
    priority: base.priority ?? null,
  };
}

async function placesBudget() {
  const db = adminClient();
  const rows = unwrap(
    await db.from("app_settings").select("key,value").in("key", ["places_monthly_budget_usd", "places_cost_per_request_usd", "places_spend"]),
  ) as { key: string; value: any }[];
  const get = (k: string) => rows.find((r) => r.key === k)?.value;
  const month = new Date().toISOString().slice(0, 7);
  const spend = get("places_spend");
  return {
    month,
    requests: spend?.month === month ? Number(spend.requests ?? 0) : 0,
    budgetUsd: Number(get("places_monthly_budget_usd") ?? 0),
    costPerRequest: Number(get("places_cost_per_request_usd") ?? 0.032),
  };
}

async function recordPlacesSpend(month: string, requests: number) {
  await adminClient().from("app_settings").upsert({
    key: "places_spend",
    value: { month, requests },
    description: "Google Places requests this month (import-leads budget cap)",
    is_public: false,
  });
}
