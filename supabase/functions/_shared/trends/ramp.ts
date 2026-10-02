// Gate 6: kill switch, rate caps and the ramp (brief Section 21.10).
//
//   * per-country daily cap = caps.ramp_levels[ramp.<country>.level] (1, 2, 5, 10, 20), counted per
//     local day in the country's time zone; at most caps.max_per_hour in any rolling hour;
//   * the ramp steps UP only manually (admin_trends_set_ramp: one level, 30+ days apart, healthy) or
//     by a health signal when ramp.auto_step_up is on (same conditions);
//   * it steps DOWN automatically, one level, when a health snapshot newer than the last change
//     shows a low indexed share, a traffic drop, Search Console warnings or a manual action;
//   * a manual action or an error-report spike also pauses publishing (kill switch).
import { perDayCap } from "./settings.ts";
import type { Country, Health, Settings } from "./types.ts";

export const localDay = (iso: string | Date, tz: string): string =>
  new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit" })
    .format(typeof iso === "string" ? new Date(iso) : iso);

export interface CapCheck {
  allowed: boolean;
  reason: string | null;
  per_day: number;
  today: number;
  last_hour: number;
}

/** May one more article of `country` be published at `now`, given the publish times so far? */
export function capCheck(country: Country, now: Date, publishedAt: string[], s: Settings): CapCheck {
  const perDay = perDayCap(s, country);
  const tz = s.caps.timezones[country];
  const day = localDay(now, tz);
  const t = now.getTime();
  const today = publishedAt.filter((p) => localDay(p, tz) === day).length;
  const lastHour = publishedAt.filter((p) => {
    const x = Date.parse(p);
    return x <= t && t - x < 3_600_000;
  }).length;
  if (s.publishing.paused) {
    return {
      allowed: false,
      reason: "publishing paused (kill switch)",
      per_day: perDay,
      today,
      last_hour: lastHour,
    };
  }
  if (today >= perDay) {
    return {
      allowed: false,
      reason: `daily cap ${perDay} reached`,
      per_day: perDay,
      today,
      last_hour: lastHour,
    };
  }
  if (lastHour >= s.caps.max_per_hour) {
    return {
      allowed: false,
      reason: `hourly cap ${s.caps.max_per_hour} reached`,
      per_day: perDay,
      today,
      last_hour: lastHour,
    };
  }
  return { allowed: true, reason: null, per_day: perDay, today, last_hour: lastHour };
}

/** Remaining daily capacity (used by trends-draft to avoid drafting what cannot be published). */
export function remainingToday(country: Country, now: Date, publishedAt: string[], s: Settings): number {
  const c = capCheck(country, now, publishedAt, { ...s, publishing: { ...s.publishing, paused: false } });
  return Math.max(0, c.per_day - c.today);
}

/** Null when healthy; otherwise the first problem. Mirrors trends.health_problem() in SQL. */
export function healthProblem(h: Health | null, now: Date, s: Settings): string | null {
  const cfg = s.ramp.health;
  if (!h || now.getTime() - Date.parse(h.recorded_at) > cfg.max_age_days * 86_400_000) {
    return "no_recent_health";
  }
  if (h.manual_action) return "manual_action";
  if (h.error_reports_24h > cfg.max_error_reports_24h) return "error_reports";
  if (h.sc_warnings > cfg.max_sc_warnings) return "search_console_warnings";
  if (h.indexed_share === null || h.indexed_share < cfg.min_indexed_share) return "low_indexed_share";
  if (
    (h.clicks_prev_7d ?? 0) > 0 &&
    ((h.clicks_prev_7d! - (h.clicks_7d ?? 0)) / h.clicks_prev_7d!) > cfg.max_click_drop
  ) {
    return "traffic_drop";
  }
  return null;
}

export interface RampDecision {
  action: "none" | "down" | "up";
  from: number;
  to: number;
  pause: string | null; // set: pause publishing with this reason
  reason: string | null;
}

/**
 * Evaluates the ramp of one country against its latest health snapshot. Only a snapshot recorded
 * after the last ramp change can move the ramp, so one bad snapshot steps down exactly once.
 */
export function evaluateRamp(country: Country, latest: Health | null, now: Date, s: Settings): RampDecision {
  const state = s.ramp[country];
  const level = state.level;
  const changed = state.changed_at ? Date.parse(state.changed_at) : 0;
  const none: RampDecision = { action: "none", from: level, to: level, pause: null, reason: null };
  if (!latest) return none;
  const fresh = Date.parse(latest.recorded_at) > changed;
  let pause: string | null = null;
  if (!s.publishing.paused) {
    if (latest.manual_action) pause = "search_console_manual_action";
    else if (latest.error_reports_24h > s.ramp.health.max_error_reports_24h) pause = "error_report_spike";
  }
  const problem = healthProblem(latest, now, s);
  if (problem && problem !== "no_recent_health") {
    if (fresh && level > 0 && problem !== "error_reports") {
      return { action: "down", from: level, to: level - 1, pause, reason: problem };
    }
    return { ...none, pause, reason: problem };
  }
  if (
    !problem && s.ramp.auto_step_up && fresh && level < s.caps.ramp_levels.length - 1 &&
    s.caps.ramp_levels[level + 1] <= s.caps.hard_max_per_day &&
    changed > 0 && now.getTime() - changed >= s.ramp.min_days_between_steps * 86_400_000
  ) {
    return { action: "up", from: level, to: level + 1, pause: null, reason: "healthy" };
  }
  return { ...none, pause };
}
