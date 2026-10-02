# Backend API contract (Flutter app, admin panel, websites)

The source of truth is `supabase/migrations/`; this file is the contract the clients code
against. Both apps (`com.calecute.iwant.usa`, `com.calecute.iwant.india`) use the same API
against their own project. A country never sees the other country's data.

## 1. Conventions

**Auth.** Supabase Auth with phone OTP, Google and Apple. The custom access token hook
(`public.custom_access_token_hook`) adds these JWT claims, which the app reads with
`session.accessToken` → decode:

| claim | type | notes |
|---|---|---|
| `roles` | `string[]` | `buyer`, `seller`, `admin` (empty when banned or deleted) |
| `active_mode` | `"buyer" \| "seller"` | last mode chosen with `set_active_mode` |
| `account_status` | `active \| suspended \| banned \| deleted` | show a blocking screen unless `active` |
| `seller_verified` | `bool` | Verified badge / priority window |

After `become_seller`, `set_active_mode` or an admin role change, call
`supabase.auth.refreshSession()` so the claims update. The server re-checks every claim against
the database (admin needs the claim **and** `profiles.roles`).

**Errors.** RPCs raise `SQLSTATE PTnnn`, and PostgREST answers HTTP `nnn` with this body:

```json
{ "code": "PT409", "message": "quote_cap_reached", "details": "...|null", "hint": null }
```

`message` is a stable snake_case code; map it to a localized string (see section 9). In
supabase-dart this is `PostgrestException(code: 'PT409', message: 'quote_cap_reached')`. An RLS
or grant violation is `42501` (HTTP 403). Edge Functions return the same shape with the HTTP
status: `{ "code": "...", "message": "...", "details": ..., "hint": ... }`.

**Money.** Integer minor units (paise / cents) as `int` / `bigint`. Never use doubles for money.
Tax rates are integer basis points (`1800` = 18 %). `round_half_up(n, d) = (2n + d) ~/ (2d)`.

- India GST per line: `base = round_half_up(qty × unit_price_minor, 1)` (qty has up to 3 decimals).
  Intra-state: `cgst = sgst = round_half_up(base × bp, 20000)`. Inter-state:
  `igst = round_half_up(base × bp, 10000)`. Intra means seller state = request state (or
  either is unknown).
- USA: `sales_tax = round_half_up(subtotal × bp, 10000)` on the subtotal only.
- `total = subtotal + tax + delivery` (delivery is untaxed).
- `tax_breakdown`: `{"kind":"gst","mode":"intra"|"inter","rate_bp","cgst","sgst","igst"}` or
  `{"kind":"sales_tax","rate_bp","amount"}`.
- Shared fixtures: `supabase/tests/fixtures/money_rounding_cases.json`. Use them for the Dart
  `lib/core/money` tests too. Preview totals with `compute_quote_totals`; the server always
  recomputes.
- Limitation: integer bp cannot express 8.875 % (NYC). See section 11.

**Pagination.** Keyset cursors, never offsets: pass the last row's `{ "created_at", "id" }` as
`p_cursor`. Results are newest first.

**Time.** All timestamps are `timestamptz` (ISO 8601 UTC). Quiet hours and business hours use the
user's or seller's IANA `timezone`.

**Rate limits.** In the database: requests (`max_requests_per_buyer_per_day`, rolling 24 h),
quotes (`max_quotes_per_seller_per_hour`) and the lead feed (`lead_feed_per_minute`). Edge
Functions also use per-user or per-IP Upstash limits. All of them answer `429 rate_limited`.

## 2. Tables (direct PostgREST access)

Write through RPCs unless a write is listed here. RLS is on everywhere.

| Table | anon | authenticated read | authenticated write |
|---|---|---|---|
| `app_settings` | public keys | public keys (admin: all) | admin via `admin_set_setting` |
| `postal_codes`, `cities` | yes | yes | – |
| `categories` | active | active (admin: all) | admin RPCs |
| `sellers` | not hidden | not hidden / own | via `upsert_seller_profile` |
| `seller_categories` | yes | yes | via `upsert_seller_profile` |
| `reviews` | not hidden | + own (from/to) | via `submit_review`, `seller_reply_review` |
| `profiles` | – | own row (others: `get_profiles_public`) | `update` own `name, photo_url, language, timezone, notification_prefs` |
| `addresses` | – | own | full CRUD on own rows |
| `device_tokens` | – | own | CRUD own (prefer `register_device_token`) |
| `quote_templates` | – | own (seller) | CRUD own |
| `blocks` | – | own | `insert` / `delete` own (or `block_user` / `unblock_user`) |
| `consents` | – | own | `insert` own (`document in terms, privacy, marketing, analytics, whatsapp, seller_terms`; `version`) |
| `requests` | – | own as buyer (sellers: `get_lead_feed` / `get_request_for_seller`) | `create_request`, `close_request` |
| `request_private` | – | buyer, accepted seller, admin | buyer: `update (full_address)` |
| `request_media` | – | buyer; sellers who quoted (not hidden) | buyer: `insert` / `delete` while open (path `{request_id}/...`) |
| `quotes`, `quote_line_items`, `quote_revisions` | – | the quote's seller and the request's buyer | quote RPCs |
| `lead_states` | – | own (seller) | `dismiss_lead`, `mark_leads_seen` |
| `chats` | – | members | `get_or_create_chat` / `open_chat` |
| `messages` | – | members (hidden ones only to the sender) | `insert (chat_id, sender_id, type, body, attachment_path, client_id)`, `type in text, image`, sender = you, not blocked, attachment under `{chat_id}/`; `client_id` makes retries idempotent (see Chat) |
| `orders`, `order_events` | – | parties | order RPCs |
| `notifications` | – | own | `mark_notifications_read` |
| `entitlements` | – | own (seller) | stores only (Edge Functions) |
| `seller_documents`, `seller_licences`, `seller_contacts` | – | own (contacts: also order parties) | `submit_verification`, `submit_licence`, `upsert_seller_profile` |
| `reports` | – | own | `report_content` |
| `billing_events`, `category_keywords` | – | admin | – |
| `outreach_*`, `suppression_list`, `brochures` | – | admin | admin (full CRUD; campaign activation and stage moves have extra rules, see Outreach below) |
| `admin_audit_log` | – | admin | – (written only server side; append-only) |
| `web_form_submissions`, `waitlist_signups`, `account_deletion_requests` | – | admin | admin `update` (status, handled_by) |

Selected columns:

- `profiles`: `id, name, phone, email, photo_url, language, roles[], active_mode, status,
  suspended_until, timezone, notification_prefs {mode, quiet_hours{start,end}, push, marketing},
  is_review_account, referral_code`
- `requests`: `id, buyer_id, category_id, title, description, fields, budget_min_minor,
  budget_max_minor, currency, budget_visible, needed_by, location (≈110 m), location_code,
  locality, city, state, audience (local|online|both), status (open|closed|awarded|expired|cancelled),
  quote_count, max_quotes, priority_until, quote_window_ends_at, accepted_quote_id, reference_url,
  inviting_seller_id, hidden, closed_at, created_at`
- `quotes`: `id, request_id, seller_id, subtotal_minor, tax_minor, tax_breakdown, delivery_minor,
  total_minor, currency, offered_brand_model, fields, delivery_date, warranty, valid_until, notes,
  attachments[], status (sent|revised|shortlisted|declined|accepted|withdrawn|expired),
  revision_count, decline_reason, counter_target_minor, counter_note, shortlisted_at, accepted_at,
  billing_source, created_at`
- `orders`: `id, request_id, request_title, quote_id, buyer_id, seller_id, status, total_minor, currency,
  payment_method (cash|upi|card|bank_transfer|zelle|check|seller_link|other), payment_amount_minor,
  payment_recorded_at, scheduled_for, completed_at, cancelled_reason, created_at`.
  `status`: `accepted → scheduled → dispatched → delivered → completed`, or `cancelled`.
- `chats`: `id, request_id, request_title, buyer_id, seller_id, last_message_at, last_message_preview`.
  `request_title` (on chats and orders) is a copy of `requests.title`, kept in sync by the server,
  because sellers cannot read `requests` directly.
- `messages`: `id, chat_id, sender_id, type, body, attachment_path, quote_id, contains_contact,
  hidden, read_at, client_id, created_at`.
- `sellers`: `id, business_name, slug, logo_url, photos[], description, years_in_business,
  brands[], area_type (radius|codes|nationwide), center, radius_km, service_codes[], city, state,
  timezone, verification_status, rating_avg, rating_count, quotes_sent, quotes_won,
  avg_response_mins, early_partner, free_until, notify_mode (instant|hourly|daily),
  quiet_hours_start, quiet_hours_end, featured_until`
- `categories`: `id, parent_id, slug, names {en, hi|es}, policy (allowed|restricted|blocked),
  required_licence_type, disclaimer, policy_reason, field_schema, keywords[], icon, sort, active`.
  `field_schema` (one shape everywhere: SQL validator, seeds, admin editor; a bare array is
  rejected with `23514`/HTTP 400): `{version: 1, fields: [{key, type: text|number|select|multiselect|boolean|date,
  label{..}, required, scope: request|quote|both, options[{value,label{..}}], min, max, unit}]}`.

Public `app_settings` keys (`get_app_settings()` returns them as one object): `country`,
`currency`, `default_timezone`, `monetization_enabled`, `early_partner_free_until`,
`free_quotes_per_month`, `quote_cap`, `priority_window_minutes`,
`max_requests_per_buyer_per_day`, `max_quotes_per_seller_per_hour`, `quote_valid_days_default`,
`max_quote_revisions`, `legal_versions`, `languages`, `web_purchase_links_allowed` (bool, default
`false`: show external web checkout links in the apps), `paywall_default_period` (`"monthly"` |
`"annual"`, default `"annual"`), `whatsapp_notifications` (bool, default `false`) and the other rows
marked `is_public`.

Admin-only keys (read with `admin_get_settings`, write with `admin_set_setting`) include the outreach
flags and caps, `outreach_business_address` (see Outreach) and `kpi_product_prices_minor`
(`{"seller_pro_monthly": 49900, ...}`, used only for the revenue estimate in `admin_kpis`).

## 3. RPCs (`supabase.rpc(name, params: {...})`)

Arguments are named. `=x` is the default. `→` is the result: `table` means a row of that table
(JSON object); `setof` / `table(...)` means a list.

### Settings, profile, identity
| RPC | → | notes |
|---|---|---|
| `get_app_settings()` | `jsonb` | anon OK |
| `set_active_mode(p_mode text)` | `text` | `buyer` or `seller` (seller needs the role) |
| `get_profiles_public(p_ids uuid[])` | `table(id, display_name, photo_url, is_seller, business_name, seller_verified, rating_avg, rating_count)` | safe public card for chat headers, etc. |
| `register_device_token(p_token, p_platform, p_app_version=null, p_locale=null)` | `void` | `platform`: android, ios, web |
| `block_user(p_user_id)` / `unblock_user(p_user_id)` | `void` | blocks hide each party from feed, chat and matching |
| `delete_my_account()` | `jsonb` summary | prefer the `delete-account` Edge Function (it also deletes the auth user and revokes Apple tokens) |
| `classify_request_text(p_text, p_limit=5)` | `table(category_id, slug, names, parent_id, policy, score real, blocked bool, reason jsonb)` | category suggestions while typing; `blocked=true` means show `reason` and stop |
| `normalize_postal_code(p_code)` | `text` | |
| `is_valid_gstin(p_gstin)` / `is_valid_ein(p_ein)` | `bool` | client-side hints; the server validates again |
| `compute_quote_totals(p_country 'IN'|'US', p_lines jsonb, p_delivery_minor=0, p_sales_tax_rate_bp=0, p_intra_state=true)` | `jsonb {lines, subtotal_minor, tax_minor, tax_breakdown, delivery_minor, total_minor}` | anon OK |
| `gst_line_tax(p_qty, p_unit_price_minor, p_rate_bp, p_intra_state)` | `{base_minor, cgst_minor, sgst_minor, igst_minor, tax_minor}` | |
| `us_sales_tax(p_subtotal_minor, p_rate_bp)` / `money_round_half_up(n, d)` | `bigint` | |

### Seller onboarding and plan
| RPC | → | notes |
|---|---|---|
| `become_seller(p_business_name, p_signup_token=null)` | `sellers` | adds the `seller` role; `early_partner=true` while monetization is off; the token links an outreach lead |
| `upsert_seller_profile(p_business_name, p_description, p_years_in_business, p_brands text[], p_area_type, p_lat, p_lng, p_radius_km, p_service_codes text[], p_category_ids bigint[], p_logo_url, p_photos text[], p_city, p_state, p_timezone, p_notify_mode, p_quiet_hours_start time, p_quiet_hours_end time, p_business_phone, p_business_email, p_website, p_address_line, p_postal_code, p_signup_token)` (all `=null`) | `sellers` | partial update: null keeps the current value. Blocked categories are rejected (`422 invalid_or_blocked_category`) |
| `get_my_seller_profile()` | `jsonb` = the `sellers` row (minus `center`) + `center_lat`, `center_lng`, `contacts` (seller_contacts row), `category_ids[]`, `lead_category_ids[]` (leaf ids the seller actually receives) | |
| `submit_verification(p_doc_type, p_doc_number=null, p_file_path=null)` | `seller_documents` | `doc_type`: gstin, udyam, pan, shop_photo, ein, state_license, business_address, website, other; file in `verification-docs/{seller_id}/...` |
| `submit_licence(p_licence_type, p_number, p_issuer=null, p_state=null, p_category_ids bigint[]='{}', p_expires_at=null, p_file_path=null)` | `seller_licences` | needed for restricted categories |
| `get_my_entitlement()` | `jsonb {is_seller, monetization_enabled, early_partner, free_until, subscription{store, product_id, status, renews_at, expires_at}, payment_issue, free_quotes_per_month, free_quotes_used, credits_balance, has_priority, can_quote, next_quote_billing_source}` | drives the paywall, "Founding partner until …" badge and "fix your payment" banner |

### Requests (buyer)
| RPC | → | notes |
|---|---|---|
| `create_request(p_category_id, p_title, p_description=null, p_fields jsonb='{}', p_budget_min_minor=null, p_budget_max_minor=null, p_budget_visible=true, p_needed_by date=null, p_lat=null, p_lng=null, p_location_code=null, p_locality=null, p_audience='both', p_quote_window_hours=48, p_full_address=null, p_buyer_phone=null, p_reference_url=null, p_inviting_seller_id=null)` | `table(request_id, status, priority_until, quote_window_ends_at, matched_sellers int)` | needs a GPS pin **or** a postal code. The public point is rounded to about 110 m; the exact pin and address go to `request_private`. Show "We've notified N sellers". Then upload media to `request-media/{request_id}/...` and insert `request_media` rows |
| `close_request(p_request_id, p_status='cancelled', p_reason=null)` | `requests` | `cancelled` or `closed`; quoting sellers are notified |
| `get_my_quotes(p_tab=null, p_cursor=null, p_limit=20)` | `table(quote jsonb, request jsonb, order_id, chat_id, created_at, id)` | seller "My quotes": `p_tab` active, won, lost, or null for all |

Buyers read their requests and quotes directly:
`from('requests').select('*, quotes(*, quote_line_items(*))').eq('buyer_id', uid)`.

### Leads (seller)
| RPC | → | notes |
|---|---|---|
| `get_lead_feed(p_filters jsonb='{}', p_cursor jsonb=null, p_limit=20)` | `table(request_id, category_id, category_slug, category_names, title, description, fields, budget_min_minor, budget_max_minor, currency, needed_by, locality, city, state, location_code, audience, quote_count, max_quotes, priority_until, quote_window_ends_at, created_at, distance_m, media_count, is_invited, my_quote_id, my_quote_status, seen_at, required_licence_type)` | filters: `category_ids[]`, `max_distance_km`, `min_budget_minor`, `needed_by_before`, `audience`, `hide_quoted`, `include_dismissed`. Cursor `{created_at, id}`. Matches PostGIS radius, postal-code list, nationwide and invited sellers. Excludes blocked, full, closed, hidden and priority-window leads (unless the seller is verified or Pro) and restricted categories without a licence. Hidden budgets come back null |
| `get_request_for_seller(p_request_id)` | `jsonb` (safe request + `media[]` + `my_quote`) | lead detail; 404 when outside the seller's coverage |
| `dismiss_lead(p_request_id, p_dismiss=true)` | `void` | |
| `mark_leads_seen(p_request_ids uuid[])` | `void` | unread dots |

### Quotes
| RPC | → | notes |
|---|---|---|
| `submit_quote(p_request_id, p_line_items jsonb, p_delivery_minor=0, p_sales_tax_rate_bp=0, p_offered_brand_model=null, p_delivery_date=null, p_warranty=null, p_valid_days=null, p_notes=null, p_attachments text[]='{}', p_fields jsonb='{}')` | `quotes` | line item: `{description, qty, unit_price_minor, tax_rate_bp (India), hsn_sac}`. Totals are computed on the server. Checks: cap (10), priority window, coverage, category, licence, block, entitlement (`402 quota_exhausted`). Attachments go under `request-media/{request_id}/quotes/{seller_id}/` |
| `revise_quote(p_quote_id, p_line_items, …same as submit…)` | `quotes` | stores a `quote_revisions` snapshot; max `max_quote_revisions` |
| `withdraw_quote(p_quote_id)` | `quotes` | frees a slot under the cap |
| `shortlist(p_quote_id, p_on=true)` | `quotes` | buyer |
| `counter_offer(p_quote_id, p_target_minor, p_note=null)` | `quotes` | buyer |
| `decline_quote(p_quote_id, p_reason=null)` | `quotes` | buyer |
| `accept_quote(p_quote_id)` | `orders` | buyer: the request becomes `awarded`, other active quotes are declined and their sellers politely notified, the order and its chat are created, contacts unlock |

### Chat
| RPC | → | notes |
|---|---|---|
| `get_or_create_chat(p_request_id, p_seller_id=null)` | `chats` | buyer passes `p_seller_id`; seller passes null (only after quoting) |
| `open_chat(p_request_id, p_seller_id=null)` | `chats` | alias of `get_or_create_chat` |
| `mark_read(p_chat_id, p_up_to=null)` | `int` | |

Send messages with a direct insert:
`from('messages').insert({chat_id, sender_id: uid, type: 'text', body})`. For images, upload to
`chat-media/{chat_id}/{uuid}.jpg` first, then insert with `type: 'image'` and `attachment_path`.
For an offline queue, give every outgoing message a client-generated `client_id` (uuid) and send
(and retry) it with
`from('messages').upsert({chat_id, sender_id: uid, type, body, client_id}, onConflict: 'chat_id,client_id', ignoreDuplicates: true)`
(`INSERT … ON CONFLICT (chat_id, client_id) DO NOTHING`): a retry of a message that already arrived
creates nothing. Messages without `client_id` are unaffected.
The server flags phone numbers and emails before an order (`contains_contact`) and bumps the
chat preview.

### Orders, reviews, trust
| RPC | → | notes |
|---|---|---|
| `update_order_status(p_order_id, p_status, p_note=null, p_scheduled_for=null)` | `orders` | seller: scheduled, dispatched, delivered; either party: completed; cancel while accepted or scheduled |
| `record_payment(p_order_id, p_method, p_amount_minor)` | `orders` | offline payment note (cash, upi, card, bank_transfer, zelle, check, seller_link, other) |
| `get_order_contacts(p_order_id)` | `jsonb {buyer{name, phone, full_address}, seller{business_name, phone, email, website, address_line}}` | order parties only |
| `submit_review(p_order_id, p_stars, p_tags text[]='{}', p_text=null, p_photos text[]='{}')` | `reviews` | completed orders only, once |
| `seller_reply_review(p_review_id, p_reply)` | `reviews` | once |
| `report_content(p_target_type, p_target_id, p_reason, p_details=null)` | `reports` | target: request, quote, message, review, seller, user. Three distinct reports auto-hide the target |
| `mark_notifications_read(p_ids uuid[]=null)` | `int` | null = all |

### Admin (JWT `roles` claim must contain `admin`, and so must `profiles.roles`)
`admin_review_document(p_document_id, p_approve, p_reason=null, p_verify_seller=true) → seller_documents`,
`admin_set_seller_verification(p_seller_id, p_status, p_reason=null) → sellers`,
`admin_review_licence(p_licence_id, p_approve, p_reason=null) → seller_licences`,
`admin_resolve_report(p_report_id, p_action dismiss|hide|restore, p_note=null) → int`,
`admin_set_user_status(p_user_id, p_status active|suspended|banned, p_until=null, p_reason=null) → profiles`,
`admin_set_role(p_user_id, p_role, p_grant) → text[]`,
`admin_set_category_policy(p_category_id, p_policy, p_required_licence_type=null, p_disclaimer=null, p_policy_reason=null) → categories`,
`admin_upsert_category(p_id, p_slug, p_names, p_parent_id=null, p_field_schema=null, p_keywords=null, p_icon=null, p_sort=null, p_active=null) → categories`,
`admin_upsert_keyword(p_keyword, p_action block|suggest, p_category_id=null, p_lang='en', p_reason=null, p_active=true) → category_keywords`,
`admin_set_setting(p_key, p_value jsonb) → app_settings` (validated; the first `monetization_enabled=true` sets `early_partner_free_until = now() + 6 months` and stamps the early partners),
`admin_get_settings() → setof app_settings`,
`admin_grant_entitlement(p_seller_id, p_tier pro|credits, p_credits=0, p_expires_at=null, p_note=null) → entitlements`,
`admin_metrics() → jsonb`,
`admin_kpis() → jsonb` (Section 13 KPIs, see below),
`admin_seller_coverage(p_min_sellers=5) → table(city, state, category_id, sellers, needs_sellers)`,
`admin_outreach_set_stage(p_lead_id, p_stage, p_note=null) → outreach_leads` (see Outreach).

**Audit log.** Every admin RPC above that changes data writes one `admin_audit_log` row in the same
transaction: `{id, actor_id, actor_email, action (= the RPC name), target_type (document | licence |
report | user | seller | category | keyword | setting | entitlement | outreach_lead), target_id,
details (old/new values, reason, note), created_at}`. Triggers add rows for `outreach_leads` stage
changes (`outreach_stage_change`), `suppression_list` inserts (`suppression_add`),
`outreach_campaigns` creation and status changes (`outreach_campaign_create`,
`outreach_campaign_status`, including automatic brakes) and `brochures` inserts
(`brochure_create`); `outreach-send` adds `outreach_send_one`. Rows written without a user
(service role, cron, webhooks) have `actor_id = null` and `details.via` (`service_role` or
`system`). Admins read it with `from('admin_audit_log').select(...).order('created_at', ascending: false)`;
nobody can insert, update or delete through the API, and the table refuses updates and deletes
even for the owner (`audit_log_append_only`). Read-only RPCs (`admin_get_settings`, `admin_metrics`,
`admin_kpis`, `admin_seller_coverage`) are not logged.

**`admin_kpis()`** (admin only) returns, all keys optional (null = not enough data), percentages
0-100 with one decimal:

| key | meaning |
|---|---|
| `request_to_acceptance_pct` | requests created in the last 30 days that were awarded |
| `seller_response_rate_pct` | (seller, request) pairs notified as `new_lead` in the last 30 days that the seller quoted |
| `free_to_paid_pct` | sellers with a store-paid entitlement (any store except `manual`) / all sellers |
| `retention` | `{buyer_d1, buyer_d7, buyer_d30, seller_d1, seller_d7, seller_d30}`: rolling retention of users who signed up in the 30 days ending n days ago, active on or after day n (activity = request, chat message, quote, lead opened, push token refresh); review accounts excluded |
| `revenue_30d_minor`, `revenue_per_seller_minor` | estimate: `kpi_product_prices_minor` × store entitlements with a billing event in the last 30 days (per seller = / visible sellers); null until prices are set |
| `refunds_30d` | entitlements refunded in the last 30 days |
| `outreach_sent_today` | outreach sends since 00:00 UTC |
| `outreach_daily_capacity` | sum of active inboxes' warm-up caps, bounded by `outreach_global_daily_cap` |
| `outreach_queue` | leads still in the automated pipeline (sourced/contacted, sequence none/active, < 3 touches, not a seller) |
| `outreach_reply_rate_pct`, `outreach_signup_rate_pct` | contacted leads that replied / became sellers |
| `outreach_active_campaigns`, `outreach_business_address_ready`, `computed_at` | extras for the outreach dashboard |

Outreach CRM (admin or service): `outreach_can_send(p_lead_id, p_channel='email', p_inbox_id=null, p_at=now()) → table(allowed, reason)`,
`outreach_next_batch(p_campaign_id, p_limit=20, p_at=now())`, `outreach_record_send(…)`,
`outreach_record_event(p_event_type, p_provider_message_id=null, p_email=null, p_meta='{}', p_channel='email') → uuid`,
`outreach_upsert_lead(p_lead jsonb) → uuid|null` (null = duplicate business),
`outreach_check_brakes(p_campaign_id) → jsonb`, `outreach_is_suppressed(p_email, p_phone, p_business_key) → bool`.
The admin panel logs manual WhatsApp, call and visit touches by inserting `outreach_events` with
event types `whatsapp_manual`, `call_logged`, `visit_logged` or `note`.

#### Outreach (Section 21.2 / 21.5 / 21.8)

**Automated email sequences** run exactly as Section 21.2 describes: pg_cron calls
`outreach-send {action: "run"}` every 10 minutes on weekdays (only while `outreach_enabled`), and
each run sends due touches of a 1-3 step sequence to business leads, with per-inbox warm-up caps,
per-domain and global daily caps, campaign daily caps, weekday business hours in the lead's time
zone, randomised pacing, template rotation and automatic brakes (bounce > 2 %, complaints > 0.08 %,
negative replies > 5 % pause the campaign). On top of that, nothing is sent until a person turns a
campaign on:

- **Every new campaign is created paused.** An insert into `outreach_campaigns` always stores
  `status = 'draft'` (a `'paused'` insert stays paused), whatever status the caller passes.
- **Only an admin activates.** Changing `status` to `active` needs an admin JWT (the panel's
  `update outreach_campaigns set status = 'active'`); the server stamps `activated_by` and
  `activated_at`. The service role, cron, Edge Functions and direct SQL sessions get
  `403 campaign_activation_requires_admin`. Leaving `active` (manual pause, automatic brake,
  content-check pause, `completed`) clears the stamp, so a paused campaign needs a new admin
  activation.
- **The cron run only processes campaigns an admin explicitly set to active** (`status = 'active'`
  and `activated_by` set). `outreach_can_send` answers `campaign_draft`, `campaign_paused`,
  `campaign_completed` or `campaign_not_activated` otherwise, and the `outreach_events` trigger
  refuses to record a send for such a campaign (`409 outreach_campaign_not_active`).

**Business address.** `app_settings.outreach_business_address` (admin only) is the physical postal
address printed in every outreach email (CAN-SPAM, rule 21.8-8). It ships as the placeholder
`"{{BUSINESS_ADDRESS}}"`. While it is empty, shorter than 10 characters or contains `{{` / `}}`,
`outreach_can_send` answers `business_address_missing`, the `run` action skips with
`{skipped: "business_address_missing"}`, `send_one` refuses, and recording a send fails with
`409 outreach_business_address_missing`. `outreach-send` builds the footer from this setting (not
from an env variable). Set it with `admin_set_setting('outreach_business_address', '"…"')`.

`outreach_can_send` reasons (first failing rule wins): `outreach_disabled`,
`business_address_missing`, `lead_not_found`, `suppressed`, `already_seller`, `stage_<stage>`,
`max_touches`, `conversation_finished`, `remind_later`, `not_relevant`, `no_email`,
`email_not_verified`, `unknown_address_source`, `no_opt_in`, `weekly_cap`, `channel_not_automated`,
`no_campaign`, `campaign_<status>`, `campaign_not_activated`, `sequence_done`, `not_due`,
`outside_business_hours`, `global_daily_cap`, `campaign_daily_cap`, `domain_daily_cap`,
`inbox_inactive`, `inbox_daily_cap`, or `ok`.

**Stage moves.** `admin_outreach_set_stage(p_lead_id, p_stage, p_note=null)` is the only way the
panel moves a lead. Forward-only edges (same as `admin/lib/features/outreach/domain/stage_machine.dart`):

| from | allowed to |
|---|---|
| `sourced` | `contacted`, `replied`, `not_interested`, `do_not_contact` |
| `contacted` | `replied`, `onboarding`, `not_interested`, `do_not_contact` |
| `replied` | `onboarding`, `not_interested`, `do_not_contact` |
| `onboarding` | `live_seller`, `not_interested`, `do_not_contact` |
| `live_seller` | `active`, `do_not_contact` |
| `active` | `do_not_contact` |
| `not_interested` | `replied`, `do_not_contact` |
| `do_not_contact` | nothing (permanent) |

`live_seller` / `active` need `seller_id`; a manual move to `contacted` needs a logged
`whatsapp_manual`, `call_logged` or `visit_logged` event. Moves to replied, onboarding, live seller,
active or not interested stop a running sequence; `do_not_contact` stops it and adds the email,
phone and business key to `suppression_list`. Each move inserts a `stage_change` event (note in
`body_preview`, `{from, to}` in `meta`) and one audit row. Errors: `400 invalid_stage`,
`404 lead_not_found`, `409 stage_no_change | stage_terminal | stage_not_allowed |
stage_needs_seller_link | stage_needs_logged_contact`.

Service role only (Edge Functions): `match_sellers_for_request`, `claim_due_notifications`,
`mark_notifications_pushed`, `delete_device_tokens`, `record_billing_event`, `apply_entitlement`,
`outreach_unsubscribe`, `edge_rate_limit_hit`.

## 4. Storage buckets

| Bucket | Public | Path | Who writes | Who reads | Limit / types |
|---|---|---|---|---|---|
| `seller-media` | yes | `{user_id}/...` | owner | everyone | 5 MB; jpeg, png, webp |
| `request-media` | no | `{request_id}/...` (buyer media) and `{request_id}/quotes/{seller_id}/...` (quote attachments) | request buyer while open; quoting seller in their own folder | buyer, sellers who can see the lead, admin | 25 MB; jpeg, png, webp, mp4, mov, pdf |
| `verification-docs` | no | `{seller_id}/...` | the seller | the seller, admin | private documents |
| `chat-media` | no | `{chat_id}/...` | chat members | chat members, admin | images |
| `brochures` | yes | admin-defined | admin | everyone | 10 MB; pdf, png, jpeg, webp |

Use signed URLs (`createSignedUrl`, about 1 h) for the private buckets. Compress images on the
device before upload (max 1600 px, quality 80).

## 5. Realtime

`postgres_changes` (RLS-filtered) on `requests`, `quotes`, `messages`, `chats`, `orders`, `notifications`:

| Screen | Subscription |
|---|---|
| Buyer request detail | `quotes` filter `request_id=eq.{id}` (new and revised quotes) and `requests` filter `id=eq.{id}` |
| Chat | `messages` filter `chat_id=eq.{id}` |
| Chat list | `chats` (RLS gives only your chats) |
| Order detail / list | `orders` filter `id=eq.{id}` (or none for the list; RLS gives only your orders as buyer or seller) |
| Inbox badge | `notifications` filter `user_id=eq.{uid}` |
| Seller lead feed | **broadcast** channel `seller:{seller_id}`, event `new_lead`, payload `{request_id, category_id, created_at}`, sent by `match-request` when the lead is matched. Re-query `get_lead_feed` (no PII in the payload) |

Use a single channel per screen and unsubscribe on dispose. The broadcast channel is public
(`private: false`); it carries ids only.

## 6. Edge Functions

Base URL `https://<ref>.supabase.co/functions/v1/`. Call them from the app with
`supabase.functions.invoke(name, body: {...})`, which sends the user JWT. Mobile clients should
also send `X-Firebase-AppCheck` (enforced when `APP_CHECK_ENFORCE=true`).

| Function | Caller / auth | Request | Response |
|---|---|---|---|
| `delete-account` | user JWT (+ App Check) | `{apple_authorization_code?, apple_refresh_token?, apple_client_id?}`. Re-run Sign in with Apple on the confirm screen and send the fresh authorization code | `{deleted: true, apple_revoked: bool\|null, summary}` |
| `create-checkout` | seller JWT | `{product_id: seller_pro_monthly\|seller_pro_annual\|credits_10\|credits_50, success_url?, cancel_url?}` or `{action: "portal", return_url?}` (USA) | `{url, provider: stripe\|razorpay, product_id}`. Open `url` in the browser. Entitlements arrive by webhook; refresh with `get_my_entitlement` |
| `play-rtdn` | Pub/Sub push (OIDC) **or** user JWT with `{action: "verify", product_id, purchase_token, kind: "subs"\|"inapp"}` | | `{seller_id}` or `{sellerId, granted}`. Set `obfuscatedAccountId = user id` when purchasing. The server acknowledges or consumes the purchase |
| `appstore-notifications` | App Store (`{signedPayload}`) **or** user JWT with `{action: "verify", signed_transaction}` (StoreKit 2 `jwsRepresentation`) | | `{seller_id}`. Set `appAccountToken = user id` when purchasing. Chain verification is still a TODO (see section 11) |
| `stripe-webhook` | Stripe signature | Stripe event | `{received, applied}` |
| `razorpay-webhook` | Razorpay signature | Razorpay event | `{received, applied}` |
| `match-request` | database trigger (`x-webhook-secret`) | `{record: {id}}` or `{request_id}` | `{matched, pushed_now, queued, failed}` |
| `send-push` | trigger and cron (`x-webhook-secret`) | `{action: "flush_due", limit?}` | `{claimed, pushes, sent, skipped, failed, tokens_deleted}` |
| `outreach-send` | cron (`x-webhook-secret`) or admin JWT; `send_one`: admin JWT only | `{action: run\|preview\|verify_emails, campaign_id?, limit?}` or `send_one` (below) | per-campaign report (`preview` renders without sending; `run` only touches admin-activated campaigns) / `send_one`: `{ok: true, event_id, provider_message_id}` or `{ok: false, reason, problems?}` |
| `outreach-webhook` | Resend (Svix), Brevo (`?provider=brevo&secret=`), or `x-webhook-secret` | provider event, or `{type: "reply", from, text, in_reply_to?}`; `GET/POST ?action=unsubscribe&token=` | `{event}` / HTML page |
| `import-leads` | admin JWT or `x-webhook-secret` | `{source: osm\|places, city: {name, state?, lat, lng, city_id?, timezone?, priority?} \| {city_id}, radius_m?=15000, category_slugs?, max_results?=200, dry_run?}` | `{found, upserted, duplicates, places_requests}` |
| `brochure-link` | admin JWT | `{city?, category_id?\|category_slug?, language?, format?: pdf\|image\|onepager (default pdf; png = image), source?, campaign?, lead_id?}` | `{signup_url, brochure: {url, version, storage_path, format}\|null}`; unknown format: `400 invalid_format` |
| `web-forms` | websites (CORS allow-list + Turnstile) | see below | `{ok: true}` |

### `outreach-send` action `send_one` (admin panel)

One lead, one admin-reviewed message, one explicit confirmation. Never called by cron: the webhook
secret or service key is not accepted for this action (`401`/`403`).

```json
{ "action": "send_one", "lead_id": "uuid", "campaign_id": "uuid|null", "inbox_id": "uuid|null",
  "channel": "email|whatsapp", "step": 1, "variant": 0, "category_id": 4,
  "subject": "...", "body": "...", "footer": "client preview only",
  "whatsapp_template": "approved_template_name|null", "confirmed_by_admin": true }
```

The function checks, in order, and answers `200 {ok: false, reason}` at the first failure (nothing
is sent): `confirmed_by_admin` must be `true` (`not_confirmed_by_admin`); request shape
(`invalid_lead_id`, `channel_not_allowed`, `invalid_step`, `inbox_required`,
`subject_and_body_required`, `message_too_long`); `outreach_disabled`; `business_address_missing`;
`outreach_identity_not_configured`; `lead_not_found`; `step` must be the lead's next touch
(`step_mismatch`); the lead's campaign must exist, match `campaign_id` and be admin-activated
(`no_campaign`, `campaign_mismatch`, `campaign_<status>`, `campaign_not_activated`); `category_id`
must be one of the lead's matched categories (`not_relevant`); the inbox must be active and in the
campaign (`inbox_inactive`, `inbox_not_in_campaign`); email content rules on the edited subject and
body (`content_check_failed:<problems>` plus `problems[]`: length, links, question CTA, caps, spam
phrases, personalisation, no fake `Re:`, no brochure link in touch 1); WhatsApp: an approved
template (`whatsapp_template_required`, `invalid_whatsapp_template`,
`whatsapp_template_not_approved` against `WHATSAPP_APPROVED_TEMPLATES`) and a phone (`no_phone`);
then `outreach_can_send(lead, channel, inbox)` (its reason is returned as is). The function builds
its own identity footer (postal address from `outreach_business_address`) and List-Unsubscribe
headers; the client `footer` is ignored. It sends (email provider, or the WhatsApp Cloud API
template), records the send with `outreach_record_send` (the database re-checks the hard rules),
stamps the admin on the event (`created_by`, `meta.via = "send_one"`) and writes an
`outreach_send_one` audit row. Provider failure: `send_failed`; sent but refused by the database:
`sent_not_recorded`.

Secrets/config for WhatsApp: `WHATSAPP_PROVIDER` (`cloud` | `dry_run`, default dry run),
`WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_GRAPH_VERSION`,
`WHATSAPP_TEMPLATE_LANGUAGE`, `WHATSAPP_APPROVED_TEMPLATES` (comma separated). Templates are sent
without parameters.

### `web-forms` (websites in `web/`)

`POST /functions/v1/web-forms`, `Content-Type: application/json`, from an origin in
`WEB_FORMS_ALLOWED_ORIGINS` (others get 403; preflight answers 204 only for allowed origins).

```json
{ "form": "seller_signup | contact | waitlist | account_deletion | trends_contact",
  "country": "usa | india", "page": "/sellers", "submitted_at": "ISO",
  "fields": { "...": "..." }, "consents": [{ "key": "consent_email", "text": "exact wording shown" }],
  "honeypot": "", "turnstile_token": "..." }
```

Processing order:

1. Honeypot not empty: `200 {ok:true}`, and nothing is stored.
2. Per-IP rate limit: `WEB_FORMS_RATE_LIMIT` (5) per 10 minutes. When hit, the answer is `429`
   with `Retry-After`. It uses Upstash, or the Postgres fallback `edge_rate_limit_hit`.
3. Turnstile siteverify with `TURNSTILE_SECRET_KEY`. The widget `action` must equal `form`. The
   hostname must be in `TURNSTILE_ALLOWED_HOSTNAMES`, and the token at most 5 minutes old.
   Failure answers `403 captcha_failed`.
4. Field validation: only known fields are kept. Errors are `400` with code `missing_field`,
   `invalid_email`, `invalid_phone`, `invalid_url`, `invalid_postal_code`, `field_too_long`,
   `consent_required`, `wrong_country` or `unknown_form`, and the field name in `details`.

Then every submission is stored in `web_form_submissions` (the IP only as a salted hash). Every
consent goes to `consents` with its exact text, key, form, page and `accepted_at`.

| form | fields | effect |
|---|---|---|
| `seller_signup` | business_name, contact_name, email, phone, city, postal_code, category (slug), website?; consents `consent_contact` (required), `consent_whatsapp` | inbound CRM lead via `outreach_upsert_lead` (`source=inbound`, `lawful_basis=inbound_request`, next action "call back"). A WhatsApp opt-in is stored with its proof. Admins are notified |
| `contact`, `trends_contact` | name/email/topic/message (trends: topic, article?, email?, message) | stored, admins notified (`web_contact`) |
| `waitlist` | email, city, postal_code?, whatsapp?, source; consent `consent_email` (required), `consent_whatsapp` | **double opt-in**: a pending `waitlist_signups` row plus a hashed token (72 h). Only the confirmation email is sent (`TRANSACTIONAL_EMAIL_PROVIDER`; stubbed and logged when unset). `GET ?action=confirm_waitlist&token=` confirms (consents get `confirmed_at`, the WhatsApp opt-in is recorded) and redirects to `WAITLIST_CONFIRMED_URL`. `GET ?action=unsubscribe_waitlist&token=<unsubscribe_token>` withdraws |
| `account_deletion` | email?, phone? (one required), reason?; consent `confirm_delete` | creates `account_deletion_requests`. If the account has a phone, an OTP is sent to the **registered** phone through Supabase Auth (`status=otp_sent`); otherwise `manual_review` and admins are notified. The response is always `{ok:true, request_id}` (no account enumeration) |

Second step of account deletion (add an OTP box on the page after the first submit):
`POST {"action":"confirm_deletion","request_id":"…","otp":"123456"}`. It allows 5 attempts and
the code is valid for 15 minutes, with a per-IP limit of 10 per hour. It answers
`200 {ok:true, deleted:true}` or `400 invalid_or_expired_code`. On success it runs the same
anonymisation as in the app (`delete_my_account`) and soft-deletes the auth user.

Secrets: `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, `WEB_FORMS_ALLOWED_ORIGINS`,
`WEB_FORMS_RATE_LIMIT`, `WEB_FORMS_PUBLIC_URL`, `IP_HASH_SALT`, `WAITLIST_CONFIRMED_URL`,
`TRANSACTIONAL_EMAIL_PROVIDER`, `TRANSACTIONAL_FROM_EMAIL`, `TRANSACTIONAL_FROM_NAME` (plus
`RESEND_API_KEY` / `BREVO_API_KEY` / `AWS_*` for the chosen provider) and optionally
`UPSTASH_REDIS_REST_URL` / `_TOKEN`. If the function is served from a custom domain, add it to
`connect-src` in the sites' CSP.

## 7. Notifications (inbox + push)

Rows in `notifications` (`type`, `payload`, `read_at`). Push `data` carries `type`, `route` and
the ids. The app deep-links with `payload.route`.

| type | to | payload | route |
|---|---|---|---|
| `new_lead` | seller | request_id, title, category_id, city | `/seller/leads/{request_id}` (digest: `/seller/leads`) |
| `new_quote` | buyer | request_id, quote_id, title, seller_name, total_minor, currency, quote_number | `/r/{request_id}` (from the 4th quote, merged per 15 min) |
| `quote_revised` | buyer | request_id, quote_id, title | `/q/{quote_id}` |
| `message` | other party | chat_id, request_id, message_id, preview | `/chat/{chat_id}` |
| `quote_window_ending` | buyer | request_id, title | `/r/{request_id}` |
| `shortlisted`, `quote_declined`, `counter_offer`, `quote_not_selected`, `request_closed` | seller | request_id, quote_id, title (+reason / target) | `/seller/quotes/{quote_id}` |
| `quote_accepted` | seller | request_id, quote_id, order_id, title | `/orders/{order_id}` |
| `quote_expiring` | seller | quote_id, request_id | `/seller/quotes/{quote_id}` |
| `order_status` | other party | order_id, status, request_id | `/orders/{order_id}` |
| `review_reminder` | buyer | order_id | `/orders/{order_id}/review` |
| `new_review` | reviewed party | review_id, order_id, stars | `/reviews/{review_id}` |
| `seller_verified`, `verification_rejected`, `licence_approved`, `licence_rejected`, `licence_expiring`, `licence_expired` | seller | reason, licence_id | `/seller/profile`, `/seller/verification` |
| `outreach_brake`, `outreach_reply`, `web_contact`, `web_seller_signup`, `account_deletion_request` | admins | campaign_id / from / submission_id | `/admin/...` |

Seller lead pushes respect the priority window (verified and Pro sellers first), `notify_mode`
(instant, hourly, daily at 09:00 local) and quiet hours (default 22:00 to 07:00 local). A user
with `notification_prefs.push = false` still gets inbox rows but no push. Android channels:
`leads`, `quotes`, `chat`, `orders`, `account`.

## 8. Payments and entitlements

Products: `seller_pro_monthly`, `seller_pro_annual` (tier `pro`) and `credits_10`, `credits_50`
(tier `credits`). The ids are the same in Play, the App Store, Stripe and Razorpay. Every store
writes `entitlements` via `apply_entitlement`, idempotent per `billing_events(provider, event_id)`.
The app never writes entitlements. It reads `get_my_entitlement()`.

Status values: `pending, active, grace, on_hold, paused, cancelled, expired, revoked, refunded`.
Show "fix your payment" for `grace` and `on_hold`. A quote is billed in this order:
early partner (until `free_until`), active Pro, free tier (N per calendar month), then one credit.
Otherwise the answer is `402 quota_exhausted`.

## 9. Error codes (message → meaning; HTTP from PTnnn)

- **400:** `business_name_required, cannot_block_self, cannot_change_own_status, category_not_leaf, invalid_action, invalid_amount, invalid_area_type, invalid_audience, invalid_budget, invalid_delivery_amount, invalid_field_value, invalid_fields, invalid_file_path, invalid_line_item, invalid_location, invalid_mode, invalid_payment_method, invalid_policy, invalid_stage, invalid_postal_code, invalid_quote_window, invalid_reason, invalid_role, invalid_sales_tax_input, invalid_seller_profile, invalid_setting_value, invalid_stars, invalid_status, invalid_target_price, invalid_target_type, invalid_tier, invalid_validity, licence_details_required, licence_type_required, line_items_required, location_required, missing_required_field (details = field key), needed_by_in_past, reply_required, seller_required, title_too_short, too_many_categories, too_many_line_items, too_many_service_codes`
- **401:** `not_authenticated`
- **402:** `quota_exhausted`
- **403:** `account_not_active, admin_only, audit_log_append_only, campaign_activation_requires_admin, blocked, cannot_quote_own_request, category_blocked, chat_not_allowed, licence_required, not_a_seller, priority_window, request_not_in_service_area, seller_suspended`
- **404:** `category_not_found, chat_not_found, document_not_found, lead_not_found, licence_not_found, order_not_found, quote_not_found, report_not_found, request_not_found, review_not_found, seller_not_found, unknown_setting, user_not_found`
- **409:** `already_quoted, already_replied, already_reviewed, duplicate_request, invalid_status_transition, order_cancelled, order_not_completed, quote_cap_reached, quote_expired, quote_not_acceptable, quote_not_counterable, quote_not_declinable, quote_not_revisable, quote_not_shortlistable, quote_not_withdrawable, quote_window_closed, request_not_open, revision_limit_reached`, outreach: `outreach_suppressed, outreach_max_touches, outreach_conversation_finished, outreach_email_not_verified, outreach_no_opt_in, outreach_business_address_missing, outreach_campaign_not_active, stage_no_change, stage_terminal, stage_not_allowed, stage_needs_seller_link, stage_needs_logged_contact`
- **422:** `blocked_content (details: matched keyword reason), category_blocked, invalid_ein, invalid_gstin, invalid_or_blocked_category, invalid_udyam, licence_expired, unknown_postal_code`
- **429:** `rate_limited`
- **Edge Functions** also use: `invalid_json, method_not_allowed, invalid_token, invalid_webhook_secret, invalid_signature, app_check_failed, unknown_product, product_not_configured, no_billing_account, portal_not_available, captcha_failed, origin_not_allowed, invalid_or_expired_code, invalid_format, internal_error`.

## 10. Test accounts

Fictional numbers, code `123456`, set in `config.toml [auth.sms.test_otp]` (local) and the
dashboard (hosted; production only the review accounts):
USA `+15555550100` buyer, `…0101` seller, `…0102` verified seller, `…0103` admin, `…0104` and
`…0105` store review; India `+910000000001` to `…0004` (same roles), `…0005` and `…0006` store
review. Demo data (sellers, requests, quotes, orders) is created by `seed/<country>_demo.sql`
for local and staging only.

## 11. Known gaps

- **Sales tax precision:** integer basis points cannot represent 8.875 % (New York City). The
  demo uses 888. Fixing it needs a finer unit (for example hundredths of a basis point) changed
  in SQL, TypeScript, Dart and the fixtures together.
- **App Store JWS:** `appstore-notifications` verifies the signature with the leaf certificate
  but not yet the x5c chain to Apple Root CA G3. Production refuses notifications until that is
  added (`APPSTORE_ALLOW_UNVERIFIED_CHAIN=true` only on staging).
- The `seller:{id}` broadcast is a public channel carrying ids only. Moving it to private
  channels with `realtime.messages` RLS is a later hardening step.
