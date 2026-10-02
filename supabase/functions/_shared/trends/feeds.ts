// Feed fetchers and parsers for trends-poll. Only headlines, links and the short
// snippets the feeds themselves carry are read; article pages are never fetched.
//
//   Google Trends  https://trends.google.com/trending/rss?geo=IN | IN-MH | US | US-CA ...
//   Google News    https://news.google.com/rss/search?q=<place>+when:1d&hl=..&gl=..&ceid=..
//   Reddit         official OAuth API (client credentials), /r/<sub>/rising — only when
//                  REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET are set
import { baseDomain, clip, decodeEntities, hostOf, normalizeTitle, stripTags } from "./text.ts";
import type { SignalInput, TrendSource } from "./types.ts";

export type FetchFn = typeof fetch;

export const USER_AGENT = "TrendsPipeline/1.0 (headline monitor; +https://trends-site.example/about)";
const SNIPPET_MAX = 300;

function tag(xml: string, name: string): string | null {
  const re = new RegExp(
    `<${name.replace(/[:]/g, "\\:")}(?:\\s[^>]*)?>([\\s\\S]*?)</${name.replace(/[:]/g, "\\:")}>`,
    "i",
  );
  const m = re.exec(xml);
  return m ? decodeEntities(m[1]).trim() : null;
}

function attr(xml: string, name: string, attribute: string): string | null {
  const m = new RegExp(`<${name}\\s[^>]*${attribute}="([^"]*)"`, "i").exec(xml);
  return m ? decodeEntities(m[1]) : null;
}

function blocks(xml: string, name: string): string[] {
  const out: string[] = [];
  const re = new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, "gi");
  let m: RegExpExecArray | null;
  while ((m = re.exec(xml))) out.push(m[1]);
  return out;
}

const httpUrl = (u: string | null): string | null => (u && /^https?:\/\//i.test(u) ? u : null);

export interface TrendsItem {
  title: string;
  approxTraffic: number;
  pubDate: string | null;
  news: { title: string; url: string | null; source: string | null; snippet: string | null }[];
}

/** "20,000+" / "2K+" / "1M+" -> number. */
export function parseTraffic(s: string | null): number {
  if (!s) return 0;
  const m = /([\d.,]+)\s*([KkMm])?/.exec(s);
  if (!m) return 0;
  const n = Number(m[1].replace(/,/g, ""));
  const mult = m[2] ? (m[2].toLowerCase() === "k" ? 1e3 : 1e6) : 1;
  return Number.isFinite(n) ? n * mult : 0;
}

export function parseGoogleTrendsRss(xml: string): TrendsItem[] {
  return blocks(xml, "item").map((it) => ({
    title: stripTags(tag(it, "title") ?? ""),
    approxTraffic: parseTraffic(tag(it, "ht:approx_traffic")),
    pubDate: tag(it, "pubDate"),
    news: blocks(it, "ht:news_item").map((n) => ({
      title: stripTags(tag(n, "ht:news_item_title") ?? ""),
      url: httpUrl(tag(n, "ht:news_item_url")),
      source: tag(n, "ht:news_item_source"),
      snippet: tag(n, "ht:news_item_snippet")
        ? clip(stripTags(tag(n, "ht:news_item_snippet")!), SNIPPET_MAX)
        : null,
    })).filter((n) => n.title),
  })).filter((i) => i.title);
}

export interface NewsItem {
  title: string;
  url: string | null;
  publisher: string | null;
  publisherDomain: string | null;
  snippet: string | null;
  pubDate: string | null;
}

export function parseGoogleNewsRss(xml: string): NewsItem[] {
  return blocks(xml, "item").map((it) => {
    const publisher = tag(it, "source");
    const publisherUrl = attr(it, "source", "url");
    const rawTitle = stripTags(tag(it, "title") ?? "");
    const title = publisher && rawTitle.endsWith(` - ${publisher}`)
      ? rawTitle.slice(0, -(publisher.length + 3))
      : rawTitle;
    let snippet = decodeEntities(stripTags(tag(it, "description") ?? "")).replace(/\s+/g, " ").trim();
    if (publisher && snippet.endsWith(publisher)) snippet = snippet.slice(0, -publisher.length).trim();
    if (snippet === title || snippet === rawTitle) snippet = "";
    return {
      title,
      url: httpUrl(tag(it, "link")),
      publisher,
      publisherDomain: publisherUrl ? hostOf(publisherUrl) || null : null,
      snippet: snippet ? clip(snippet, SNIPPET_MAX) : null,
      pubDate: tag(it, "pubDate"),
    };
  }).filter((i) => i.title);
}

export interface RedditPost {
  title: string;
  permalink: string;
  domain: string;
  score: number;
  isSelf: boolean;
}

export function parseRedditListing(json: unknown): RedditPost[] {
  const children = (json as { data?: { children?: { data?: Record<string, unknown> }[] } })?.data?.children ??
    [];
  return children.map((c) => c.data ?? {}).filter((d) =>
    !d.over_18 && !d.stickied && typeof d.title === "string"
  )
    .map((d) => ({
      title: String(d.title),
      permalink: `https://www.reddit.com${String(d.permalink ?? "")}`,
      domain: String(d.domain ?? "reddit.com"),
      score: Number(d.score ?? 0) || 0,
      isSelf: Boolean(d.is_self),
    }));
}

export function googleTrendsUrl(geo: string): string {
  return `https://trends.google.com/trending/rss?geo=${encodeURIComponent(geo)}`;
}

export function googleNewsUrl(query: string, country: "usa" | "india"): string {
  const loc = country === "india"
    ? { hl: "en-IN", gl: "IN", ceid: "IN:en" }
    : { hl: "en-US", gl: "US", ceid: "US:en" };
  const q = encodeURIComponent(`${query} when:1d`);
  return `https://news.google.com/rss/search?q=${q}&hl=${loc.hl}&gl=${loc.gl}&ceid=${loc.ceid}`;
}

/** A link counts as citable only when it is on the publisher's own domain (not a redirect). */
export function isCitable(
  url: string | null,
  publisherDomain: string | null,
  nonPublisher: string[],
): boolean {
  const h = hostOf(url);
  if (!h || !publisherDomain) return false;
  if (nonPublisher.some((d) => h === d || h.endsWith(`.${d}`))) return false;
  return baseDomain(h) === baseDomain(publisherDomain);
}

const base = (s: TrendSource) => ({
  source_id: s.id,
  source_kind: s.kind,
  country: s.country,
  place_slug: s.place_slug,
  place_name: s.place_name,
  state: s.state,
  level: s.level,
  geo: s.geo,
});

export function signalsFromTrends(
  src: TrendSource,
  items: TrendsItem[],
  nonPublisher: string[],
): SignalInput[] {
  const out: SignalInput[] = [];
  for (const it of items) {
    const norm = normalizeTitle(it.title);
    if (!norm) continue;
    out.push({
      ...base(src),
      topic: clip(it.title, 400),
      norm_title: norm,
      dedupe_key: `trend:${norm}`,
      url: null,
      publisher: null,
      publisher_domain: null,
      citable: false,
      snippet: null,
      score: it.approxTraffic,
      cluster_hint: norm,
    });
    for (const n of it.news) {
      const domain = hostOf(n.url) || null;
      const nnorm = normalizeTitle(n.title, n.source);
      if (!nnorm) continue;
      out.push({
        ...base(src),
        topic: clip(n.title, 400),
        norm_title: nnorm,
        dedupe_key: n.url ?? `title:${nnorm}`,
        url: n.url,
        publisher: n.source,
        publisher_domain: domain ? baseDomain(domain) : null,
        citable: isCitable(n.url, domain, nonPublisher),
        snippet: n.snippet,
        score: 0,
        cluster_hint: norm,
      });
    }
  }
  return out;
}

export function signalsFromNews(src: TrendSource, items: NewsItem[], nonPublisher: string[]): SignalInput[] {
  return items.map((n) => {
    const norm = normalizeTitle(n.title, n.publisher);
    return {
      ...base(src),
      topic: clip(n.title, 400),
      norm_title: norm,
      dedupe_key: n.url ?? `title:${norm}`,
      url: n.url,
      publisher: n.publisher,
      publisher_domain: n.publisherDomain ? baseDomain(n.publisherDomain) : null,
      citable: isCitable(n.url, n.publisherDomain, nonPublisher),
      snippet: n.snippet,
      score: 0,
    };
  }).filter((s) => s.norm_title);
}

export function signalsFromReddit(src: TrendSource, posts: RedditPost[]): SignalInput[] {
  return posts.map((p) => {
    const norm = normalizeTitle(p.title);
    // Reddit is a detection signal only: never a citable publisher.
    return {
      ...base(src),
      topic: clip(p.title, 400),
      norm_title: norm,
      dedupe_key: p.permalink,
      url: p.permalink,
      publisher: `r/${src.query}`,
      publisher_domain: "reddit.com",
      citable: false,
      snippet: null,
      score: p.score,
    };
  }).filter((s) => s.norm_title);
}

async function getText(fetchFn: FetchFn, url: string, init: RequestInit = {}): Promise<string> {
  const res = await fetchFn(url, {
    ...init,
    headers: {
      "User-Agent": USER_AGENT,
      Accept: "application/rss+xml, application/xml, application/json",
      ...init.headers,
    },
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) {
    await res.body?.cancel();
    throw new Error(`http_${res.status}`);
  }
  const text = await res.text();
  if (text.length > 2_000_000) throw new Error("feed_too_large");
  return text;
}

export interface RedditCreds {
  clientId: string;
  clientSecret: string;
  userAgent: string;
}

let redditToken: { token: string; exp: number } | null = null;

export async function redditAccessToken(
  fetchFn: FetchFn,
  creds: RedditCreds,
  now = Date.now(),
): Promise<string> {
  if (redditToken && redditToken.exp > now + 60_000) return redditToken.token;
  const res = await fetchFn("https://www.reddit.com/api/v1/access_token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${creds.clientId}:${creds.clientSecret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": creds.userAgent,
    },
    body: "grant_type=client_credentials",
    signal: AbortSignal.timeout(10_000),
  });
  if (!res.ok) throw new Error(`reddit_auth_${res.status}`);
  const j = await res.json() as { access_token?: string; expires_in?: number };
  if (!j.access_token) throw new Error("reddit_auth_no_token");
  redditToken = { token: j.access_token, exp: now + (j.expires_in ?? 3600) * 1000 };
  return j.access_token;
}

export function resetRedditToken() {
  redditToken = null;
}

/** Polls one source and returns its signals. Reddit sources return [] without credentials. */
export async function pollSource(
  src: TrendSource,
  deps: { fetch: FetchFn; reddit: RedditCreds | null; nonPublisher: string[] },
): Promise<{ signals: SignalInput[]; skipped?: string }> {
  if (src.kind === "google_trends") {
    const xml = await getText(deps.fetch, googleTrendsUrl(src.geo));
    return { signals: signalsFromTrends(src, parseGoogleTrendsRss(xml), deps.nonPublisher) };
  }
  if (src.kind === "google_news") {
    const xml = await getText(deps.fetch, googleNewsUrl(src.query ?? src.place_name, src.country));
    return { signals: signalsFromNews(src, parseGoogleNewsRss(xml), deps.nonPublisher) };
  }
  if (!deps.reddit) return { signals: [], skipped: "reddit_not_configured" };
  if (!/^[A-Za-z0-9_]{2,21}$/.test(src.query ?? "")) return { signals: [], skipped: "invalid_subreddit" };
  const token = await redditAccessToken(deps.fetch, deps.reddit);
  const body = await getText(
    deps.fetch,
    `https://oauth.reddit.com/r/${src.query}/rising?limit=25&raw_json=1`,
    {
      headers: { Authorization: `Bearer ${token}`, "User-Agent": deps.reddit.userAgent },
    },
  );
  return { signals: signalsFromReddit(src, parseRedditListing(JSON.parse(body))) };
}
