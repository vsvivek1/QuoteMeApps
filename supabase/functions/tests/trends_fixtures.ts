// Shared fixtures for the trends pipeline tests (not a test file itself).
import { DEFAULT_SETTINGS } from "../_shared/trends/settings.ts";
import type { Settings, Signal, Topic } from "../_shared/trends/types.ts";

export const NOW = new Date("2026-10-02T15:00:00Z");
export const iso = (minsAgo: number) => new Date(NOW.getTime() - minsAgo * 60_000).toISOString();

export function settings(over: Partial<Settings> = {}): Settings {
  return { ...structuredClone(DEFAULT_SETTINGS), ...over };
}

export const topic: Topic = {
  id: "7f3c2a10-0000-4000-8000-000000000001",
  country: "usa",
  place_slug: "chicago",
  place_name: "Chicago",
  state: "Illinois",
  level: "metro",
  title: "Chicago first snow",
  norm_title: "chicago first snow",
  alt_titles: [],
  status: "fired",
  velocity: 82,
  peak_velocity: 82,
  signal_count: 4,
  domain_count: 2,
  domains: ["forecast.example.com", "metro.example.net"],
  domains_at_reject: null,
  first_seen: iso(90),
  last_seen: iso(5),
  fired_at: iso(10),
  ended_at: null,
  article_slug: null,
};

export function sig(p: Partial<Signal> & { topic: string }): Signal {
  return {
    source_kind: "google_news",
    url: null,
    publisher: null,
    publisher_domain: null,
    citable: false,
    snippet: null,
    score: 0,
    first_seen: iso(30),
    last_seen: iso(5),
    ...p,
  };
}

export const signals: Signal[] = [
  sig({ source_kind: "google_trends", topic: "chicago first snow", score: 20000, first_seen: iso(50) }),
  sig({
    topic: "First snow expected in the city by the weekend",
    url: "https://forecast.example.com/chicago-snow",
    publisher: "Example Forecast",
    publisher_domain: "forecast.example.com",
    citable: true,
    snippet: "Forecasters expect several inches of snow in the city by the weekend.",
  }),
  sig({
    topic: "Hardware stores see a rush on snow blowers",
    url: "https://metro.example.net/chicago-stores",
    publisher: "Example Metro",
    publisher_domain: "metro.example.net",
    citable: true,
    snippet: "Hardware stores reported more interest in snow blowers this week.",
  }),
  sig({
    topic: "Snow day ahead for Chicago",
    url: "https://news.google.com/rss/articles/abc",
    publisher: "Some Paper",
    publisher_domain: "somepaper.example.org",
    citable: false,
  }),
];

const A_BODY =
  "In the next few days the priority is getting through the storm safely and warmly. That means checking that the furnace starts, that there is a working shovel or blower, and that driveways and sidewalks can be cleared. Demand spikes can mean longer waits for repairs and higher prices for last-minute equipment, so people who act early usually get better availability and choice. Comparing a few quotes for a furnace check can still be done quickly, and neighbours often share the work of clearing shared paths before the first heavy fall arrives in earnest.";
const B_BODY =
  "Over the full winter, the bigger costs come from heating efficiency and wear. A furnace that is serviced and running well can lower monthly bills, and sealing drafts or adding insulation pays off across many storms rather than one. Seasonal snow removal contracts can cost less per visit than one-off calls. Households that plan their winter upkeep in advance tend to spend less overall and face fewer emergency repairs during the coldest weeks, which matters most for older buildings with original equipment and thin windows.";

export const modelArticle = {
  headline: "Chicago gets ready for the season's first heavy snow",
  summary: [
    "Forecasters cited by local outlets say a significant snowfall could reach the city before the weekend.",
    "One report says hardware stores are fielding more questions about snow blowers this week.",
    "Residents are weighing quick storm preparations against longer-term winter planning.",
  ],
  framing: "Short-term vs Long-term",
  perspective_a: { label: "Short-term", body: A_BODY },
  perspective_b: { label: "Long-term", body: B_BODY },
  agree:
    "Both views agree that acting before the storm is cheaper and less stressful than reacting during it, and that clear, comparable quotes help people decide quickly.",
  context:
    "The first heavy snow of the season usually brings a rush of furnace tune-ups, snow removal contracts and equipment purchases, because many people put these off until the weather forces the issue.",
  local_angle:
    "In Chicago, older homes with original heating systems are especially exposed to first-cold-snap failures, and many neighborhoods rely on residents to clear their own sidewalks.",
  watch_next:
    "Watch the updated snowfall totals from the weather service and any city parking restrictions on snow routes. If the cold lasts into next week, demand for heating repairs is likely to stay high.",
  topic_tags: ["weather", "home"],
};

export type ModelReplies = {
  article?: unknown[]; // consumed in order (draft, rewrite, ...)
  facts?: unknown;
  balance?: unknown;
  update?: unknown;
  refuse?: boolean;
};

/** A fetch mock standing in for the Claude Messages API; records every request body. */
export function claudeFetch(replies: ModelReplies) {
  const calls: { url: string; headers: Headers; body: Record<string, unknown>; kind: string }[] = [];
  const articles = [...(replies.article ?? [modelArticle])];
  const f = (input: string | URL | Request, init?: RequestInit): Promise<Response> => {
    const url = String(input instanceof Request ? input.url : input);
    const body = JSON.parse(String(init?.body ?? "{}"));
    const system = String(body.system ?? "");
    const kind = system.includes("strict fact checker")
      ? "facts"
      : system.includes("for balance")
      ? "balance"
      : system.includes("maintain a published")
      ? "update"
      : "article";
    calls.push({ url, headers: new Headers(init?.headers), body, kind });
    if (replies.refuse) {
      return Promise.resolve(
        Response.json({ stop_reason: "refusal", stop_details: { category: "general_harms" }, content: [] }),
      );
    }
    const payload = kind === "facts"
      ? replies.facts ?? { unsupported_sentences: [], conflicts: false, conflict_notes: "" }
      : kind === "balance"
      ? replies.balance ?? { balanced: true, weaker_side: "none", loaded_terms: [], reason: "even" }
      : kind === "update"
      ? replies.update ?? { has_update: false, update_text: "", has_correction: false, correction_text: "" }
      : (articles.length > 1 ? articles.shift() : articles[0]);
    return Promise.resolve(Response.json({
      model: body.model,
      stop_reason: "end_turn",
      content: [{ type: "thinking", thinking: "" }, { type: "text", text: JSON.stringify(payload) }],
    }));
  };
  return { fetch: f as typeof fetch, calls };
}
