// Trends pipeline: every quality gate, and the Claude drafting flow with a mocked Messages API.
import { assert, assertEquals, assertRejects } from "@std/assert";
import { ClaudeError, claudeFromEnv, DEFAULT_MODEL, makeClaude } from "../_shared/trends/claude.ts";
import {
  appLinkFor,
  buildArticle,
  draftTopic,
  draftUpdate,
  pickSources,
  preGates,
} from "../_shared/trends/draft.ts";
import {
  checkSchema,
  detectSensitive,
  gateBalanceLocal,
  gateOriginality,
  gateSources,
  gateValue,
  removeSentences,
} from "../_shared/trends/gates.ts";
import type { Article } from "../_shared/trends/types.ts";
import { claudeFetch, iso, modelArticle, NOW, settings, sig, signals, topic } from "./trends_fixtures.ts";

const s = settings();
const article = (): Article =>
  buildArticle(structuredClone(modelArticle), topic, pickSources(signals, s), s, NOW);
const claude = (f: typeof fetch) => makeClaude({ apiKey: "test-key", model: DEFAULT_MODEL, fetch: f });

// ---- gate 1 -------------------------------------------------------------------------------------
Deno.test("gate 1: two independent citable publishers needed; redirects and aggregators do not count", () => {
  assertEquals(gateSources(signals, s).passed, true);
  assertEquals(gateSources(signals, s).domains, ["forecast.example.com", "metro.example.net"]);
  const one = signals.filter((x) => x.publisher_domain !== "metro.example.net");
  assertEquals(gateSources(one, s).passed, false);
  const sameDomain = [
    ...one,
    sig({
      topic: "x",
      url: "https://forecast.example.com/2",
      publisher_domain: "forecast.example.com",
      citable: true,
    }),
  ];
  assertEquals(gateSources(sameDomain, s).passed, false);
  const aggregator = [
    ...one,
    sig({ topic: "x", url: "https://www.reddit.com/r/x", publisher_domain: "reddit.com", citable: true }),
  ];
  assertEquals(gateSources(aggregator, s).passed, false);
});

// ---- gate 2 -------------------------------------------------------------------------------------
Deno.test("gate 2: sensitive keywords (whole words) and tags", () => {
  assertEquals(detectSensitive(["Two killed in Pune road crash"], [], s).reasons, ["keyword:killed"]);
  assertEquals(detectSensitive(["Election results today"], [], s).sensitive, true);
  assertEquals(detectSensitive(["Partying in the rain"], [], s).sensitive, false); // "party" is a whole word only
  assertEquals(detectSensitive(["Stock tips for Diwali"], [], s).reasons, ["keyword:stock tips"]);
  assertEquals(detectSensitive(["Snow day"], ["Health"], s).reasons, ["tag:health"]);
  assertEquals(detectSensitive(["Snow day"], ["weather"], s).sensitive, false);
});

Deno.test("gates 1-2 decide before any model call", () => {
  const single = preGates(topic, signals.slice(0, 2), s, false);
  assertEquals(single.outcome?.status, "rejected");
  assertEquals(single.outcome?.failed_gate, "sources");
  assertEquals(single.outcome?.topic_status, "waiting_sources");
  assertEquals(single.outcome?.domains_at_reject, 1);

  const crime = preGates({ ...topic, title: "Police arrest two after Chicago shooting" }, signals, s, false);
  assertEquals(crime.outcome?.status, "review");
  assertEquals(crime.outcome?.review_stage, "topic");
  assert(crime.outcome?.sensitive_reasons.includes("keyword:police"));

  const approved = preGates(
    { ...topic, title: "Police arrest two after Chicago shooting" },
    signals,
    s,
    true,
  );
  assertEquals(approved.outcome, null);
  assertEquals(preGates(topic, signals, s, false).outcome, null);
});

// ---- gate 3 -------------------------------------------------------------------------------------
Deno.test("gate 3: originality passes for own words, fails on copied snippet text and long quotes", () => {
  const a = article();
  const ok = gateOriginality(a, a.sources, s);
  assert(ok.passed, JSON.stringify(ok));
  const copied = structuredClone(a);
  copied.summary[0] = "Forecasters expect several inches of snow in the city by the weekend.";
  const bad = gateOriginality(copied, copied.sources, s);
  assertEquals(bad.passed, false);
  assertEquals(bad.worst_source, "forecast.example.com");
  const quoted = structuredClone(a);
  quoted.context += ` One official said "${"word ".repeat(30).trim()}".`;
  assertEquals(gateOriginality(quoted, quoted.sources, s).long_quote, true);
});

// ---- gate 5 + balance ------------------------------------------------------------------------------
Deno.test("gate 5: value needs enough words and every section", () => {
  const a = article();
  const v = gateValue(a, s);
  assert(v.passed, JSON.stringify(v));
  assert(v.words >= 250);
  const short = structuredClone(a);
  short.perspectives.a.body = "Short.";
  short.perspectives.b.body = "Short too.";
  assertEquals(gateValue(short, s).passed, false);
  const noLocal = structuredClone(a);
  noLocal.local_angle = "It matters here.";
  assertEquals(gateValue(noLocal, s).reason, 'section "local_angle" too short');
});

Deno.test("balance (local): banned partisan labels, identical labels, length ratio", () => {
  const a = article();
  assert(gateBalanceLocal(a, s).passed);
  const partisan = structuredClone(a);
  partisan.perspectives.a.label = "Left view";
  partisan.perspectives.b.label = "Right view";
  assertEquals(gateBalanceLocal(partisan, s).passed, false);
  const religious = structuredClone(a);
  religious.perspectives.framing = "Hindu vs Secular";
  assertEquals(gateBalanceLocal(religious, s).passed, false);
  const same = structuredClone(a);
  same.perspectives.b.label = "short-term";
  assertEquals(gateBalanceLocal(same, s).reason, "perspective labels are identical");
  const lopsided = structuredClone(a);
  lopsided.perspectives.b.body = lopsided.perspectives.b.body.split(" ").slice(0, 40).join(" ");
  assertEquals(gateBalanceLocal(lopsided, s).passed, false);
});

Deno.test("gate 4 (apply): unsupported sentences are removed", () => {
  const a = article();
  const r = removeSentences(a, [
    "One report says hardware stores are fielding more questions about snow blowers this week.",
  ]);
  assertEquals(r.removed, 1);
  assertEquals(r.article.summary.length, 2);
  assertEquals(removeSentences(a, ["tiny"]).removed, 0); // too short to match safely
});

Deno.test("schema check and contextual app link", () => {
  const a = article();
  assertEquals(checkSchema(a), null);
  assert(/^chicago-gets-ready-for-the-season-s-first-heavy-snow-7f3c2a$/.test(a.slug), a.slug);
  assertEquals(a.app_link, null); // no app_links rules in the default settings
  const withRules = settings({
    app_links: [{
      country: "usa",
      keywords: ["snow"],
      category: "furnace-repair",
      label: "Get furnace repair quotes in {place} on I Want USA",
    }],
  });
  assertEquals(appLinkFor(topic, "first heavy snow", withRules), {
    label: "Get furnace repair quotes in Chicago on I Want USA",
    url: "https://iwantusa.app/quotes/chicago/furnace-repair",
  });
  assertEquals(appLinkFor({ ...topic, country: "india" }, "first heavy snow", withRules), null);
});

// ---- Claude client ---------------------------------------------------------------------------------
Deno.test("Claude client: Messages API request shape, default model, structured output", async () => {
  const m = claudeFetch({});
  const c = claudeFromEnv((k) => ({ ANTHROPIC_API_KEY: "sk-test" } as Record<string, string>)[k], m.fetch)!;
  assertEquals(c.model, "claude-sonnet-5-5");
  const out = await c.json<{ headline: string }>({ system: "x", user: "y", schema: { type: "object" } });
  assertEquals(out.headline, modelArticle.headline);
  const call = m.calls[0];
  assertEquals(call.url, "https://api.anthropic.com/v1/messages");
  assertEquals(call.headers.get("x-api-key"), "sk-test");
  assertEquals(call.headers.get("anthropic-version"), "2023-06-01");
  assertEquals(call.body.model, "claude-sonnet-5-5");
  assertEquals((call.body.output_config as { format: { type: string } }).format.type, "json_schema");
  assertEquals(claudeFromEnv(() => undefined), null); // no key: no client, drafting skipped
  const custom = claudeFromEnv(
    (k) => ({ ANTHROPIC_API_KEY: "k", ANTHROPIC_MODEL: "claude-opus-5-5" } as Record<string, string>)[k],
    m.fetch,
  )!;
  assertEquals(custom.model, "claude-opus-5-5");
});

Deno.test("Claude client: refusal and HTTP errors throw", async () => {
  await assertRejects(
    () => claude(claudeFetch({ refuse: true }).fetch).json({ system: "", user: "", schema: {} }),
    ClaudeError,
    "general_harms",
  );
  const bad = (() => Promise.resolve(new Response("bad", { status: 400 }))) as typeof fetch;
  await assertRejects(() => claude(bad).json({ system: "", user: "", schema: {} }), ClaudeError);
});

// ---- the drafting pipeline -------------------------------------------------------------------------
Deno.test("draft: passes every gate and is queued with check results", async () => {
  const m = claudeFetch({});
  const o = await draftTopic({
    topic,
    signals,
    settings: s,
    claude: claude(m.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals(o.status, "queued", `${o.failed_gate}: ${o.reason}`);
  assertEquals(m.calls.map((c) => c.kind), ["article", "facts", "balance"]);
  const a = o.article!;
  assertEquals(a.checks.originality?.passed, true);
  assertEquals(a.checks.fact_consistency?.passed, true);
  assertEquals(a.checks.balance?.passed, true);
  assertEquals(a.sources.length, 2); // citable sources only, one per publisher
  assertEquals(a.ai_disclosure, "AI-assisted, automatically published");
  for (const g of ["sources", "sensitive", "originality", "facts", "value", "balance"]) {
    assert(o.gates[g]?.passed, g);
  }
  // prompt carries the two-perspective rules and the banned labels; only headlines/snippets are sent
  const sys = String(m.calls[0].body.system);
  assert(sys.includes("Short-term vs Long-term") && sys.includes("communist") && sys.includes("never: left"));
  assert(
    !String(m.calls[0].body.messages && JSON.stringify(m.calls[0].body.messages)).includes("news.google.com"),
  );
});

Deno.test("draft: single source or sensitive topic never reaches the model", async () => {
  const m = claudeFetch({});
  const o1 = await draftTopic({
    topic,
    signals: signals.slice(0, 2),
    settings: s,
    claude: claude(m.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals(o1.failed_gate, "sources");
  const o2 = await draftTopic({
    topic: { ...topic, title: "Chicago election turnout" },
    signals,
    settings: s,
    claude: claude(m.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals([o2.status, o2.review_stage], ["review", "topic"]);
  assertEquals(m.calls.length, 0);
});

Deno.test("draft: gate 3 rewrites once, then rejects", async () => {
  const copied = {
    ...modelArticle,
    summary: [
      "Forecasters expect several inches of snow in the city by the weekend.",
      ...modelArticle.summary.slice(1),
    ],
  };
  const m1 = claudeFetch({ article: [copied, modelArticle] });
  const o1 = await draftTopic({
    topic,
    signals,
    settings: s,
    claude: claude(m1.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals(o1.status, "queued");
  assertEquals(o1.rewrites, 1);
  assert(
    String((m1.calls[1].body.messages as { content: string }[])[0].content).includes("Rewrite it completely"),
  );

  const m2 = claudeFetch({ article: [copied, copied] });
  const o2 = await draftTopic({
    topic,
    signals,
    settings: s,
    claude: claude(m2.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals([o2.status, o2.failed_gate, o2.rewrites], ["rejected", "originality", 1]);
  assertEquals(m2.calls.filter((c) => c.kind === "article").length, 2);
});

Deno.test("draft: gate 4 conflicts wait for more sources; removed claims can fail gate 5", async () => {
  const conflict = await draftTopic({
    topic,
    signals,
    settings: s,
    now: NOW,
    topicApproved: false,
    claude: claude(
      claudeFetch({ facts: { unsupported_sentences: [], conflicts: true, conflict_notes: "totals differ" } })
        .fetch,
    ),
  });
  assertEquals([conflict.status, conflict.failed_gate, conflict.topic_status], [
    "rejected",
    "facts",
    "waiting_sources",
  ]);

  const a = modelArticle;
  const unsupported = await draftTopic({
    topic,
    signals,
    settings: s,
    now: NOW,
    topicApproved: false,
    claude: claude(
      claudeFetch({
        facts: {
          unsupported_sentences: [
            ...a.perspective_a.body.split(". ").slice(0, 4),
            ...a.perspective_b.body.split(". ").slice(0, 3),
          ],
          conflicts: false,
          conflict_notes: "",
        },
      }).fetch,
    ),
  });
  assertEquals(unsupported.status, "rejected");
  assert(["facts", "value", "balance"].includes(unsupported.failed_gate!), unsupported.failed_gate!);
  assert(
    (unsupported.gates.facts.unsupported_claims_removed as number) >= 5 ||
      unsupported.reason === "too little supported content left",
  );
});

Deno.test("draft: balance model pass and partisan labels reject", async () => {
  const b = await draftTopic({
    topic,
    signals,
    settings: s,
    now: NOW,
    topicApproved: false,
    claude: claude(
      claudeFetch({
        balance: {
          balanced: false,
          weaker_side: "b",
          loaded_terms: ["obviously"],
          reason: "B is a strawman",
        },
      }).fetch,
    ),
  });
  assertEquals([b.status, b.failed_gate], ["rejected", "balance"]);
  const partisan = {
    ...modelArticle,
    framing: "Liberal vs Conservative",
    perspective_a: { ...modelArticle.perspective_a, label: "Liberal" },
    perspective_b: { ...modelArticle.perspective_b, label: "Conservative" },
  };
  const m = claudeFetch({ article: [partisan] });
  const p = await draftTopic({
    topic,
    signals,
    settings: s,
    claude: claude(m.fetch),
    topicApproved: false,
    now: NOW,
  });
  assertEquals([p.status, p.failed_gate], ["rejected", "balance"]);
  assertEquals(m.calls.some((c) => c.kind === "balance"), false); // local check first, no extra spend
});

Deno.test("draft: approved sensitive topic is drafted, then waits for content review", async () => {
  const o = await draftTopic({
    topic: { ...topic, title: "Chicago police close roads for the snow" },
    signals,
    settings: s,
    now: NOW,
    topicApproved: true,
    claude: claude(claudeFetch({}).fetch),
  });
  assertEquals([o.status, o.review_stage], ["review", "content"]);
  assertEquals(o.article?.sensitive, true);
  // finished text that turns out sensitive (tags) also goes to review
  const tagged = await draftTopic({
    topic,
    signals,
    settings: s,
    now: NOW,
    topicApproved: false,
    claude: claude(claudeFetch({ article: [{ ...modelArticle, topic_tags: ["weather", "health"] }] }).fetch),
  });
  assertEquals([tagged.status, tagged.review_stage], ["review", "content"]);
});

Deno.test("live update: new citable sources add a dated Update and a correction", async () => {
  const a = article();
  const fresh = [sig({
    topic: "City adds overnight plow shifts",
    url: "https://third.example.org/plows",
    publisher: "Third",
    publisher_domain: "third.example.org",
    citable: true,
    snippet: "The city added overnight plow shifts for the storm.",
    first_seen: iso(3),
  })];
  const upd = {
    has_update: true,
    update_text:
      "Third reports that the city has scheduled extra crews to clear streets during the night, which should shorten waits on side streets once the heaviest bands pass through.",
    has_correction: true,
    correction_text:
      "An earlier version said stores reported more interest; a newer report gives a lower figure.",
  };
  const u = await draftUpdate({
    article: a,
    newSignals: fresh,
    settings: s,
    claude: claude(claudeFetch({ update: upd }).fetch),
    now: NOW,
  });
  assertEquals(u.kind, "both");
  assertEquals(u.article.updates.length, 1);
  assertEquals(u.article.corrections.length, 1);
  assertEquals(u.article.sources.length, 3);
  assertEquals(u.article.updated_at, NOW.toISOString());
  const none = await draftUpdate({
    article: a,
    newSignals: [],
    settings: s,
    claude: claude(claudeFetch({}).fetch),
    now: NOW,
  });
  assertEquals(none.kind, null);
  const copied = await draftUpdate({
    article: a,
    newSignals: fresh,
    settings: s,
    now: NOW,
    claude: claude(
      claudeFetch({
        update: {
          ...upd,
          update_text: `The city added overnight plow shifts for the storm. ${upd.update_text}`,
          has_correction: false,
        },
      }).fetch,
    ),
  });
  assertEquals(copied.kind, null); // copied wording is not published
});
