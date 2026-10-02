// Push scheduling: priority window, digest modes, quiet hours; grouping and texts.
import { assert, assertEquals } from "@std/assert";
import { groupForPush, inQuietHours, nextDigestTime, planLeadPush, renderPush } from "../_shared/notify.ts";

const base = { sellerId: "s1", quietStart: "22:00", quietEnd: "07:00", timeZone: "Asia/Kolkata" };
// 2026-10-05 11:00 IST = 05:30 UTC
const now = new Date("2026-10-05T05:30:00Z");

Deno.test("instant seller with priority is pushed now", () => {
  const p = planLeadPush({ ...base, now, priorityUntil: new Date(now.getTime() + 15 * 60_000), sellerHasPriority: true, notifyMode: "instant" });
  assertEquals(p.immediate, true);
  assertEquals(p.digestKey, null);
  assertEquals(p.reason, "instant");
});

Deno.test("non-priority seller waits for the priority window", () => {
  const until = new Date(now.getTime() + 15 * 60_000);
  const p = planLeadPush({ ...base, now, priorityUntil: until, sellerHasPriority: false, notifyMode: "instant" });
  assertEquals(p.pushAfter.toISOString(), until.toISOString());
  assertEquals(p.immediate, false);
  assertEquals(p.reason, "priority_window");
});

Deno.test("hourly digest goes to the next hour with a shared digest key", () => {
  const p = planLeadPush({ ...base, now, priorityUntil: null, sellerHasPriority: true, notifyMode: "hourly" });
  assertEquals(p.pushAfter.toISOString(), "2026-10-05T06:00:00.000Z");
  assertEquals(p.digestKey, "leads:hourly:2026-10-05T06:00");
  const q = planLeadPush({ ...base, now: new Date(now.getTime() + 60_000), priorityUntil: null, sellerHasPriority: true, notifyMode: "hourly" });
  assertEquals(q.digestKey, p.digestKey);
});

Deno.test("daily digest is 09:00 seller local time", () => {
  const d = nextDigestTime(now, "daily", "Asia/Kolkata");
  assertEquals(d.toISOString(), "2026-10-06T03:30:00.000Z"); // 09:00 IST next day
  const ny = nextDigestTime(new Date("2026-10-05T12:00:00Z"), "daily", "America/New_York");
  assertEquals(ny.toISOString(), "2026-10-05T13:00:00.000Z"); // 08:00 EDT now -> 09:00 EDT today
});

Deno.test("quiet hours (wrapping midnight) move the push to the end of quiet hours", () => {
  const late = new Date("2026-10-05T17:30:00Z"); // 23:00 IST
  assert(inQuietHours(late, "Asia/Kolkata", "22:00", "07:00"));
  assert(!inQuietHours(now, "Asia/Kolkata", "22:00", "07:00"));
  const p = planLeadPush({ ...base, now: late, priorityUntil: null, sellerHasPriority: true, notifyMode: "instant" });
  assertEquals(p.reason, "quiet_hours");
  assertEquals(p.pushAfter.toISOString(), "2026-10-06T01:30:00.000Z"); // 07:00 IST
  assertEquals(p.immediate, false);
});

Deno.test("no quiet hours configured", () => {
  assert(!inQuietHours(now, "UTC", null, null));
  assert(!inQuietHours(now, "UTC", "10:00", "10:00"));
});

Deno.test("grouping merges digest keys per user and respects push off", () => {
  const row = (id: string, user: string, digest: string | null, push = true) => ({
    id, user_id: user, type: "new_quote", payload: { title: "Fridge", route: "/r/1" }, digest_key: digest,
    created_at: "", language: "en", notification_prefs: { push }, timezone: "UTC", fcm_tokens: ["t-" + user],
  });
  const groups = groupForPush([row("1", "u1", "quotes:r1"), row("2", "u1", "quotes:r1"), row("3", "u1", null), row("4", "u2", null, false)]);
  assertEquals(groups.length, 3);
  const digest = groups.find((g) => g.ids.length === 2)!;
  assertEquals(digest.count, 2);
  assertEquals(groups.find((g) => g.userId === "u2")!.pushEnabled, false);
});

Deno.test("push texts: language fallback and digest wording", () => {
  assertEquals(renderPush("new_quote", { title: "Fridge", seller_name: "A1" }, "en").body, "A1 sent a quote.");
  assertEquals(renderPush("new_quote", { title: "Fridge" }, "en", 5).title, "5 new quotes");
  assertEquals(renderPush("new_lead", { title: "AC repair" }, "hi").title, "आपके पास नई माँग");
  assertEquals(renderPush("new_lead", { title: "AC" }, "fr").title, "New request near you");
  assertEquals(renderPush("unknown_type", {}, "es").body, "Tienes una novedad.");
});
