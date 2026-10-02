// Push scheduling (priority window, digest mode, quiet hours) and push texts.
// Pure functions, unit tested in functions/tests/notify_test.ts.

export type NotifyMode = "instant" | "hourly" | "daily";

export interface LocalParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  weekday: number; // 0 = Sunday
}

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export function localParts(at: Date, timeZone: string): LocalParts {
  const fmt = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    weekday: "short",
  });
  const p = Object.fromEntries(fmt.formatToParts(at).map((x) => [x.type, x.value]));
  return {
    year: Number(p.year),
    month: Number(p.month),
    day: Number(p.day),
    hour: Number(p.hour) % 24,
    minute: Number(p.minute),
    weekday: WEEKDAYS.indexOf(p.weekday),
  };
}

/** "22:00" / "22:00:00" -> minutes after midnight. */
export function parseTimeOfDay(t: string | null | undefined): number | null {
  if (!t) return null;
  const m = /^(\d{1,2}):(\d{2})/.exec(t);
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

export function inQuietHours(at: Date, timeZone: string, start?: string | null, end?: string | null): boolean {
  const s = parseTimeOfDay(start), e = parseTimeOfDay(end);
  if (s === null || e === null || s === e) return false;
  const lp = localParts(at, timeZone);
  const now = lp.hour * 60 + lp.minute;
  return s < e ? now >= s && now < e : now >= s || now < e; // wraps midnight (22:00 -> 07:00)
}

/** Next instant (after `at`) when the local clock shows `hhmm` minutes. */
export function nextLocalTime(at: Date, timeZone: string, minutesOfDay: number): Date {
  const lp = localParts(at, timeZone);
  const now = lp.hour * 60 + lp.minute;
  let delta = minutesOfDay - now;
  if (delta <= 0) delta += 24 * 60;
  const out = new Date(at.getTime() + delta * 60_000);
  out.setUTCSeconds(0, 0);
  return out;
}

export function nextDigestTime(at: Date, mode: NotifyMode, timeZone: string, dailyAt = 9 * 60): Date {
  if (mode === "hourly") {
    const d = new Date(at.getTime());
    d.setUTCMinutes(0, 0, 0);
    d.setUTCHours(d.getUTCHours() + 1);
    return d;
  }
  if (mode === "daily") return nextLocalTime(at, timeZone, dailyAt);
  return at;
}

export interface LeadPushInput {
  now: Date;
  sellerId: string;
  priorityUntil: Date | null;
  sellerHasPriority: boolean;
  notifyMode: NotifyMode | string | null;
  quietStart?: string | null;
  quietEnd?: string | null;
  timeZone?: string | null;
}

export interface LeadPushPlan {
  pushAfter: Date;
  digestKey: string | null;
  /** true = push right now from match-request (fast path). */
  immediate: boolean;
  reason: "instant" | "priority_window" | "digest" | "quiet_hours";
}

/**
 * When should a seller hear about a new matching request?
 *  1. Non-priority sellers wait until the priority window ends (verified / Pro go first).
 *  2. hourly / daily digest sellers get one merged push per bucket.
 *  3. Quiet hours (seller local time) move the push to the end of quiet hours.
 */
export function planLeadPush(i: LeadPushInput): LeadPushPlan {
  const tz = i.timeZone || "UTC";
  let at = i.now;
  let reason: LeadPushPlan["reason"] = "instant";
  if (!i.sellerHasPriority && i.priorityUntil && i.priorityUntil > at) {
    at = i.priorityUntil;
    reason = "priority_window";
  }
  let digestKey: string | null = null;
  const mode = (i.notifyMode ?? "instant") as NotifyMode;
  if (mode === "hourly" || mode === "daily") {
    at = nextDigestTime(at, mode, tz);
    digestKey = `leads:${mode}:${at.toISOString().slice(0, 16)}`;
    reason = "digest";
  }
  if (inQuietHours(at, tz, i.quietStart, i.quietEnd)) {
    at = nextLocalTime(at, tz, parseTimeOfDay(i.quietEnd)!);
    if (digestKey) digestKey = `leads:${mode}:${at.toISOString().slice(0, 16)}`;
    reason = "quiet_hours";
  }
  return { pushAfter: at, digestKey, immediate: at.getTime() <= i.now.getTime(), reason };
}

// --- texts -----------------------------------------------------------------------------------

type Lang = "en" | "hi" | "es";
type Tpl = { title: string; body: string };

const T: Record<string, Record<Lang, Tpl>> = {
  new_lead: {
    en: { title: "New request near you", body: "{title}" },
    hi: { title: "आपके पास नई माँग", body: "{title}" },
    es: { title: "Nueva solicitud cerca de ti", body: "{title}" },
  },
  new_lead_digest: {
    en: { title: "{count} new requests", body: "Buyers near you are waiting for quotes." },
    hi: { title: "{count} नई माँगें", body: "आपके पास के खरीदार कोटेशन का इंतज़ार कर रहे हैं।" },
    es: { title: "{count} solicitudes nuevas", body: "Compradores cerca de ti esperan cotizaciones." },
  },
  new_quote: {
    en: { title: "New quote: {title}", body: "{seller_name} sent a quote." },
    hi: { title: "नया कोटेशन: {title}", body: "{seller_name} ने कोटेशन भेजा।" },
    es: { title: "Nueva cotización: {title}", body: "{seller_name} envió una cotización." },
  },
  new_quote_digest: {
    en: { title: "{count} new quotes", body: "for {title}" },
    hi: { title: "{count} नए कोटेशन", body: "{title} के लिए" },
    es: { title: "{count} cotizaciones nuevas", body: "para {title}" },
  },
  quote_revised: {
    en: { title: "Quote updated", body: "A seller revised their quote for {title}." },
    hi: { title: "कोटेशन बदला गया", body: "{title} के लिए विक्रेता ने कोटेशन बदला।" },
    es: { title: "Cotización actualizada", body: "Un vendedor actualizó su cotización para {title}." },
  },
  message: {
    en: { title: "New message", body: "{preview}" },
    hi: { title: "नया संदेश", body: "{preview}" },
    es: { title: "Nuevo mensaje", body: "{preview}" },
  },
  message_digest: {
    en: { title: "{count} new messages", body: "Open the chat to reply." },
    hi: { title: "{count} नए संदेश", body: "जवाब देने के लिए चैट खोलें।" },
    es: { title: "{count} mensajes nuevos", body: "Abre el chat para responder." },
  },
  quote_window_ending: {
    en: { title: "Quotes closing soon", body: "Compare the quotes for {title} before the window ends." },
    hi: { title: "कोटेशन जल्द बंद होंगे", body: "{title} के कोटेशन अभी देखें।" },
    es: { title: "Las cotizaciones cierran pronto", body: "Compara las cotizaciones para {title}." },
  },
  shortlisted: {
    en: { title: "You were shortlisted", body: "The buyer shortlisted your quote for {title}." },
    hi: { title: "आप शॉर्टलिस्ट हुए", body: "खरीदार ने {title} के लिए आपका कोटेशन चुना।" },
    es: { title: "Estás preseleccionado", body: "El comprador preseleccionó tu cotización para {title}." },
  },
  quote_accepted: {
    en: { title: "Quote accepted!", body: "The buyer accepted your quote for {title}." },
    hi: { title: "कोटेशन स्वीकार!", body: "खरीदार ने {title} के लिए आपका कोटेशन स्वीकार किया।" },
    es: { title: "¡Cotización aceptada!", body: "El comprador aceptó tu cotización para {title}." },
  },
  quote_declined: {
    en: { title: "Quote declined", body: "The buyer declined your quote for {title}." },
    hi: { title: "कोटेशन अस्वीकार", body: "{title} के लिए आपका कोटेशन अस्वीकार हुआ।" },
    es: { title: "Cotización rechazada", body: "El comprador rechazó tu cotización para {title}." },
  },
  quote_not_selected: {
    en: { title: "Thanks for quoting", body: "The buyer chose another quote for {title}." },
    hi: { title: "कोटेशन के लिए धन्यवाद", body: "खरीदार ने {title} के लिए दूसरा कोटेशन चुना।" },
    es: { title: "Gracias por cotizar", body: "El comprador eligió otra cotización para {title}." },
  },
  counter_offer: {
    en: { title: "Counter-offer", body: "The buyer asked for a better price on {title}." },
    hi: { title: "मोलभाव", body: "खरीदार ने {title} पर बेहतर दाम माँगा।" },
    es: { title: "Contraoferta", body: "El comprador pidió un mejor precio para {title}." },
  },
  quote_expiring: {
    en: { title: "Quote expiring tomorrow", body: "Revise or extend your quote." },
    hi: { title: "कोटेशन कल समाप्त", body: "अपना कोटेशन बदलें या बढ़ाएँ।" },
    es: { title: "Tu cotización vence mañana", body: "Revisa o extiende tu cotización." },
  },
  request_closed: {
    en: { title: "Request closed", body: "The buyer closed {title}." },
    hi: { title: "माँग बंद", body: "खरीदार ने {title} बंद किया।" },
    es: { title: "Solicitud cerrada", body: "El comprador cerró {title}." },
  },
  order_status: {
    en: { title: "Order update", body: "Order status: {status}" },
    hi: { title: "ऑर्डर अपडेट", body: "ऑर्डर स्थिति: {status}" },
    es: { title: "Actualización del pedido", body: "Estado del pedido: {status}" },
  },
  review_reminder: {
    en: { title: "How did it go?", body: "Leave a quick review for the seller." },
    hi: { title: "अनुभव कैसा रहा?", body: "विक्रेता के लिए समीक्षा लिखें।" },
    es: { title: "¿Cómo te fue?", body: "Deja una reseña rápida al vendedor." },
  },
  new_review: {
    en: { title: "New review", body: "You received a {stars}-star review." },
    hi: { title: "नई समीक्षा", body: "आपको {stars}-स्टार समीक्षा मिली।" },
    es: { title: "Nueva reseña", body: "Recibiste una reseña de {stars} estrellas." },
  },
  seller_verified: {
    en: { title: "You're verified", body: "Your business is now verified." },
    hi: { title: "आप सत्यापित हैं", body: "आपका व्यवसाय सत्यापित हो गया है।" },
    es: { title: "Estás verificado", body: "Tu negocio ya está verificado." },
  },
  verification_rejected: {
    en: { title: "Verification needs attention", body: "Please check your documents." },
    hi: { title: "सत्यापन पर ध्यान दें", body: "कृपया अपने दस्तावेज़ जाँचें।" },
    es: { title: "Revisa tu verificación", body: "Por favor revisa tus documentos." },
  },
};

const GENERIC: Record<Lang, Tpl> = {
  en: { title: "I Want", body: "You have a new update." },
  hi: { title: "I Want", body: "आपके लिए नया अपडेट है।" },
  es: { title: "I Want", body: "Tienes una novedad." },
};

const CHANNEL: Record<string, string> = {
  new_lead: "leads",
  message: "chat",
  new_quote: "quotes",
  quote_revised: "quotes",
  quote_window_ending: "quotes",
  order_status: "orders",
};

export function fill(tpl: string, vars: Record<string, unknown>): string {
  return tpl.replace(/\{(\w+)\}/g, (_, k) => {
    const v = vars[k];
    return v === undefined || v === null ? "" : String(v);
  }).replace(/\s+/g, " ").trim();
}

export function renderPush(
  type: string,
  payload: Record<string, unknown>,
  language: string | null | undefined,
  count = 1,
): { title: string; body: string; channel: string } {
  const lang = (["en", "hi", "es"].includes(language ?? "") ? language : "en") as Lang;
  const key = count > 1 && T[`${type}_digest`] ? `${type}_digest` : type;
  const tpl = T[key]?.[lang] ?? T[key]?.en ?? GENERIC[lang];
  const vars = { ...payload, count };
  const body = fill(tpl.body, vars) || GENERIC[lang].body;
  return { title: fill(tpl.title, vars), body, channel: CHANNEL[type] ?? "account" };
}

export interface ClaimedNotification {
  id: string;
  user_id: string;
  type: string;
  payload: Record<string, unknown>;
  digest_key: string | null;
  created_at: string;
  language: string | null;
  notification_prefs: Record<string, unknown> | null;
  timezone: string | null;
  fcm_tokens: string[] | null;
}

export interface PushGroup {
  userId: string;
  ids: string[];
  type: string;
  payload: Record<string, unknown>;
  count: number;
  language: string | null;
  tokens: string[];
  collapseKey: string;
  pushEnabled: boolean;
}

/** One push per (user, digest_key); notifications without a digest key push individually. */
export function groupForPush(rows: ClaimedNotification[]): PushGroup[] {
  const groups = new Map<string, PushGroup>();
  for (const r of rows) {
    const key = r.digest_key ? `${r.user_id}|${r.digest_key}` : `${r.user_id}|id:${r.id}`;
    const g = groups.get(key);
    if (g) {
      g.ids.push(r.id);
      g.count++;
      g.payload = r.payload; // latest wins for title/route
      continue;
    }
    groups.set(key, {
      userId: r.user_id,
      ids: [r.id],
      type: r.type,
      payload: r.payload ?? {},
      count: 1,
      language: r.language,
      tokens: r.fcm_tokens ?? [],
      collapseKey: r.digest_key ?? `${r.type}:${r.id}`,
      pushEnabled: (r.notification_prefs?.push ?? true) !== false,
    });
  }
  // Digest pushes for leads / chats route to the list rather than one item.
  for (const g of groups.values()) {
    if (g.count > 1 && g.type === "new_lead") g.payload = { ...g.payload, route: "/seller/leads" };
  }
  return [...groups.values()];
}
