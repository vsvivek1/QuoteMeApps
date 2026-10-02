// Trends pipeline: gate 6 caps, the ramp (manual / health step-up, automatic step-down) and the kill switch.
import { assert, assertEquals } from "@std/assert";
import { capCheck, evaluateRamp, healthProblem, localDay, remainingToday } from "../_shared/trends/ramp.ts";
import { perDayCap, settingsFromRows } from "../_shared/trends/settings.ts";
import type { Health, Settings } from "../_shared/trends/types.ts";
import { NOW, settings } from "./trends_fixtures.ts";

const withLevel = (level: number, changed_at: string | null = null, over: Partial<Settings["ramp"]> = {}) => {
  const s = settings();
  s.ramp = { ...s.ramp, usa: { level, changed_at }, india: { level, changed_at }, ...over };
  return s;
};
const healthy = (over: Partial<Health> = {}): Health => ({
  country: "usa",
  recorded_at: new Date(NOW.getTime() - 3_600_000).toISOString(),
  indexed_share: 0.85,
  clicks_7d: 1000,
  clicks_prev_7d: 950,
  sc_warnings: 0,
  manual_action: false,
  error_reports_24h: 0,
  ...over,
});

Deno.test("ramp levels: 1, 2, 5, 10, 20 per day, never above the hard max", () => {
  assertEquals([0, 1, 2, 3, 4].map((l) => perDayCap(withLevel(l), "usa")), [1, 2, 5, 10, 20]);
  assertEquals(perDayCap(withLevel(9), "usa"), 20); // out of range clamps to the top level
  const s = withLevel(4);
  s.caps.hard_max_per_day = 10;
  assertEquals(perDayCap(s, "usa"), 10);
});

Deno.test("settings: database rows override the seeded defaults key by key", () => {
  const s = settingsFromRows([
    { key: "caps", value: { max_per_hour: 2 } },
    { key: "ramp", value: { usa: { level: 2, changed_at: null } } },
    { key: "sensitive_keywords", value: ["only"] },
    { key: "unknown", value: 1 },
  ]);
  assertEquals(s.caps.max_per_hour, 2);
  assertEquals(s.caps.ramp_levels, [1, 2, 5, 10, 20]);
  assertEquals(perDayCap(s, "usa"), 5);
  assertEquals(perDayCap(s, "india"), 1);
  assertEquals(s.sensitive_keywords, ["only"]);
});

Deno.test("daily cap counts per local day in the country's time zone", () => {
  const s = withLevel(1); // 2 per day
  // 2026-10-02 15:00Z = 20:30 IST; 2026-10-01 19:00Z = 2026-10-02 00:30 IST (same IST day)
  const india = ["2026-10-01T19:00:00Z", "2026-10-02T09:00:00Z"];
  assertEquals(localDay("2026-10-01T19:00:00Z", "Asia/Kolkata"), "2026-10-02");
  assertEquals(capCheck("india", NOW, india, s).allowed, false);
  // in New York the first one was on Oct 1, so one slot is left
  assertEquals(capCheck("usa", NOW, india, s).allowed, true);
  assertEquals(remainingToday("usa", NOW, india, s), 1);
  assertEquals(remainingToday("india", NOW, india, s), 0);
});

Deno.test("hourly cap: at most max_per_hour in any rolling hour", () => {
  const s = withLevel(4); // 20 per day
  const t = (m: number) => new Date(NOW.getTime() - m * 60_000).toISOString();
  assertEquals(capCheck("usa", NOW, [t(5), t(20), t(50)], s).reason, "hourly cap 3 reached");
  assertEquals(capCheck("usa", NOW, [t(5), t(20), t(61)], s).allowed, true);
});

Deno.test("kill switch blocks publishing regardless of capacity", () => {
  const s = withLevel(4);
  s.publishing = { paused: true, paused_at: NOW.toISOString() };
  const c = capCheck("usa", NOW, [], s);
  assertEquals([c.allowed, c.reason], [false, "publishing paused (kill switch)"]);
  assertEquals(remainingToday("usa", NOW, [], s), 20); // capacity math ignores the switch; callers check it first
});

Deno.test("health problems", () => {
  const s = settings();
  assertEquals(healthProblem(healthy(), NOW, s), null);
  assertEquals(healthProblem(null, NOW, s), "no_recent_health");
  assertEquals(healthProblem(healthy({ recorded_at: "2026-09-01T00:00:00Z" }), NOW, s), "no_recent_health");
  assertEquals(healthProblem(healthy({ indexed_share: 0.4 }), NOW, s), "low_indexed_share");
  assertEquals(healthProblem(healthy({ clicks_7d: 500, clicks_prev_7d: 1000 }), NOW, s), "traffic_drop");
  assertEquals(healthProblem(healthy({ sc_warnings: 1 }), NOW, s), "search_console_warnings");
  assertEquals(healthProblem(healthy({ manual_action: true }), NOW, s), "manual_action");
});

Deno.test("ramp steps down automatically, once per health snapshot", () => {
  const s = withLevel(2, "2026-09-01T00:00:00Z");
  const bad = healthy({ indexed_share: 0.3 });
  const d = evaluateRamp("usa", bad, NOW, s);
  assertEquals([d.action, d.from, d.to, d.reason], ["down", 2, 1, "low_indexed_share"]);
  // after stepping down (changed_at = now), the same snapshot does not step down again
  const after = withLevel(1, NOW.toISOString());
  assertEquals(evaluateRamp("usa", bad, NOW, after).action, "none");
  // never below level 0
  assertEquals(evaluateRamp("usa", bad, NOW, withLevel(0, "2026-09-01T00:00:00Z")).action, "none");
  // traffic drop also steps down
  assertEquals(evaluateRamp("usa", healthy({ clicks_7d: 100, clicks_prev_7d: 1000 }), NOW, s).action, "down");
});

Deno.test("manual action pauses and steps down; an error-report spike pauses only", () => {
  const s = withLevel(3, "2026-09-01T00:00:00Z");
  const m = evaluateRamp("usa", healthy({ manual_action: true }), NOW, s);
  assertEquals([m.action, m.pause], ["down", "search_console_manual_action"]);
  const e = evaluateRamp("usa", healthy({ error_reports_24h: 9 }), NOW, s);
  assertEquals([e.action, e.pause], ["none", "error_report_spike"]);
  const paused = withLevel(3, "2026-09-01T00:00:00Z");
  paused.publishing = { paused: true, paused_at: NOW.toISOString() };
  assertEquals(evaluateRamp("usa", healthy({ error_reports_24h: 9 }), NOW, paused).pause, null); // already paused
});

Deno.test("ramp steps up only when auto_step_up is on, healthy, and 30+ days after the last step", () => {
  const old = "2026-08-15T00:00:00Z"; // 48 days before NOW
  assertEquals(evaluateRamp("usa", healthy(), NOW, withLevel(0, old)).action, "none"); // manual only by default
  const auto = withLevel(0, old, { auto_step_up: true });
  assertEquals(evaluateRamp("usa", healthy(), NOW, auto).action, "up");
  assertEquals(
    evaluateRamp("usa", healthy(), NOW, withLevel(0, "2026-09-20T00:00:00Z", { auto_step_up: true })).action,
    "none",
  ); // < 30 days
  assertEquals(
    evaluateRamp("usa", healthy(), NOW, withLevel(0, null, { auto_step_up: true })).action,
    "none",
  ); // not launched
  assertEquals(
    evaluateRamp("usa", healthy({ indexed_share: 0.5 }), NOW, withLevel(1, old, { auto_step_up: true }))
      .action,
    "down",
  ); // unhealthy: down, not up
  assertEquals(evaluateRamp("usa", healthy(), NOW, withLevel(4, old, { auto_step_up: true })).action, "none"); // top level
  assertEquals(evaluateRamp("usa", null, NOW, auto).action, "none");
  // a snapshot older than the last change cannot move the ramp
  assert(evaluateRamp("usa", healthy({ recorded_at: "2026-08-01T00:00:00Z" }), NOW, auto).action === "none");
});
