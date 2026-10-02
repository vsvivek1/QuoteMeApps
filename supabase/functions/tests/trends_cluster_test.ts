// Trends pipeline: title normalisation, clustering, velocity and firing.
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import { clusterSignals, computeVelocity, nextTopicState } from "../_shared/trends/cluster.ts";
import { normalizeTitle, slugify, titleSimilarity } from "../_shared/trends/text.ts";
import type { SignalInput } from "../_shared/trends/types.ts";
import { iso, NOW, settings, sig } from "./trends_fixtures.ts";

const d = settings().detection;

function input(p: Partial<SignalInput> & { topic: string }): SignalInput {
  return {
    source_id: 1,
    source_kind: "google_news",
    country: "india",
    place_slug: "pune",
    place_name: "Pune",
    state: "Maharashtra",
    level: "metro",
    geo: "IN-MH",
    norm_title: normalizeTitle(p.topic, p.publisher),
    dedupe_key: p.url ?? p.topic,
    url: null,
    publisher: null,
    publisher_domain: null,
    citable: false,
    snippet: null,
    score: 0,
    ...p,
  };
}

Deno.test("normalizeTitle strips the publisher suffix, case, punctuation and accents", () => {
  assertEquals(
    normalizeTitle("Pune Heatwave: Mercury Hits 42°C - Hindustan Times", "Hindustan Times"),
    "pune heatwave mercury hits 42 c",
  );
  assertEquals(normalizeTitle("Café prices rise | The Hindu", "The Hindu"), "cafe prices rise");
  assertEquals(normalizeTitle("Pune - the city - grows"), "pune the city grows");
});

Deno.test("titleSimilarity: same story high, different stories low, short trend query contained", () => {
  assert(
    titleSimilarity(
      normalizeTitle("Pune heatwave: mercury hits 42 degrees"),
      normalizeTitle("Heatwave grips Pune as mercury hits 42"),
    ) >= 0.5,
  );
  assert(
    titleSimilarity(
      normalizeTitle("ipl final"),
      normalizeTitle("IPL final: Mumbai beat Chennai in a thriller"),
    ) === 1,
  );
  assert(
    titleSimilarity(normalizeTitle("Pune heatwave"), normalizeTitle("Metro line 3 opens in Pune")) < 0.5,
  );
  // the place name alone never makes two headlines the same story
  assert(
    titleSimilarity(
      normalizeTitle("Pune heatwave hits"),
      normalizeTitle("Pune metro opens"),
      new Set(["pune"]),
    ) === 0,
  );
  assertEquals(titleSimilarity("", "pune"), 0);
});

Deno.test("clustering merges duplicates per place and keeps places apart", () => {
  const s = [
    input({ topic: "Pune heatwave: mercury hits 42 degrees", url: "https://a.example.com/1" }),
    input({ topic: "Heatwave grips Pune as mercury hits 42", url: "https://b.example.com/2" }),
    input({ topic: "Metro line 3 opens in Pune", url: "https://c.example.com/3" }),
    input({
      topic: "Mumbai heatwave: mercury hits 40 degrees",
      url: "https://d.example.com/4",
      place_slug: "mumbai",
      place_name: "Mumbai",
    }),
  ];
  const r = clusterSignals(s, [], d.cluster_similarity);
  assertEquals(r.assignments[0], r.assignments[1]);
  assertNotEquals(r.assignments[0], r.assignments[2]);
  assertNotEquals(r.assignments[0], r.assignments[3]); // same words, other place
  assertEquals([...r.topics.values()].filter((t) => t.isNew).length, 3);
});

Deno.test("clustering joins an existing active topic and Google Trends news items join their trend", () => {
  const active = [{
    id: "t1",
    country: "india" as const,
    place_slug: "pune",
    place_name: "Pune",
    state: "Maharashtra",
    level: "metro" as const,
    title: "Pune heatwave",
    norm_title: "pune heatwave",
    alt_titles: [],
    status: "watching" as const,
  }];
  const s = [
    input({ topic: "Heatwave in Pune: schools change timings", url: "https://e.example.com/5" }),
    input({
      source_kind: "google_trends",
      topic: "pune rains",
      cluster_hint: "pune rains",
      dedupe_key: "trend:pune rains",
    }),
    input({
      source_kind: "google_trends",
      topic: "Unexpected showers bring relief",
      url: "https://f.example.com/6",
      cluster_hint: "pune rains",
    }),
  ];
  const r = clusterSignals(s, active, d.cluster_similarity);
  assertEquals(r.assignments[0], "t1");
  assertEquals(r.assignments[1], r.assignments[2]); // the news item joins its trend despite no shared words
  assert(r.topics.get("t1")!.alt_titles.includes(s[0].norm_title));
  // a trend title already stored: its news items join the stored topic through the hint
  const known = new Map([["india|pune|pune rains", "t1"]]);
  const r2 = clusterSignals([s[2]], active, d.cluster_similarity, known);
  assertEquals(r2.assignments[0], "t1");
});

Deno.test("velocity grows with fresh signals and independent publishers, decays when old", () => {
  const fresh = [
    sig({ source_kind: "google_trends", topic: "t", score: 20000, first_seen: iso(20), last_seen: iso(2) }),
    ...["a", "b", "c", "d"].map((x, i) =>
      sig({
        topic: "t",
        url: `https://${x}.example.com/n`,
        publisher_domain: `${x}.example.com`,
        citable: true,
        first_seen: iso(10 + i),
      })
    ),
  ];
  const v = computeVelocity(fresh, NOW, d);
  assert(v.velocity >= d.fire_threshold, `fresh velocity ${v.velocity}`);
  assertEquals(v.domains.length, 4);

  const old = fresh.map((s) => ({ ...s, first_seen: iso(60 * 20), last_seen: iso(60 * 20) }));
  const vo = computeVelocity(old, NOW, d);
  assert(vo.velocity < d.end_velocity, `old velocity ${vo.velocity}`);

  const one = computeVelocity([fresh[1]], NOW, d);
  assert(one.velocity < v.velocity && one.velocity < d.fire_threshold);
});

Deno.test("velocity rewards acceleration over the baseline", () => {
  const recent = [1, 2, 3].map((i) =>
    sig({ topic: "t", first_seen: iso(i * 5), publisher_domain: "x.example.com" })
  );
  const steady = [
    ...recent,
    ...[90, 120, 150, 180, 210, 240, 270, 300, 330].map((m) =>
      sig({ topic: "t", first_seen: iso(m), last_seen: iso(m) })
    ),
  ];
  const burst = computeVelocity(recent, NOW, d);
  const flat = computeVelocity(steady, NOW, d);
  assert(burst.accel > flat.accel);
});

Deno.test("topic transitions: fire, re-fire with more sources, end, drop", () => {
  const hot = {
    velocity: 80,
    signalCount: 5,
    domains: ["a.com", "b.com"],
    recentWeight: 9,
    baselineRate: 0,
    accel: 2,
    publisherDomains: 2,
  };
  const cold = { ...hot, velocity: 3 };
  const base = { last_seen: iso(1), first_seen: iso(30), domains_at_reject: null, fired_at: null };
  assertEquals(nextTopicState({ ...base, status: "watching" }, hot, NOW, d)?.status, "fired");
  assertEquals(nextTopicState({ ...base, status: "watching" }, { ...hot, signalCount: 1 }, NOW, d), null); // too few signals
  assertEquals(nextTopicState({ ...base, status: "watching" }, cold, NOW, d), null);
  assertEquals(
    nextTopicState({ ...base, status: "waiting_sources", domains_at_reject: 2 }, hot, NOW, d),
    null,
  );
  assertEquals(
    nextTopicState({ ...base, status: "waiting_sources", domains_at_reject: 1 }, hot, NOW, d)?.status,
    "fired",
  );
  assertEquals(
    nextTopicState({ ...base, status: "published", last_seen: iso(60 * 7) }, cold, NOW, d)?.status,
    "ended",
  );
  assertEquals(nextTopicState({ ...base, status: "published" }, cold, NOW, d), null); // seen recently
  assertEquals(
    nextTopicState({ ...base, status: "watching", first_seen: iso(60 * 49) }, cold, NOW, d)?.status,
    "dropped",
  );
});

Deno.test("slugify", () => {
  assertEquals(
    slugify("Chicago gets ready: the season's first heavy snow!"),
    "chicago-gets-ready-the-season-s-first-heavy-snow",
  );
  assertEquals(slugify("à la carte — menu"), "a-la-carte-menu");
  assert(slugify("word ".repeat(40), 20).length <= 20);
  assertEquals(slugify("!!!"), "story");
});
