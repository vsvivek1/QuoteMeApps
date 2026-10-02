// Text helpers shared by the trends pipeline. words / shingles / containment are
// byte-for-byte the same rules as web/trends_site/src/lib/articles.ts, so the
// pipeline and the site build agree on word counts and overlap.

export const words = (s = ""): number => (s.match(/[\p{L}\p{N}][\p{L}\p{N}'’-]*/gu) ?? []).length;
export const tokens = (s = ""): string[] => s.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? [];

export function shingles(s: string, n: number): Set<string> {
  const t = tokens(s);
  const out = new Set<string>();
  for (let i = 0; i + n <= t.length; i++) out.add(t.slice(i, i + n).join(" "));
  return out;
}

/** Share of a source text's n-grams that reappear in the draft (containment). */
export function containment(draft: Set<string>, source: string, n: number): number {
  const s = shingles(source, n);
  if (s.size === 0) return 0;
  let hit = 0;
  for (const g of s) if (draft.has(g)) hit++;
  return hit / s.size;
}

/** The source n-grams that reappear in the draft (for the rewrite prompt). */
export function overlappingPhrases(draftText: string, source: string, n: number, max = 8): string[] {
  const d = shingles(draftText, n);
  const out: string[] = [];
  for (const g of shingles(source, n)) {
    if (d.has(g)) out.push(g);
    if (out.length >= max) break;
  }
  return out;
}

export function hostOf(u: string | null | undefined): string {
  if (!u) return "";
  try {
    return new URL(u).hostname.replace(/^www\./, "").toLowerCase();
  } catch {
    return "";
  }
}

/** Registrable-ish domain: last two labels, or three for co.in / com.au style suffixes. */
export function baseDomain(host: string): string {
  const parts = host.toLowerCase().replace(/^www\./, "").split(".").filter(Boolean);
  if (parts.length <= 2) return parts.join(".");
  const sld = parts[parts.length - 2];
  const twoLevel = ["co", "com", "net", "org", "gov", "ac", "edu", "nic"].includes(sld) &&
    parts.at(-1)!.length === 2;
  return parts.slice(twoLevel ? -3 : -2).join(".");
}

export function wordRe(list: string[]): RegExp | null {
  if (!list.length) return null;
  const esc = list.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\s+/g, "\\s+"));
  return new RegExp(`\\b(${esc.join("|")})\\b`, "i");
}

const STOPWORDS = new Set(
  ("a an the and or but of to in on at for from by with as is are was were be been has have had it its this that " +
    "these those after before over under into about amid near new news live latest today update updates says say " +
    "said what why how who when where will can may could would should vs v his her their our your my not no more " +
    "than up down out off all any some just also very").split(" "),
);

/** Lower-case, strip a trailing " - Publisher" / " | Publisher", keep letters and digits. */
export function normalizeTitle(title: string, publisher?: string | null): string {
  let t = title.trim();
  if (publisher) {
    const p = publisher.trim().toLowerCase();
    const m = /\s+[-–—|:]\s+([^-–—|:]+)$/.exec(t);
    if (m && m[1].trim().toLowerCase() === p) t = t.slice(0, m.index);
  }
  return tokens(t.normalize("NFKD").replace(/\p{M}/gu, "")).join(" ");
}

export function titleTokens(norm: string): Set<string> {
  return new Set(norm.split(" ").filter((w) => w.length > 1 && !STOPWORDS.has(w)));
}

/**
 * Similarity of two normalised titles: the larger of Jaccard and containment of the shorter
 * title (when it shares two content words, or is a single word), so a short trend query ("ipl final")
 * matches the long headlines about it. Words in `ignore` (the place name) do not count: every
 * headline of a place mentions it.
 */
export function titleSimilarity(a: string, b: string, ignore: Set<string> = new Set()): number {
  const A = new Set([...titleTokens(a)].filter((w) => !ignore.has(w)));
  const B = new Set([...titleTokens(b)].filter((w) => !ignore.has(w)));
  if (!A.size || !B.size) return 0;
  let inter = 0;
  for (const w of A) if (B.has(w)) inter++;
  const jaccard = inter / (A.size + B.size - inter);
  const small = Math.min(A.size, B.size);
  const contain = inter >= 2 || (small === 1 && inter === 1) ? inter / small : 0;
  return Math.max(jaccard, contain);
}

export function slugify(s: string, max = 80): string {
  const base = tokens(s.normalize("NFKD").replace(/\p{M}/gu, "")).filter((w) => /^[a-z0-9]+$/.test(w)).join(
    "-",
  );
  if (base.length <= max) return base || "story";
  const cut = base.slice(0, max);
  return (cut.includes("-") && base[max] !== "-" ? cut.slice(0, cut.lastIndexOf("-")) : cut) || "story";
}

export function decodeEntities(s: string): string {
  return s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&nbsp;/g, " ")
    .replace(/&quot;/g, '"')
    .replace(/&apos;|&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&");
}

export function stripTags(s: string): string {
  return s.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
}

/** Cuts at a word boundary; feeds give headlines and short snippets only, never bodies. */
export function clip(s: string, max: number): string {
  const t = s.replace(/\s+/g, " ").trim();
  if (t.length <= max) return t;
  const cut = t.slice(0, max - 1);
  return cut.slice(0, Math.max(cut.lastIndexOf(" "), max * 0.6)).trimEnd() + "…";
}

export function splitSentences(s: string): string[] {
  return s.match(/[^.!?]+(?:[.!?]+["”’)]?|$)/g)?.map((x) => x.trim()).filter(Boolean) ?? [];
}
