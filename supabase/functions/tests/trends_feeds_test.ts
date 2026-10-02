// Trends pipeline: feed parsing (Google Trends RSS, Google News RSS, Reddit) with mocked fetch.
import { assert, assertEquals } from "@std/assert";
import {
  googleNewsUrl,
  googleTrendsUrl,
  isCitable,
  parseGoogleNewsRss,
  parseGoogleTrendsRss,
  parseTraffic,
  pollSource,
  resetRedditToken,
} from "../_shared/trends/feeds.ts";
import type { TrendSource } from "../_shared/trends/types.ts";
import { settings } from "./trends_fixtures.ts";

const nonPub = settings().detection.non_publisher_domains;

const TRENDS_XML = `<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:atom="http://www.w3.org/2005/Atom" xmlns:ht="https://trends.google.com/trending/rss" version="2.0"><channel>
<item>
  <title>pune rains</title>
  <ht:approx_traffic>20,000+</ht:approx_traffic>
  <pubDate>Fri, 2 Oct 2026 09:00:00 +0530</pubDate>
  <ht:news_item>
    <ht:news_item_title><![CDATA[Heavy rain lashes Pune, IMD issues &quot;orange&quot; alert]]></ht:news_item_title>
    <ht:news_item_snippet>Showers are expected to continue through the evening.</ht:news_item_snippet>
    <ht:news_item_url>https://www.hindustantimes.com/cities/pune-news/rain-123.html</ht:news_item_url>
    <ht:news_item_source>Hindustan Times</ht:news_item_source>
  </ht:news_item>
  <ht:news_item>
    <ht:news_item_title>Pune rain: traffic slows on key roads</ht:news_item_title>
    <ht:news_item_url>https://timesofindia.indiatimes.com/city/pune/rain/456.cms</ht:news_item_url>
    <ht:news_item_source>Times of India</ht:news_item_source>
  </ht:news_item>
</item>
<item><title>cricket score</title><ht:approx_traffic>2K+</ht:approx_traffic></item>
</channel></rss>`;

const NEWS_XML = `<rss version="2.0"><channel>
<item>
  <title>Pune metro line 3 opens to public - The Hindu</title>
  <link>https://news.google.com/rss/articles/CBMiXYZ?oc=5</link>
  <pubDate>Fri, 02 Oct 2026 07:00:00 GMT</pubDate>
  <description>&lt;a href="https://news.google.com/rss/articles/CBMiXYZ"&gt;Pune metro line 3 opens to public&lt;/a&gt;&amp;nbsp;&amp;nbsp;&lt;font color="#6f6f6f"&gt;The Hindu&lt;/font&gt;</description>
  <source url="https://www.thehindu.com">The Hindu</source>
</item>
</channel></rss>`;

const src = (kind: TrendSource["kind"], query: string | null = null): TrendSource => ({
  id: 7,
  kind,
  country: "india",
  geo: "IN-MH",
  place_slug: "pune",
  place_name: "Pune",
  state: "Maharashtra",
  level: "metro",
  query,
});

Deno.test("Google Trends RSS: titles, traffic, news items (entities and CDATA decoded)", () => {
  const items = parseGoogleTrendsRss(TRENDS_XML);
  assertEquals(items.length, 2);
  assertEquals(items[0].title, "pune rains");
  assertEquals(items[0].approxTraffic, 20000);
  assertEquals(items[0].news.length, 2);
  assertEquals(items[0].news[0].title, 'Heavy rain lashes Pune, IMD issues "orange" alert');
  assertEquals(items[0].news[0].source, "Hindustan Times");
  assertEquals(items[1].approxTraffic, 2000);
  assertEquals(parseTraffic("1M+"), 1_000_000);
});

Deno.test("Google News RSS: headline without publisher suffix, publisher domain, no copied body", () => {
  const items = parseGoogleNewsRss(NEWS_XML);
  assertEquals(items.length, 1);
  assertEquals(items[0].title, "Pune metro line 3 opens to public");
  assertEquals(items[0].publisherDomain, "thehindu.com");
  assertEquals(items[0].snippet, null); // the description only repeats the headline
  assert(googleNewsUrl("Pune", "india").includes("gl=IN"));
  assert(googleTrendsUrl("IN-MH").endsWith("geo=IN-MH"));
});

Deno.test("citable only when the link is on the publisher's own domain", () => {
  assert(isCitable("https://www.hindustantimes.com/x", "hindustantimes.com", nonPub));
  assert(isCitable("https://timesofindia.indiatimes.com/x", "indiatimes.com", nonPub));
  assert(!isCitable("https://news.google.com/rss/articles/abc", "thehindu.com", nonPub)); // redirect link
  assert(!isCitable("https://www.reddit.com/r/pune/x", "reddit.com", nonPub));
  assert(!isCitable(null, "a.com", nonPub));
});

Deno.test("pollSource: trends + news signals; reddit skipped without credentials (no request)", async () => {
  const requested: string[] = [];
  const fetchMock = ((u: string | URL | Request) => {
    const url = String(u);
    requested.push(url);
    return Promise.resolve(new Response(url.includes("trends.google.com") ? TRENDS_XML : NEWS_XML));
  }) as typeof fetch;
  const t = await pollSource(src("google_trends"), { fetch: fetchMock, reddit: null, nonPublisher: nonPub });
  assertEquals(t.signals.length, 4); // 2 trends + 2 news items
  const trend = t.signals.find((s) => !s.url)!;
  assertEquals(trend.cluster_hint, "pune rains");
  assertEquals(trend.score, 20000);
  const news = t.signals.filter((s) => s.url);
  assert(news.every((s) => s.citable && s.cluster_hint === "pune rains"));
  assertEquals(news.map((s) => s.publisher_domain).sort(), ["hindustantimes.com", "indiatimes.com"]);

  const n = await pollSource(src("google_news", "Pune"), {
    fetch: fetchMock,
    reddit: null,
    nonPublisher: nonPub,
  });
  assertEquals(n.signals.length, 1);
  assertEquals(n.signals[0].citable, false); // Google News links are redirects: detection only

  const before = requested.length;
  const r = await pollSource(src("reddit", "pune"), { fetch: fetchMock, reddit: null, nonPublisher: nonPub });
  assertEquals(r, { signals: [], skipped: "reddit_not_configured" });
  assertEquals(requested.length, before);
});

Deno.test("pollSource: reddit through the official OAuth API when configured", async () => {
  resetRedditToken();
  const calls: { url: string; init?: RequestInit }[] = [];
  const fetchMock = ((u: string | URL | Request, init?: RequestInit) => {
    const url = String(u);
    calls.push({ url, init });
    if (url.endsWith("/api/v1/access_token")) {
      return Promise.resolve(Response.json({ access_token: "tok", expires_in: 3600 }));
    }
    return Promise.resolve(Response.json({
      data: {
        children: [
          {
            data: {
              title: "Power cut in Kothrud since morning",
              permalink: "/r/pune/comments/1/x/",
              domain: "self.pune",
              score: 120,
              is_self: true,
            },
          },
          { data: { title: "NSFW thing", permalink: "/r/pune/comments/2/", over_18: true } },
        ],
      },
    }));
  }) as typeof fetch;
  const r = await pollSource(src("reddit", "pune"), {
    fetch: fetchMock,
    reddit: { clientId: "id", clientSecret: "secret", userAgent: "ua" },
    nonPublisher: nonPub,
  });
  assertEquals(r.signals.length, 1);
  assertEquals(r.signals[0].citable, false);
  assertEquals(r.signals[0].publisher_domain, "reddit.com");
  assertEquals(calls[1].url, "https://oauth.reddit.com/r/pune/rising?limit=25&raw_json=1");
  assertEquals(new Headers(calls[1].init?.headers).get("Authorization"), "Bearer tok");
  assertEquals(new Headers(calls[0].init?.headers).get("Authorization"), `Basic ${btoa("id:secret")}`);
});

Deno.test("pollSource: HTTP errors surface (the source is marked error, the run continues)", async () => {
  const fetchMock = (() => Promise.resolve(new Response("nope", { status: 429 }))) as typeof fetch;
  let err = "";
  try {
    await pollSource(src("google_trends"), { fetch: fetchMock, reddit: null, nonPublisher: nonPub });
  } catch (e) {
    err = (e as Error).message;
  }
  assertEquals(err, "http_429");
});
