// Seller lead import helpers (Section 21.1): OpenStreetMap Overpass and the
// Google Places API (New) Text Search. Only business data, never consumers;
// emails only when published by the business itself. Pure + unit tested.

/** OSM tag -> category slugs (both countries; missing slugs are ignored per country). */
export const OSM_TAG_CATEGORIES: Record<string, string[]> = {
  "shop=appliance": ["refrigerators", "washing-machines", "washers-dryers", "air-conditioners", "microwaves", "dishwashers", "water-heaters", "water-purifiers"],
  "shop=electronics": ["televisions", "cameras", "accessories", "inverters"],
  "shop=mobile_phone": ["phones", "accessories"],
  "shop=computer": ["laptops", "accessories"],
  "shop=furniture": ["sofas", "beds"],
  "shop=bed": ["beds", "mattresses"],
  "shop=kitchen": ["modular-kitchens", "kitchen-remodel"],
  "shop=interior_decoration": ["interiors", "interior-design"],
  "shop=car": ["new-cars"],
  "shop=motorcycle": ["new-bikes"],
  "shop=car_repair": ["vehicle-servicing"],
  "shop=tyres": ["tyres", "tires"],
  "shop=stationery": ["office-supplies", "printing"],
  "shop=copyshop": ["printing"],
  "shop=party": ["decoration"],
  "shop=chemist": ["medicines"],
  "amenity=pharmacy": ["medicines"],
  "craft=electrician": ["electrical", "appliance-repair"],
  "craft=plumber": ["plumbing"],
  "craft=carpenter": ["carpentry", "handyman"],
  "craft=painter": ["painting"],
  "craft=hvac": ["ac-repair", "hvac"],
  "craft=roofer": ["roofing"],
  "craft=caterer": ["catering"],
  "craft=photographer": ["photography"],
  "craft=printer": ["printing"],
  "craft=tailor": ["uniforms"],
  "office=moving_company": ["packers-movers", "moving"],
  "shop=pest_control": ["pest-control"],
  "office=pest_control": ["pest-control"],
  "shop=dry_cleaning": ["cleaning"],
  "amenity=events_venue": ["venues"],
};

export interface CityTarget {
  name: string;
  state?: string | null;
  city_id?: number | null;
  lat: number;
  lng: number;
  timezone?: string | null;
  priority?: number | null;
}

export function buildOverpassQuery(city: CityTarget, radiusM: number, tags: string[], limit = 500): string {
  const parts = tags.map((t) => {
    const [k, v] = t.split("=");
    return `  nwr["${k}"="${v}"](around:${Math.round(radiusM)},${city.lat},${city.lng});`;
  });
  return `[out:json][timeout:60];\n(\n${parts.join("\n")}\n);\nout center tags ${limit};`;
}

export function normalizeDomain(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    const u = new URL(/^https?:\/\//i.test(url) ? url : `https://${url}`);
    return u.hostname.toLowerCase().replace(/^www\./, "") || null;
  } catch {
    return null;
  }
}

export function normalizePhone(phone: string | null | undefined, country: "IN" | "US"): string | null {
  if (!phone) return null;
  const first = phone.split(/[;,/]/)[0];
  let d = first.replace(/[^\d+]/g, "");
  if (!d) return null;
  if (d.startsWith("+")) return d;
  d = d.replace(/^0+/, "");
  if (country === "IN" && d.length === 10) return `+91${d}`;
  if (country === "US" && d.length === 10) return `+1${d}`;
  if (country === "US" && d.length === 11 && d.startsWith("1")) return `+${d}`;
  if (country === "IN" && d.length === 12 && d.startsWith("91")) return `+${d}`;
  return null;
}

const SOCIAL = /(facebook|instagram|twitter|x|linkedin|youtube|wa|whatsapp|justdial|indiamart|yelp|google)\.(com|me|in)$/;

/** One business = one key: website domain, else phone, else the source id. */
export function businessKey(o: { website?: string | null; phone?: string | null; placeId?: string | null; osmId?: string | null }): string {
  const domain = normalizeDomain(o.website);
  if (domain && !SOCIAL.test(domain)) return `domain:${domain}`;
  if (o.phone) return `phone:${o.phone}`;
  if (o.placeId) return `place:${o.placeId}`;
  return `osm:${o.osmId}`;
}

export interface OsmElement {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

export interface LeadInput {
  business_key: string;
  business_name: string;
  categories_source: string[];
  matched_category_ids: number[];
  email?: string | null;
  address_source?: string | null;
  phone?: string | null;
  website?: string | null;
  website_domain?: string | null;
  place_id?: string | null;
  osm_id?: string | null;
  address?: string | null;
  city?: string | null;
  city_id?: number | null;
  state?: string | null;
  postal_code?: string | null;
  lat?: number;
  lng?: number;
  timezone?: string | null;
  rating?: number | null;
  rating_count?: number | null;
  source: "osm" | "places";
  source_ref?: string | null;
  lawful_basis: "legitimate_interest";
  chosen_reason: string;
  priority?: number | null;
}

export function osmElementToLead(
  el: OsmElement,
  city: CityTarget,
  country: "IN" | "US",
  slugToId: Map<string, number>,
): LeadInput | null {
  const t = el.tags ?? {};
  const name = t.name ?? t["name:en"];
  if (!name) return null;
  const matchedTags = Object.keys(OSM_TAG_CATEGORIES).filter((k) => {
    const [key, val] = k.split("=");
    return t[key] === val;
  });
  const ids = [...new Set(matchedTags.flatMap((k) => OSM_TAG_CATEGORIES[k]).map((s) => slugToId.get(s))
    .filter((x): x is number => typeof x === "number"))];
  if (!ids.length) return null; // rule 1: relevance only
  const website = t.website ?? t["contact:website"] ?? null;
  const phone = normalizePhone(t.phone ?? t["contact:phone"], country);
  const email = (t.email ?? t["contact:email"] ?? "").trim().toLowerCase() || null;
  const osmId = `${el.type}/${el.id}`;
  const lat = el.lat ?? el.center?.lat, lng = el.lon ?? el.center?.lon;
  const address = [t["addr:housenumber"], t["addr:street"], t["addr:city"] ?? city.name].filter(Boolean).join(", ");
  return {
    business_key: businessKey({ website, phone, osmId }),
    business_name: name.slice(0, 200),
    categories_source: matchedTags.map((k) => `osm:${k}`),
    matched_category_ids: ids,
    email,
    address_source: email ? `https://www.openstreetmap.org/${osmId}` : null,
    phone,
    website,
    website_domain: normalizeDomain(website),
    osm_id: osmId,
    address: address || null,
    city: t["addr:city"] ?? city.name,
    city_id: city.city_id ?? null,
    state: city.state ?? null,
    postal_code: t["addr:postcode"] ?? null,
    lat,
    lng,
    timezone: city.timezone ?? null,
    source: "osm",
    source_ref: osmId,
    lawful_basis: "legitimate_interest",
    chosen_reason: `OSM ${matchedTags.join(", ")} in ${city.name}`,
    priority: city.priority ?? null,
  };
}

export interface PlacesPlace {
  id: string;
  displayName?: { text: string };
  formattedAddress?: string;
  nationalPhoneNumber?: string;
  internationalPhoneNumber?: string;
  websiteUri?: string;
  rating?: number;
  userRatingCount?: number;
  location?: { latitude: number; longitude: number };
  types?: string[];
  businessStatus?: string;
}

export const PLACES_FIELD_MASK = [
  "places.id", "places.displayName", "places.formattedAddress", "places.nationalPhoneNumber",
  "places.internationalPhoneNumber", "places.websiteUri", "places.rating", "places.userRatingCount",
  "places.location", "places.types", "places.businessStatus", "nextPageToken",
].join(",");

export function placeToLead(
  p: PlacesPlace,
  city: CityTarget,
  country: "IN" | "US",
  categoryIds: number[],
  query: string,
): LeadInput | null {
  if (!p.displayName?.text || p.businessStatus === "CLOSED_PERMANENTLY" || !categoryIds.length) return null;
  const phone = normalizePhone(p.internationalPhoneNumber ?? p.nationalPhoneNumber, country);
  return {
    business_key: businessKey({ website: p.websiteUri, phone, placeId: p.id }),
    business_name: p.displayName.text.slice(0, 200),
    categories_source: (p.types ?? []).map((t) => `places:${t}`),
    matched_category_ids: categoryIds,
    email: null, // Places has no email; only the business website may publish one
    phone,
    website: p.websiteUri ?? null,
    website_domain: normalizeDomain(p.websiteUri),
    place_id: p.id,
    address: p.formattedAddress ?? null,
    city: city.name,
    city_id: city.city_id ?? null,
    state: city.state ?? null,
    lat: p.location?.latitude,
    lng: p.location?.longitude,
    timezone: city.timezone ?? null,
    rating: p.rating ?? null,
    rating_count: p.userRatingCount ?? null,
    source: "places",
    source_ref: p.id,
    lawful_basis: "legitimate_interest",
    chosen_reason: `Google Places "${query}" in ${city.name}`,
    priority: city.priority ?? null,
  };
}

/** Hard monthly budget for Places (Section 21: free credit + hard cap). */
export function placesBudgetAllows(spentRequests: number, extraRequests: number, costPerRequestUsd: number, budgetUsd: number): boolean {
  return (spentRequests + extraRequests) * costPerRequestUsd <= budgetUsd + 1e-9;
}
