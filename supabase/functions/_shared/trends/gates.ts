// Quality gates of brief Section 21.10, as pure functions. The same thresholds and the
// same counting rules as the site build (web/trends_site/src/lib/articles.ts), so an article
// that passes here also passes the build's last-line-of-defence checks.
//
//   1 sources      >= min_sources independent publisher domains with citable links
//   2 sensitive    sensitive tags / keywords -> human review queue, never auto-publish
//   3 originality  n-gram containment vs every source title+snippet <= max_similarity; no long quotes
//   4 facts        second model pass (see draft.ts); unsupported sentences removed here
//   5 value        >= min_words of real content, local angle / context / what to watch
//   5b balance     neutral non-partisan labels, similar length (+ model tone check in draft.ts)
//   6 caps         see ramp.ts
import { containment, hostOf, shingles, splitSentences, wordRe, words } from "./text.ts";
import type { Article, ArticleSource, GateResult, Settings, Signal } from "./types.ts";

export function bodyText(
  a: Pick<
    Article,
    "summary" | "perspectives" | "agree" | "local_angle" | "context" | "watch_next" | "updates"
  >,
): string {
  return [
    ...a.summary,
    a.perspectives.a.body,
    a.perspectives.b.body,
    a.agree,
    a.local_angle,
    a.context ?? "",
    a.watch_next,
    ...(a.updates ?? []).map((u) => u.text),
  ].join("\n");
}

/** Gate 1: independent publishers with citable links (aggregators and social sites do not count). */
export function gateSources(
  signals: Pick<Signal, "citable" | "publisher_domain" | "url">[],
  s: Settings,
): GateResult & {
  domains: string[];
} {
  const nonPub = new Set(s.detection.non_publisher_domains);
  const domains = new Set<string>();
  for (const sig of signals) {
    if (!sig.citable || !sig.publisher_domain || nonPub.has(sig.publisher_domain)) continue;
    domains.add(sig.publisher_domain);
  }
  const list = [...domains].sort();
  return {
    passed: list.length >= s.gates.min_sources,
    domains: list,
    detail: `${list.length} independent source domain(s), need ${s.gates.min_sources}`,
  };
}

/** Gate 2: sensitive topics (tags from the model, keywords in title / headlines / summary). */
export function detectSensitive(
  texts: string[],
  tags: string[],
  s: Settings,
): { sensitive: boolean; reasons: string[] } {
  const reasons: string[] = [];
  const tagSet = new Set(s.sensitive_tags.map((t) => t.toLowerCase()));
  for (const t of tags) if (tagSet.has(t.toLowerCase())) reasons.push(`tag:${t.toLowerCase()}`);
  const re = wordRe(s.sensitive_keywords);
  if (re) {
    for (const t of texts) {
      const m = re.exec(t);
      if (m) {
        const k = `keyword:${m[1].toLowerCase().replace(/\s+/g, " ")}`;
        if (!reasons.includes(k)) reasons.push(k);
      }
    }
  }
  return { sensitive: reasons.length > 0, reasons };
}

/** Gate 3: originality against every cited source, and no quote longer than max_quote_words. */
export function gateOriginality(
  a: Pick<
    Article,
    "summary" | "perspectives" | "agree" | "local_angle" | "context" | "watch_next" | "updates" | "headline"
  >,
  sources: ArticleSource[],
  s: Settings,
): GateResult & { max_similarity: number; worst_source: string | null; long_quote: boolean } {
  const n = s.gates.shingle_words;
  const text = bodyText(a);
  const draft = shingles(text, n);
  let max = 0;
  let worst: string | null = null;
  for (const src of sources) {
    const sim = containment(draft, `${src.title ?? ""} ${src.snippet ?? ""}`, n);
    if (sim > max) {
      max = sim;
      worst = hostOf(src.url);
    }
  }
  const quotes = text.match(/[“"]([^”"]+)[”"]/g) ?? [];
  const longQuote = quotes.some((q) => words(q) > s.gates.max_quote_words);
  const rounded = Math.round(max * 1000) / 1000;
  return {
    passed: max <= s.gates.max_similarity && !longQuote,
    max_similarity: rounded,
    worst_source: worst,
    long_quote: longQuote,
  };
}

/** Gate 5: enough real content, with the local angle, what to watch and where they agree. */
export function gateValue(a: Article, s: Settings): GateResult & { words: number; reason: string | null } {
  const total = words(bodyText(a));
  if (total < s.gates.min_words) {
    return { passed: false, words: total, reason: `${total} words, need ${s.gates.min_words}` };
  }
  for (
    const [name, val] of [["local_angle", a.local_angle], ["watch_next", a.watch_next], [
      "agree",
      a.agree,
    ]] as const
  ) {
    if (words(val) < s.gates.min_section_words) {
      return { passed: false, words: total, reason: `section "${name}" too short` };
    }
  }
  if (!a.context || words(a.context) < s.gates.min_section_words) {
    return { passed: false, words: total, reason: 'section "context" too short' };
  }
  return { passed: true, words: total, reason: null };
}

/** Gate 5b (local part): neutral labels, distinct labels, similar length. */
export function gateBalanceLocal(
  a: Pick<Article, "perspectives">,
  s: Settings,
): GateResult & { reason: string | null; ratio: number } {
  const { a: pa, b: pb, framing } = a.perspectives;
  const banned = wordRe(s.banned_perspective_terms);
  const label = `${framing} ${pa.label} ${pb.label}`;
  const wa = words(pa.body);
  const wb = words(pb.body);
  const ratio = Math.round((Math.max(wa, wb) / Math.max(1, Math.min(wa, wb))) * 100) / 100;
  const hit = banned?.exec(label)?.[0];
  if (hit) return { passed: false, ratio, reason: `partisan or ideological perspective label ("${hit}")` };
  if (pa.label.trim().toLowerCase() === pb.label.trim().toLowerCase()) {
    return { passed: false, ratio, reason: "perspective labels are identical" };
  }
  if (ratio > s.gates.max_perspective_ratio) {
    return { passed: false, ratio, reason: `perspectives unbalanced (${wa} vs ${wb} words)` };
  }
  return { passed: true, ratio, reason: null };
}

/** Gate 4 (apply): removes sentences the fact checker marked unsupported. Returns the count removed. */
export function removeSentences(a: Article, unsupported: string[]): { article: Article; removed: number } {
  const norm = (x: string) => x.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  const targets = unsupported.map(norm).filter((x) => x.length >= 12);
  let removed = 0;
  const strip = (text: string): string => {
    if (!targets.length) return text;
    const kept = splitSentences(text).filter((sent) => {
      const n = norm(sent);
      const hit = targets.some((t) => n === t || n.includes(t) || (t.includes(n) && n.length >= 20));
      if (hit) removed++;
      return !hit;
    });
    return kept.join(" ");
  };
  const out: Article = structuredClone(a);
  out.summary = out.summary.map(strip).filter((x) => x.trim());
  out.perspectives.a.body = strip(out.perspectives.a.body);
  out.perspectives.b.body = strip(out.perspectives.b.body);
  out.agree = strip(out.agree);
  out.local_angle = strip(out.local_angle);
  out.context = out.context ? strip(out.context) : out.context;
  out.watch_next = strip(out.watch_next);
  return { article: out, removed };
}

/** Same schema check as the site build (gate 0). */
export function checkSchema(a: Article): string | null {
  const slug = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
  if (!a || typeof a !== "object") return "not an object";
  if (!slug.test(a.slug ?? "")) return "bad or missing slug";
  if (a.country !== "usa" && a.country !== "india") return "country must be usa or india";
  if (!a.headline?.trim()) return "missing headline";
  if (!Array.isArray(a.summary) || a.summary.length < 1 || a.summary.length > 3) {
    return "summary must have 1 to 3 lines";
  }
  if (!a.perspectives?.a?.body || !a.perspectives?.b?.body) return "missing perspectives";
  if (!Array.isArray(a.places) || !a.places.length || a.places.some((p) => !slug.test(p.slug))) {
    return "missing or bad places";
  }
  if (!Array.isArray(a.sources)) return "missing sources";
  if (Number.isNaN(Date.parse(a.published_at))) return "bad published_at";
  if (!a.checks) return "missing checks";
  return null;
}
