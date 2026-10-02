// Minimal Claude Messages API client (raw fetch, no SDK) for the trends pipeline.
//   POST https://api.anthropic.com/v1/messages
//   model:  ANTHROPIC_MODEL (default "claude-sonnet-5-5"), key: ANTHROPIC_API_KEY
// Responses are constrained to a JSON schema with structured outputs (output_config.format).
// Server-side refusal fallback ("fallbacks": "default") is on, so a request a safety classifier
// declines is retried on Anthropic's recommended fallback model; a final refusal throws.

export type FetchFn = typeof fetch;

export const DEFAULT_MODEL = "claude-sonnet-5-5";
const API_URL = "https://api.anthropic.com/v1/messages";

export class ClaudeError extends Error {
  constructor(public code: string, public status?: number, message?: string) {
    super(message ?? code);
  }
}

export interface ClaudeConfig {
  apiKey: string;
  model: string;
  fetch: FetchFn;
  effort?: "low" | "medium" | "high";
  maxTokens?: number;
}

export interface JsonCall {
  system: string;
  user: string;
  schema: Record<string, unknown>;
  maxTokens?: number;
}

export interface Claude {
  model: string;
  json<T>(call: JsonCall): Promise<T>;
}

export function claudeFromEnv(
  get: (k: string) => string | undefined,
  fetchFn: FetchFn = fetch,
): Claude | null {
  const apiKey = get("ANTHROPIC_API_KEY");
  if (!apiKey) return null;
  return makeClaude({ apiKey, model: get("ANTHROPIC_MODEL") || DEFAULT_MODEL, fetch: fetchFn });
}

export function makeClaude(cfg: ClaudeConfig): Claude {
  return {
    model: cfg.model,
    async json<T>(call: JsonCall): Promise<T> {
      const body = {
        model: cfg.model,
        max_tokens: call.maxTokens ?? cfg.maxTokens ?? 8000,
        system: call.system,
        messages: [{ role: "user", content: call.user }],
        output_config: {
          effort: cfg.effort ?? "medium",
          format: { type: "json_schema", schema: call.schema },
        },
        fallbacks: "default",
      };
      let res: Response | undefined;
      for (let attempt = 0; attempt < 3; attempt++) {
        res = await cfg.fetch(API_URL, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-api-key": cfg.apiKey,
            "anthropic-version": "2023-06-01",
            "anthropic-beta": "server-side-fallback-2026-07-01",
          },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(120_000),
        });
        if (res.status !== 429 && res.status < 500) break;
        await res.body?.cancel();
        const retryAfter = Number(res.headers.get("retry-after") ?? "");
        await new Promise((r) =>
          setTimeout(
            r,
            Number.isFinite(retryAfter) && retryAfter > 0
              ? Math.min(retryAfter, 10) * 1000
              : 1000 * (attempt + 1),
          )
        );
      }
      if (!res!.ok) {
        const text = await res!.text().catch(() => "");
        throw new ClaudeError("claude_http_error", res!.status, `${res!.status} ${text.slice(0, 300)}`);
      }
      const msg = await res!.json() as {
        stop_reason?: string;
        stop_details?: { category?: string | null } | null;
        content?: { type: string; text?: string }[];
      };
      if (msg.stop_reason === "refusal") {
        throw new ClaudeError("claude_refusal", 200, msg.stop_details?.category ?? "refusal");
      }
      if (msg.stop_reason === "max_tokens") throw new ClaudeError("claude_max_tokens");
      const text = (msg.content ?? []).filter((b) => b.type === "text").map((b) => b.text ?? "").join("");
      return parseJsonText<T>(text);
    },
  };
}

export function parseJsonText<T>(text: string): T {
  const t = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "");
  try {
    return JSON.parse(t) as T;
  } catch {
    const start = t.indexOf("{");
    const end = t.lastIndexOf("}");
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(t.slice(start, end + 1)) as T;
      } catch { /* fallthrough */ }
    }
    throw new ClaudeError("claude_invalid_json");
  }
}
