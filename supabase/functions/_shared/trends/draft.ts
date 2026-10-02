// Drafting for trends-draft: gates 1-2 before any model call, then the Claude draft
// (two-perspective format), gate 3 originality with one rewrite, gate 4 fact consistency
// (second model pass), gate 5 value, balance check (local + model pass). Gate 6 (caps,
// kill switch) is applied by the caller before drafting and again by trends-publish.
//
// Inputs are headlines, links and feed snippets only. Article pages are never fetched.
import type { Claude } from "./claude.ts";
import {
  bodyText,
  checkSchema,
  detectSensitive,
  gateBalanceLocal,
  gateOriginality,
  gateSources,
  gateValue,
  removeSentences,
} from "./gates.ts";
import { clip, containment, hostOf, overlappingPhrases, shingles, slugify, wordRe, words } from "./text.ts";
import type { Article, ArticleSource, GateResult, Settings, Signal, Topic } from "./types.ts";

export const AI_DISCLOSURE = "AI-assisted, automatically published";

export interface DraftOutcome {
  status: "queued" | "review" | "rejected";
  review_stage: "topic" | "content" | null;
  article: Article | null;
  gates: Record<string, GateResult>;
  failed_gate: string | null;
  reason: string | null;
  sensitive: boolean;
  sensitive_reasons: string[];
  rewrites: number;
  /** what happens to the topic */
  topic_status: Topic["status"];
  topic_reason: string;
  domains_at_reject?: number;
}

type DraftTopic = Pick<
  Topic,
  "id" | "country" | "place_slug" | "place_name" | "state" | "level" | "title" | "velocity"
>;

/** The citable sources handed to the model and listed under Sources: one per publisher domain. */
export function pickSources(signals: Signal[], s: Settings, max = 8): ArticleSource[] {
  const nonPub = new Set(s.detection.non_publisher_domains);
  const byDomain = new Map<string, Signal>();
  const sorted = [...signals].sort((a, b) =>
    Number(!!b.snippet) - Number(!!a.snippet) || Date.parse(b.first_seen) - Date.parse(a.first_seen)
  );
  for (const sig of sorted) {
    if (!sig.citable || !sig.url || !sig.publisher_domain || nonPub.has(sig.publisher_domain)) continue;
    if (!byDomain.has(sig.publisher_domain)) byDomain.set(sig.publisher_domain, sig);
  }
  return [...byDomain.values()].slice(0, max).map((sig) => ({
    publisher: sig.publisher || sig.publisher_domain!,
    url: sig.url!,
    title: clip(sig.topic, 200),
    ...(sig.snippet ? { snippet: clip(sig.snippet, 300) } : {}),
  }));
}

/** Gates 1 and 2: decided from feed data alone, before any model call. */
export function preGates(
  topic: DraftTopic,
  signals: Signal[],
  s: Settings,
  topicApproved: boolean,
): {
  gates: Record<string, GateResult>;
  outcome: DraftOutcome | null;
  sensitive: { sensitive: boolean; reasons: string[] };
} {
  const gates: Record<string, GateResult> = {};
  const g1 = gateSources(signals, s);
  gates.sources = g1;
  const sens = detectSensitive([topic.title, ...signals.map((x) => x.topic)], [], s);
  gates.sensitive = {
    passed: !sens.sensitive || topicApproved,
    reasons: sens.reasons,
    topic_approved: topicApproved,
  };
  const base = {
    article: null,
    rewrites: 0,
    sensitive: sens.sensitive,
    sensitive_reasons: sens.reasons,
    gates,
  };
  if (!g1.passed) {
    return {
      gates,
      sensitive: sens,
      outcome: {
        ...base,
        status: "rejected",
        review_stage: null,
        failed_gate: "sources",
        reason: String(g1.detail),
        topic_status: "waiting_sources",
        topic_reason: "fewer than min_sources publishers",
        domains_at_reject: g1.domains.length,
      },
    };
  }
  if (sens.sensitive && !topicApproved) {
    return {
      gates,
      sensitive: sens,
      outcome: {
        ...base,
        status: "review",
        review_stage: "topic",
        failed_gate: null,
        reason: `sensitive topic (${sens.reasons.join(", ")}): human review`,
        topic_status: "review",
        topic_reason: "sensitive",
      },
    };
  }
  return { gates, outcome: null, sensitive: sens };
}

// ---- prompts ------------------------------------------------------------------------------------

const str = { type: "string" };
const ARTICLE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: [
    "headline",
    "summary",
    "framing",
    "perspective_a",
    "perspective_b",
    "agree",
    "context",
    "local_angle",
    "watch_next",
    "topic_tags",
  ],
  properties: {
    headline: str,
    summary: { type: "array", items: str },
    framing: str,
    perspective_a: {
      type: "object",
      additionalProperties: false,
      required: ["label", "body"],
      properties: { label: str, body: str },
    },
    perspective_b: {
      type: "object",
      additionalProperties: false,
      required: ["label", "body"],
      properties: { label: str, body: str },
    },
    agree: str,
    context: str,
    local_angle: str,
    watch_next: str,
    topic_tags: { type: "array", items: str },
  },
};

const FACTS_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["unsupported_sentences", "conflicts", "conflict_notes"],
  properties: {
    unsupported_sentences: { type: "array", items: str },
    conflicts: { type: "boolean" },
    conflict_notes: str,
  },
};

const BALANCE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["balanced", "weaker_side", "loaded_terms", "reason"],
  properties: {
    balanced: { type: "boolean" },
    weaker_side: { type: "string", enum: ["a", "b", "none"] },
    loaded_terms: { type: "array", items: str },
    reason: str,
  },
};

const UPDATE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["has_update", "update_text", "has_correction", "correction_text"],
  properties: {
    has_update: { type: "boolean" },
    update_text: str,
    has_correction: { type: "boolean" },
    correction_text: str,
  },
};

interface ModelArticle {
  headline: string;
  summary: string[];
  framing: string;
  perspective_a: { label: string; body: string };
  perspective_b: { label: string; body: string };
  agree: string;
  context: string;
  local_angle: string;
  watch_next: string;
  topic_tags: string[];
}

export function draftSystemPrompt(s: Settings): string {
  return [
    "You write short, original explainers for a neutral local news site about what is trending in a place.",
    "Facts: use ONLY facts stated in the source headlines and snippets you are given. Do not invent or add numbers, names, dates, places, quotes or events. If the sources say little, write less about facts and more about why it matters.",
    "Originality: write everything in your own words. Never reuse a run of six or more words from any source. No quotation longer than one sentence, and attribute every quotation to its publisher.",
    'Format: headline (factual, plain, no clickbait, no question, at most 110 characters); summary (exactly 3 short neutral sentences of the facts); framing ("<Label A> vs <Label B>"); perspective_a and perspective_b (each 120-170 words); agree (30-60 words: where the two views agree); context (40-80 words of general, uncontroversial background, no new specific facts); local_angle (40-80 words: what it means for people in the place); watch_next (30-60 words: what to watch next); topic_tags (1-5 lowercase tags such as weather, traffic, transport, sports, events, consumer, home, jobs, education, technology, plus any of these that apply honestly: ' +
    s.sensitive_tags.join(", ") + ").",
    "Perspectives: choose two clearly labelled, neutral viewpoints that fit the topic, e.g. For vs Against, Traditional vs Modern, Economic view vs Social view, Consumer view vs Business view, Short-term vs Long-term, Human-made vs AI/automated. Argue each in its best form with evidence from the sources, at similar length and equal strength, in a calm tone. Never use ideological, partisan or religious labels or framings (never: " +
    s.banned_perspective_terms.join(", ") +
    "), and never attribute a viewpoint to a real group or person unless a source shows they hold it.",
    "Aim for 330-420 words in total. Plain, clear English. No markdown, no links, no emojis.",
  ].join("\n\n");
}

function sourcesBlock(sources: ArticleSource[]): string {
  return sources.map((src, i) =>
    `[${i + 1}] ${src.publisher} (${hostOf(src.url)})\nHeadline: ${src.title ?? ""}${
      src.snippet ? `\nSnippet: ${src.snippet}` : ""
    }`
  ).join("\n\n");
}

function draftUserPrompt(topic: DraftTopic, sources: ArticleSource[]): string {
  const where = [
    topic.place_name,
    topic.state && topic.state !== topic.place_name ? topic.state : null,
    topic.country === "usa" ? "USA" : "India",
  ].filter(Boolean).join(", ");
  return `Topic trending in ${where}: "${topic.title}"\n\nSources (headlines and feed snippets only):\n\n${
    sourcesBlock(sources)
  }\n\nWrite the article as JSON.`;
}

function articleText(a: Article): string {
  return [
    `Headline: ${a.headline}`,
    `Summary: ${a.summary.join(" ")}`,
    `Context: ${a.context ?? ""}`,
    `${a.perspectives.a.label}: ${a.perspectives.a.body}`,
    `${a.perspectives.b.label}: ${a.perspectives.b.body}`,
    `Where they agree: ${a.agree}`,
    `Local angle: ${a.local_angle}`,
    `What to watch: ${a.watch_next}`,
  ].join("\n\n");
}

// ---- assembly -------------------------------------------------------------------------------------

export function appLinkFor(topic: DraftTopic, text: string, s: Settings): Article["app_link"] {
  for (const rule of s.app_links) {
    if (rule.country !== topic.country) continue;
    const re = wordRe(rule.keywords);
    if (!re || !re.test(`${topic.title}\n${text}`)) continue;
    const host = s.app_hosts[topic.country];
    if (!host || !/^[a-z0-9-]+$/.test(rule.category)) continue;
    return {
      label: rule.label.replace("{place}", topic.place_name),
      url: `https://${host}/quotes/${topic.place_slug}/${rule.category}`,
    };
  }
  return null;
}

export function makeSlug(headline: string, topicId: string): string {
  const suffix = topicId.replace(/[^a-z0-9]/gi, "").slice(0, 6).toLowerCase();
  return `${slugify(headline, 72)}-${suffix}`;
}

export function buildArticle(
  m: ModelArticle,
  topic: DraftTopic,
  sources: ArticleSource[],
  s: Settings,
  now: Date,
): Article {
  const clean = (x: unknown) => (typeof x === "string" ? x.replace(/\s+/g, " ").trim() : "");
  const summary = (Array.isArray(m.summary) ? m.summary : []).map(clean).filter(Boolean).slice(0, 3);
  const tags = [
    ...new Set(
      (Array.isArray(m.topic_tags) ? m.topic_tags : []).map((t) => clean(t).toLowerCase()).filter((t) =>
        /^[a-z0-9-]{2,30}$/.test(t)
      ),
    ),
  ].slice(0, 5);
  const headline = clean(m.headline).slice(0, 140);
  const a: Article = {
    id: `${topic.country}-${topic.id}`,
    slug: makeSlug(headline || topic.title, topic.id),
    country: topic.country,
    places: [{
      slug: topic.place_slug,
      name: topic.place_name,
      ...(topic.state ? { state: topic.state } : {}),
      level: topic.level,
    }],
    headline,
    summary,
    context: clean(m.context),
    perspectives: {
      framing: clean(m.framing),
      a: { label: clean(m.perspective_a?.label), body: clean(m.perspective_a?.body) },
      b: { label: clean(m.perspective_b?.label), body: clean(m.perspective_b?.body) },
    },
    agree: clean(m.agree),
    local_angle: clean(m.local_angle),
    watch_next: clean(m.watch_next),
    updates: [],
    corrections: [],
    sources,
    topic_tags: tags,
    sensitive: false,
    review: { approved_by: null, approved_at: null },
    checks: {},
    published_at: now.toISOString(),
    updated_at: now.toISOString(),
    trend_ended_at: null,
    traffic: { visits_14d_after_end: null },
    superseded_by: null,
    app_link: null,
    velocity: Math.round(topic.velocity),
    ai_disclosure: AI_DISCLOSURE,
  };
  a.app_link = appLinkFor(topic, `${a.headline}\n${a.summary.join(" ")}`, s);
  return a;
}

// ---- the pipeline ---------------------------------------------------------------------------------

export async function draftTopic(args: {
  topic: DraftTopic;
  signals: Signal[];
  settings: Settings;
  claude: Claude;
  topicApproved: boolean;
  now: Date;
}): Promise<DraftOutcome> {
  const { topic, signals, settings: s, claude, topicApproved, now } = args;
  const pre = preGates(topic, signals, s, topicApproved);
  if (pre.outcome) return pre.outcome;
  const gates = pre.gates;
  const sources = pickSources(signals, s);
  let rewrites = 0;
  const reject = (gate: string, reason: string, extra: Partial<DraftOutcome> = {}): DraftOutcome => ({
    status: "rejected",
    review_stage: null,
    article: null,
    gates,
    failed_gate: gate,
    reason,
    rewrites,
    sensitive: pre.sensitive.sensitive,
    sensitive_reasons: pre.sensitive.reasons,
    topic_status: "dropped",
    topic_reason: `rejected at ${gate}`,
    ...extra,
  });

  // Draft
  const system = draftSystemPrompt(s);
  const m = await claude.json<ModelArticle>({
    system,
    user: draftUserPrompt(topic, sources),
    schema: ARTICLE_SCHEMA,
  });
  let article = buildArticle(m, topic, sources, s, now);
  const schemaErr = checkSchema(article);
  if (schemaErr) return reject("schema", schemaErr);

  // Gate 3: originality, one rewrite, then reject
  let g3 = gateOriginality(article, sources, s);
  while (!g3.passed && rewrites < s.gates.max_rewrites) {
    rewrites++;
    const phrases = sources.flatMap((src) =>
      overlappingPhrases(bodyText(article), `${src.title ?? ""} ${src.snippet ?? ""}`, s.gates.shingle_words)
    );
    const rw = await claude.json<ModelArticle>({
      system,
      user: `${draftUserPrompt(topic, sources)}\n\nYour previous draft reused source wording${
        g3.long_quote ? " and contained a quotation longer than one sentence" : ""
      }. Rewrite it completely in your own words, keeping the same facts and structure.${
        phrases.length ? ` Do not use these phrases: ${phrases.map((p) => `"${p}"`).join(", ")}.` : ""
      }\n\nPrevious draft:\n${articleText(article)}`,
      schema: ARTICLE_SCHEMA,
    });
    article = buildArticle(rw, topic, sources, s, now);
    if (checkSchema(article)) return reject("schema", checkSchema(article)!);
    g3 = gateOriginality(article, sources, s);
  }
  gates.originality = { ...g3, rewrites };
  if (!g3.passed) {
    return reject(
      "originality",
      g3.long_quote
        ? "quote longer than one sentence"
        : `${Math.round(g3.max_similarity * 100)}% overlap with ${g3.worst_source}`,
    );
  }

  // Gate 4: fact consistency (second model pass)
  const facts = await claude.json<
    { unsupported_sentences: string[]; conflicts: boolean; conflict_notes: string }
  >({
    system:
      "You are a strict fact checker for a local news site. Compare the draft with the source headlines and snippets. " +
      "List, copied exactly, every sentence of the draft that states a specific fact (a number, name, date, place, event or quotation) that the sources do not support. " +
      "Arguments, analysis, general uncontroversial background and forward-looking 'what to watch' statements are not specific facts. " +
      "Set conflicts to true only if the sources contradict each other on a key fact (what happened, numbers, who, when, where).",
    user: `Sources:\n\n${sourcesBlock(sources)}\n\nDraft:\n\n${articleText(article)}`,
    schema: FACTS_SCHEMA,
    maxTokens: 4000,
  });
  if (facts.conflicts) {
    gates.facts = { passed: false, conflicts: true, notes: clip(facts.conflict_notes ?? "", 500) };
    return reject("facts", "sources conflict on key facts; waiting for more sources", {
      topic_status: "waiting_sources",
      topic_reason: "sources conflict",
      domains_at_reject: (gates.sources.domains as string[]).length,
    });
  }
  const removal = removeSentences(article, facts.unsupported_sentences ?? []);
  article = removal.article;
  gates.facts = {
    passed: true,
    conflicts: false,
    unsupported_claims_removed: removal.removed,
    flagged: (facts.unsupported_sentences ?? []).length,
  };
  if (checkSchema(article) || !article.summary.length) {
    return reject("facts", "too little supported content left");
  }

  // Gate 5: value
  const g5 = gateValue(article, s);
  gates.value = g5;
  if (!g5.passed) return reject("value", g5.reason ?? "too short");

  // Balance: local rules, then a second model pass on tone and strength
  const gb = gateBalanceLocal(article, s);
  if (!gb.passed) {
    gates.balance = gb;
    return reject("balance", gb.reason ?? "unbalanced");
  }
  const bal = await claude.json<
    { balanced: boolean; weaker_side: string; loaded_terms: string[]; reason: string }
  >({
    system:
      "You review two-perspective news explainers for balance. The two perspectives must be of similar strength, each argued in its best form, in a neutral tone without loaded or emotive words, with neutral labels (never ideological, partisan or religious), and must not attribute a viewpoint to a real group or person without a source. Answer strictly.",
    user: articleText(article),
    schema: BALANCE_SCHEMA,
    maxTokens: 2000,
  });
  gates.balance = {
    passed: !!bal.balanced,
    ratio: gb.ratio,
    weaker_side: bal.weaker_side,
    loaded_terms: bal.loaded_terms ?? [],
    reason: clip(bal.reason ?? "", 300),
  };
  if (!bal.balanced) return reject("balance", `balance check failed: ${clip(bal.reason ?? "", 200)}`);

  // Sensitive after drafting (tags / keywords in the finished text): human review of the content.
  const post = detectSensitive([article.headline, article.summary.join("\n")], article.topic_tags, s);
  const sensitive = pre.sensitive.sensitive || post.sensitive;
  const reasons = [...new Set([...pre.sensitive.reasons, ...post.reasons])];
  article.sensitive = sensitive;
  article.checks = {
    originality: { passed: true, max_similarity: g3.max_similarity },
    fact_consistency: { passed: true, conflicts: false, unsupported_claims_removed: removal.removed },
    balance: { passed: true },
  };
  gates.sensitive = { ...gates.sensitive, passed: !sensitive, reasons, topic_approved: topicApproved };
  if (sensitive) {
    return {
      status: "review",
      review_stage: "content",
      article,
      gates,
      failed_gate: null,
      reason: `sensitive (${reasons.join(", ")}): needs human approval before publishing`,
      rewrites,
      sensitive,
      sensitive_reasons: reasons,
      topic_status: "review",
      topic_reason: "sensitive content",
    };
  }
  return {
    status: "queued",
    review_stage: null,
    article,
    gates,
    failed_gate: null,
    reason: null,
    rewrites,
    sensitive: false,
    sensitive_reasons: [],
    topic_status: "drafted",
    topic_reason: "drafted",
  };
}

// ---- live updates -------------------------------------------------------------------------------

export interface UpdateOutcome {
  article: Article;
  kind: "update" | "correction" | "both" | null;
  reason: string;
}

/** New signals on a published topic -> a dated "Update" section and/or a correction. */
export async function draftUpdate(args: {
  article: Article;
  newSignals: Signal[];
  settings: Settings;
  claude: Claude;
  now: Date;
}): Promise<UpdateOutcome> {
  const { article, newSignals, settings: s, claude, now } = args;
  const fresh = pickSources(newSignals, s, 6).filter((src) =>
    !article.sources.some((o) => o.url === src.url)
  );
  if (!fresh.length) return { article, kind: null, reason: "no new citable sources" };
  if ((article.updates?.length ?? 0) >= s.detection.max_updates) {
    return { article, kind: null, reason: "max updates reached" };
  }
  const r = await claude.json<
    { has_update: boolean; update_text: string; has_correction: boolean; correction_text: string }
  >({
    system:
      "You maintain a published local news explainer. From the NEW source headlines and snippets only, write update_text: 40-120 words of genuinely new facts not already in the article, in your own words (never six or more words copied from a source), attributing them to their publishers. Set has_update false if there is nothing new. If a new source corrects a fact the article states, set has_correction and write correction_text (one or two sentences: what was wrong and what the sources now say). Neutral tone, no speculation.",
    user: `Published article:\n\n${articleText(article)}\n\nNEW sources:\n\n${sourcesBlock(fresh)}`,
    schema: UPDATE_SCHEMA,
    maxTokens: 2000,
  });
  const out: Article = structuredClone(article);
  let kind: UpdateOutcome["kind"] = null;
  const ok = (text: string) => {
    const n = s.gates.shingle_words;
    const sh = shingles(text, n);
    return fresh.every((src) =>
      containment(sh, `${src.title ?? ""} ${src.snippet ?? ""}`, n) <= s.gates.max_similarity
    );
  };
  if (r.has_update && words(r.update_text) >= 25 && ok(r.update_text)) {
    out.updates = [...(out.updates ?? []), {
      at: now.toISOString(),
      text: r.update_text.replace(/\s+/g, " ").trim(),
    }];
    kind = "update";
  }
  if (r.has_correction && words(r.correction_text) >= 8 && ok(r.correction_text)) {
    out.corrections = [...(out.corrections ?? []), {
      at: now.toISOString(),
      text: r.correction_text.replace(/\s+/g, " ").trim(),
    }];
    kind = kind ? "both" : "correction";
  }
  if (!kind) return { article, kind: null, reason: "nothing new or not original enough" };
  out.sources = [...out.sources, ...fresh].slice(0, 14);
  // the whole article must still pass originality against every source
  const g3 = gateOriginality(out, out.sources, s);
  if (!g3.passed) return { article, kind: null, reason: "update failed originality" };
  out.checks = {
    ...out.checks,
    originality: {
      passed: true,
      max_similarity: Math.max(out.checks.originality?.max_similarity ?? 0, g3.max_similarity),
    },
  };
  out.updated_at = now.toISOString();
  return { article: out, kind, reason: kind };
}
