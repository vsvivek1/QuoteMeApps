// CORS, JSON responses and the shared error convention.
//
// Error body (same shape as PostgREST errors raised by the RPCs, so the
// Flutter client has one parser):
//   { "code": "stable_snake_case_code", "message": "...", "details": ..., "hint": ... }
// HTTP status carries the class (400/401/403/404/409/422/429/500).

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-firebase-appcheck, x-webhook-secret",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

export class HttpError extends Error {
  constructor(
    public status: number,
    public code: string,
    public details?: unknown,
    public hint?: string,
  ) {
    super(code);
  }
}

export function json(data: unknown, status = 200, extraHeaders: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8", ...extraHeaders },
  });
}

export function errorResponse(status: number, code: string, details?: unknown, hint?: string): Response {
  return json({ code, message: code, details: details ?? null, hint: hint ?? null }, status);
}

/** Maps a PostgREST / RPC error (SQLSTATE PTnnn -> HTTP nnn, message = code) to an HttpError. */
export function fromPostgrestError(err: { code?: string; message?: string; details?: unknown; hint?: string }) {
  const m = /^PT(\d{3})$/.exec(err.code ?? "");
  const status = m ? Number(m[1]) : err.code === "42501" ? 403 : 500;
  return new HttpError(status, err.message ?? "database_error", err.details, err.hint ?? undefined);
}

/** Wraps a handler: CORS preflight, JSON errors, no stack traces leaked. */
export function serve(handler: (req: Request) => Promise<Response>) {
  Deno.serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
      return await handler(req);
    } catch (e) {
      if (e instanceof HttpError) return errorResponse(e.status, e.code, e.details, e.hint);
      console.error("unhandled", e);
      return errorResponse(500, "internal_error");
    }
  });
}

export async function readJson<T = Record<string, unknown>>(req: Request): Promise<T> {
  const text = await req.text();
  if (!text) return {} as T;
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new HttpError(400, "invalid_json");
  }
}

export function requireMethod(req: Request, ...methods: string[]) {
  if (!methods.includes(req.method)) throw new HttpError(405, "method_not_allowed");
}
