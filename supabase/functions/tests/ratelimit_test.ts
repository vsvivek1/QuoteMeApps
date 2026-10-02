import { assertEquals } from "@std/assert";
import { rateLimit, rateLimitKey } from "../_shared/ratelimit.ts";

Deno.test("rate-limit key is stable, scoped and normalised", () => {
  assertEquals(rateLimitKey("create-checkout", "User-ABC", "IN"), "iwant:in:create-checkout:user-abc");
  assertEquals(rateLimitKey("web forms!", " 203.0.113.9, 10.0.0.1 ", "US"), "iwant:us:web_forms_:203.0.113.9");
  assertEquals(rateLimitKey("x", "", "US"), "iwant:us:x:anonymous");
});

Deno.test("rate limit is a no-op without Upstash env", async () => {
  Deno.env.delete("UPSTASH_REDIS_REST_URL");
  const r = await rateLimit("t", "id", 1, 60);
  assertEquals(r.success, true);
  assertEquals(r.enforced, false);
});
