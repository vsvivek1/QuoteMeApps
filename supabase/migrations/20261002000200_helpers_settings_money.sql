-- 0200 Generic helpers: updated_at trigger, error helper, app_settings,
-- rate limits, money / tax rounding helpers.
set search_path = public, extensions;

-- updated_at ----------------------------------------------------------------
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- Attach created_at/updated_at trigger to a table (used by later migrations).
create or replace function private.add_updated_at_trigger(p_table regclass)
returns void
language plpgsql
set search_path = ''
as $$
begin
  execute format(
    'create or replace trigger set_updated_at before update on %s
       for each row execute function private.set_updated_at()', p_table);
end $$;

-- Errors ----------------------------------------------------------------------
-- All RPCs raise errors with a stable machine-readable MESSAGE (e.g.
-- 'quota_exhausted') and an SQLSTATE of the form PTnnn, which PostgREST maps
-- to HTTP status nnn. See supabase/API.md "Errors".
create or replace function private.raise_error(
  p_code text, p_http int default 400, p_detail text default null, p_hint text default null)
returns void
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = 'PT' || p_http::text,
    message = p_code,
    detail = coalesce(p_detail, p_code),
    hint = coalesce(p_hint, '');
end $$;

-- app_settings ----------------------------------------------------------------
create table public.app_settings (
  key text primary key,
  value jsonb not null,
  description text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.app_settings enable row level security;
select private.add_updated_at_trigger('public.app_settings');

create or replace function private.setting(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select value from public.app_settings where key = p_key
$$;

create or replace function private.setting_int(p_key text, p_default int)
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::int from public.app_settings where key = p_key
                   and jsonb_typeof(value) = 'number'), p_default)
$$;

create or replace function private.setting_bool(p_key text, p_default boolean)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = p_key
                   and jsonb_typeof(value) = 'boolean'), p_default)
$$;

create or replace function private.setting_text(p_key text, p_default text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select value #>> '{}' from public.app_settings where key = p_key
                   and jsonb_typeof(value) <> 'null'), p_default)
$$;

create or replace function private.setting_ts(p_key text)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
  select (select (value #>> '{}')::timestamptz from public.app_settings where key = p_key
          and jsonb_typeof(value) = 'string')
$$;

-- Defaults shared by both countries. Country seeds override country-specific
-- values (country, currency, free_quotes_per_month, default_timezone).
insert into public.app_settings (key, value, is_public, description) values
  ('country', '"IN"', true, 'ISO country of this project: IN or US (set by seed/<country>.sql)'),
  ('currency', '"INR"', true, 'ISO currency of this project'),
  ('default_timezone', '"Asia/Kolkata"', true, 'Fallback time zone for quiet hours / business hours'),
  ('monetization_enabled', 'false', true, 'Section 7 switch. false = all seller features free'),
  ('early_partner_free_until', 'null', true, 'Timestamp until which early partners stay free; set automatically to now()+6 months when monetization is first enabled'),
  ('free_quotes_per_month', '10', true, 'Free tier quotes per seller per calendar month after monetization'),
  ('quote_cap', '10', true, 'Default max quotes per request'),
  ('priority_window_minutes', '15', true, 'Verified-first priority window on new requests'),
  ('max_requests_per_buyer_per_day', '10', true, 'Rate limit for create_request (rolling 24h)'),
  ('max_quotes_per_seller_per_hour', '20', true, 'Rate limit for submit_quote'),
  ('lead_feed_per_minute', '120', false, 'Rate limit for get_lead_feed per seller'),
  ('duplicate_window_hours', '24', false, 'Duplicate request detection window'),
  ('auto_hide_report_threshold', '3', false, 'Distinct open reports before content is auto-hidden'),
  ('request_expire_days_after_window', '14', false, 'Open requests expire this many days after the quote window ends'),
  ('quote_valid_days_default', '7', true, 'Default quote validity'),
  ('max_quote_revisions', '5', true, 'Max revisions per quote'),
  ('match_push_cap', '200', false, 'Max sellers notified per new request'),
  ('licence_expiry_warn_days', '30', false, 'Warn sellers this many days before licence expiry'),
  ('edge_functions_url', 'null', false, 'Base URL for Edge Functions, e.g. https://<ref>.supabase.co/functions/v1 (used by pg_net webhooks)'),
  ('outreach_enabled', 'false', false, 'Section 21 feature flag'),
  ('outreach_global_daily_cap', '50', false, 'Global daily ceiling for automated outreach emails (never lifts automatically)'),
  ('outreach_per_domain_daily_cap', '2', false, 'Max outreach emails per recipient domain per day'),
  ('outreach_bounce_brake_pct', '2', false, 'Pause campaign above this bounce %'),
  ('outreach_complaint_brake_pct', '0.08', false, 'Pause campaign above this complaint %'),
  ('outreach_negative_brake_pct', '5', false, 'Pause campaign above this negative-reply %'),
  ('outreach_uncontacted_retention_days', '90', false, 'Delete uncontacted imported leads after N days (DPDP)'),
  ('places_monthly_budget_usd', '150', false, 'Hard cap for Google Places spend per month'),
  ('places_cost_per_request_usd', '0.032', false, 'Cost estimate per Places Text Search request')
on conflict (key) do nothing;

-- rate_limits -----------------------------------------------------------------
-- Fixed-window counters for expensive RPCs. Key example: 'lead_feed:<uid>'.
create table public.rate_limits (
  key text not null,
  window_start timestamptz not null,
  count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (key, window_start)
);
alter table public.rate_limits enable row level security;
select private.add_updated_at_trigger('public.rate_limits');

-- Returns true when the call is allowed (and counts it), false when limited.
create or replace function private.rate_limit_hit(p_key text, p_limit int, p_window_seconds int)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_window timestamptz := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  v_count int;
begin
  insert into public.rate_limits as r (key, window_start, count)
  values (p_key, v_window, 1)
  on conflict (key, window_start) do update set count = r.count + 1
  returning count into v_count;
  return v_count <= p_limit;
end $$;

-- Money and tax rounding --------------------------------------------------------
-- Contract shared with Dart (lib/core/money) and Edge Functions (_shared/money.ts):
--   * all amounts are non-negative integers in minor units (paise / cents)
--   * tax rates are integers in basis points (18% = 1800, 8.25% = 825)
--   * round_half_up(n, d) = (2n + d) div (2d)            (n >= 0, d > 0)
--   * India GST per line: base = qty * unit_price_minor
--       intra-state: cgst = sgst = round_half_up(base * rate_bp, 20000)
--       inter-state: igst = round_half_up(base * rate_bp, 10000)
--   * USA sales tax on the subtotal only: round_half_up(subtotal * rate_bp, 10000)
--   * total = subtotal + tax + delivery (delivery is not taxed in the MVP)
create or replace function public.money_round_half_up(p_numerator numeric, p_denominator numeric)
returns bigint
language plpgsql
immutable
strict
set search_path = ''
as $$
begin
  if p_numerator < 0 or p_denominator <= 0 then
    raise exception using errcode = 'PT400', message = 'invalid_money_rounding_input';
  end if;
  return floor((2 * p_numerator + p_denominator) / (2 * p_denominator))::bigint;
end $$;

create or replace function public.gst_line_tax(
  p_qty numeric, p_unit_price_minor bigint, p_rate_bp int, p_intra_state boolean,
  out base_minor bigint, out cgst_minor bigint, out sgst_minor bigint,
  out igst_minor bigint, out tax_minor bigint)
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_qty is null or p_qty <= 0 or p_unit_price_minor is null or p_unit_price_minor < 0
     or p_rate_bp is null or p_rate_bp < 0 or p_rate_bp > 10000 then
    raise exception using errcode = 'PT400', message = 'invalid_line_item';
  end if;
  -- qty may be fractional (e.g. 2.5 kg); the base is rounded half up to the paisa.
  base_minor := public.money_round_half_up(p_qty * p_unit_price_minor, 1);
  if coalesce(p_intra_state, true) then
    cgst_minor := public.money_round_half_up(base_minor::numeric * p_rate_bp, 20000);
    sgst_minor := cgst_minor;
    igst_minor := 0;
  else
    cgst_minor := 0;
    sgst_minor := 0;
    igst_minor := public.money_round_half_up(base_minor::numeric * p_rate_bp, 10000);
  end if;
  tax_minor := cgst_minor + sgst_minor + igst_minor;
end $$;

create or replace function public.us_sales_tax(p_subtotal_minor bigint, p_rate_bp int)
returns bigint
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_subtotal_minor is null or p_subtotal_minor < 0 or p_rate_bp is null
     or p_rate_bp < 0 or p_rate_bp > 10000 then
    raise exception using errcode = 'PT400', message = 'invalid_sales_tax_input';
  end if;
  return public.money_round_half_up(p_subtotal_minor::numeric * p_rate_bp, 10000);
end $$;

-- Computes a full quote from line items. Used by submit_quote/revise_quote and
-- exposed so the client can preview totals with the exact server logic.
-- p_lines: [{"description": text, "qty": number, "unit_price_minor": int,
--            "tax_rate_bp": int (India only), "hsn_sac": text}]
create or replace function public.compute_quote_totals(
  p_country text, p_lines jsonb, p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default 0, p_intra_state boolean default true)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_line jsonb;
  v_lines jsonb := '[]'::jsonb;
  v_sub bigint := 0;
  v_tax bigint := 0;
  v_cgst bigint := 0; v_sgst bigint := 0; v_igst bigint := 0;
  v_rate int;
  v_max_rate int := 0;
  r record;
  v_breakdown jsonb;
begin
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then
    raise exception using errcode = 'PT400', message = 'line_items_required';
  end if;
  if jsonb_array_length(p_lines) > 50 then
    raise exception using errcode = 'PT400', message = 'too_many_line_items';
  end if;
  if coalesce(p_delivery_minor, 0) < 0 then
    raise exception using errcode = 'PT400', message = 'invalid_delivery_amount';
  end if;

  for v_line in select * from jsonb_array_elements(p_lines) loop
    v_rate := case when upper(p_country) = 'IN' then coalesce((v_line->>'tax_rate_bp')::int, 0) else 0 end;
    select * into r from public.gst_line_tax(
      (v_line->>'qty')::numeric, (v_line->>'unit_price_minor')::bigint, v_rate, p_intra_state);
    v_sub := v_sub + r.base_minor;
    if upper(p_country) = 'IN' then
      v_cgst := v_cgst + r.cgst_minor;
      v_sgst := v_sgst + r.sgst_minor;
      v_igst := v_igst + r.igst_minor;
      v_tax := v_tax + r.tax_minor;
      v_max_rate := greatest(v_max_rate, v_rate);
    end if;
    v_lines := v_lines || jsonb_build_object(
      'description', coalesce(v_line->>'description', ''),
      'qty', (v_line->>'qty')::numeric,
      'unit_price_minor', (v_line->>'unit_price_minor')::bigint,
      'tax_rate_bp', v_rate,
      'hsn_sac', v_line->>'hsn_sac',
      'line_total_minor', r.base_minor,
      'tax_minor', case when upper(p_country) = 'IN' then r.tax_minor else 0 end);
  end loop;

  if upper(p_country) = 'IN' then
    v_breakdown := jsonb_build_object(
      'kind', 'gst',
      'mode', case when coalesce(p_intra_state, true) then 'intra' else 'inter' end,
      'rate_bp', v_max_rate,
      'cgst', v_cgst, 'sgst', v_sgst, 'igst', v_igst);
  else
    v_tax := public.us_sales_tax(v_sub, coalesce(p_sales_tax_rate_bp, 0));
    v_breakdown := jsonb_build_object(
      'kind', 'sales_tax', 'rate_bp', coalesce(p_sales_tax_rate_bp, 0), 'amount', v_tax);
  end if;

  return jsonb_build_object(
    'lines', v_lines,
    'subtotal_minor', v_sub,
    'tax_minor', v_tax,
    'tax_breakdown', v_breakdown,
    'delivery_minor', coalesce(p_delivery_minor, 0),
    'total_minor', v_sub + v_tax + coalesce(p_delivery_minor, 0));
end $$;

grant execute on function public.money_round_half_up(numeric, numeric),
  public.gst_line_tax(numeric, bigint, int, boolean),
  public.us_sales_tax(bigint, int),
  public.compute_quote_totals(text, jsonb, bigint, int, boolean)
  to anon, authenticated, service_role;
