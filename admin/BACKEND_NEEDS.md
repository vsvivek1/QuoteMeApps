# Admin panel: backend contract

What `admin/` reads and calls in each country's Supabase project, checked
against `supabase/migrations` as of 2026-10-02. Items marked **MISSING** are
what the panel assumes but the backend does not have yet. Until they exist, the
panel either falls back (noted) or shows "n/a".

The client only ever holds the anon/publishable key. Every privileged action
goes through `private.require_admin()` RPCs, admin-only RLS
(`private.is_admin()`), or an Edge Function that checks the admin JWT.

## Already in the backend (used as-is)

| Area | Tables / RPCs / functions | Used by |
|---|---|---|
| Auth | `custom_access_token_hook` (`roles` claim), `profiles.roles`, `profiles.status` | Login: claim contains `admin` and profile is an active admin |
| Dashboard | `admin_metrics()` | KPI tiles |
| Verification | `seller_documents`, `seller_licences` (+ `sellers` join), `admin_review_document`, `admin_review_licence`, Storage `verification-docs` (`createSignedUrl`, 5 min) | Verification queue |
| Moderation | `reports`; previews from `requests.title`, `quotes.notes`, `messages.body`, `reviews.text`, `sellers.business_name`, `profiles.name`; `admin_resolve_report` (dismiss/hide/restore), `admin_set_user_status` (suspend/ban/reactivate) | Reports queue, users tab |
| Categories | `categories` (select), `admin_set_category_policy`, `admin_upsert_category` | Category and policy editor |
| Flags | `admin_get_settings`, `admin_set_setting` (monetization switch, `early_partner_free_until`, `outreach_enabled`, caps, brakes, limits) | Flags screen |
| CRM | `outreach_leads`, `outreach_events`, `outreach_campaigns`, `outreach_sequences`, `outreach_inboxes`, `suppression_list` (admin RLS); `outreach_upsert_lead` (CSV import, dedupe), `outreach_is_suppressed`, `outreach_can_send` (gate re-checked right before each send), `admin_seller_coverage` | Kanban board, lead detail, import, suppression, campaigns, coverage |
| Brochures | `brochures` table, Storage bucket `brochures` (admin insert, public read) | Brochure generator (upload + row, versioned path, no overwrite) |

## MISSING: needed by the panel

1. **`admin_audit_log` table** (read-only for the panel)
   ```sql
   create table public.admin_audit_log (
     id bigint generated always as identity primary key,
     actor_id uuid references public.profiles(id) on delete set null,
     actor_email text,
     action text not null,          -- e.g. admin_review_document, admin_set_setting, outreach_stage_change
     target_type text,              -- document | licence | report | user | category | setting | outreach_lead | suppression | brochure
     target_id text,
     details jsonb not null default '{}',
     created_at timestamptz not null default now()
   );
   -- RLS: select for private.is_admin(); no insert/update/delete for authenticated.
   ```
   Written **server side**: one insert in every `admin_*` RPC, plus triggers on
   `outreach_leads` (stage change), `suppression_list` (insert),
   `outreach_campaigns` (status change) and `brochures` (insert). The panel
   never writes it, so the log cannot be forged from the client.

2. **`admin_kpis()` RPC** (`jsonb`, `require_admin`): the Section 13 KPIs
   that `admin_metrics()` does not cover. Keys the panel reads (all optional):
   `request_to_acceptance_pct`, `seller_response_rate_pct`, `free_to_paid_pct`,
   `retention` (`{buyer_d1, buyer_d7, buyer_d30, seller_d1, seller_d7, seller_d30}` in %),
   `revenue_per_seller_minor`, `refunds_30d`, `outreach_sent_today`,
   `outreach_daily_capacity` (sum of active inbox caps, bounded by
   `outreach_global_daily_cap`), `outreach_queue`, `outreach_reply_rate_pct`,
   `outreach_signup_rate_pct`. Missing function = tiles show "n/a".

3. **`outreach-send` action `send_one`** (admin JWT only, never cron). The
   existing function only has `run` / `preview` / `verify_emails`. Body the
   panel sends:
   ```json
   { "action": "send_one", "lead_id": "uuid", "campaign_id": "uuid|null", "inbox_id": "uuid|null",
     "channel": "email|whatsapp", "step": 1, "variant": 0, "category_id": 4,
     "subject": "...", "body": "...", "footer": "client preview only",
     "whatsapp_template": "approved_template_name|null", "confirmed_by_admin": true }
   ```
   It must refuse unless `confirmed_by_admin` is true, run
   `checkOutreachContent` on the edited subject/body, build its own identity
   footer and List-Unsubscribe headers (the client footer is a preview),
   call `outreach_can_send(lead, channel, inbox)`, send, then
   `outreach_record_send`. Response: `{ "ok": true, "event_id": "uuid" }` or
   `{ "ok": false, "reason": "<rule code>" }`.

4. **Setting `outreach_business_address`** (`app_settings`, not public): the
   physical postal address used in every email (CAN-SPAM, rule 8). It must
   exist as a row because `admin_set_setting` only updates known keys. The
   panel's pre-send check blocks sending while it is empty or still a
   `{{...}}` placeholder. Keep it in sync with the Edge Function's
   `OUTREACH_PHYSICAL_ADDRESS` (or have the function read the setting).

5. **`admin_outreach_set_stage(p_lead_id uuid, p_stage text, p_note text)`**
   (nice to have): atomic stage move with the same forward-only rules as
   `stage_machine.dart`, a `stage_change` event and, for `do_not_contact`, a
   suppression row. Fallback today: the panel does the three writes itself
   through admin RLS (`suppression_list` insert, `outreach_leads` update,
   `outreach_events` insert) when the RPC returns `PGRST202`.

6. **Remote Config mirror** (decision): public `app_settings` (monetization
   switch, quote cap, priority window) need to reach Firebase Remote Config if
   the apps read flags from there. Suggested: a `sync-remote-config` Edge
   Function (service account stays server side) triggered on `app_settings`
   update. The panel has no Firebase credentials by design.

## Decisions and open points

- **Automatic sending.** `supabase/functions/outreach-send` is designed to be
  called by pg_cron every 10 minutes (`action: run`). The panel itself never
  sends automatically: each send is one lead, one reviewed message and an
  explicit confirmation. Whether the cron path stays enabled is a product
  decision for the owner; the panel works either way and the database gate is
  the same.
- **Hindi brochures (blocker).** The Dart `pdf` package does not shape
  Devanagari (conjuncts and matras render wrongly), so the India build offers
  English brochures only (`AdminCountryConfig.india.brochureLanguages`). Fix
  later with pre-rendered Hindi artwork from `branding/` or server-side
  rendering with a shaping engine.
- **Lead sources from the panel.** The panel imports CSV files (compliant
  sources only, validated client side, deduplicated by `outreach_upsert_lead`).
  The OSM / Places importer (`import-leads` Edge Function) is not wired to a
  panel button yet; it needs a `cities` picker with coordinates.
- **Brochure formats** use the `brochures.format` values `pdf` (A4), `onepager`
  (A5) and `image` (1080x1350 PNG). The `brochure-link` function's
  `format: "png"` should map to `image`.
