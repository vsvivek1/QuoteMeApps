-- 1050 US sales tax in parts per million (ppm).
--
-- Integer basis points cannot express rates such as New York City's 8.875 %. US sales tax
-- rates are now integers in parts per million of the subtotal: 8.875 % = 88750 ppm,
-- 8.25 % = 82500 ppm, 100 % = 1000000 ppm.
--
--   sales_tax = round_half_up(subtotal_minor * rate_ppm, 1000000)
--
-- India GST is unchanged (basis points per line).
--
-- Compatibility with app versions that still send basis points:
--   * us_sales_tax, compute_quote_totals, submit_quote and revise_quote accept the new
--     p_sales_tax_rate_ppm / p_rate_ppm and still accept p_sales_tax_rate_bp / p_rate_bp
--     (converted exactly: ppm = bp * 100). Passing both with different values is
--     rejected (400 invalid_sales_tax_input).
--   * Each function keeps a single signature (the new parameter is appended with a
--     default), so PostgREST never sees an ambiguous overload.
--   * tax_breakdown for sales tax is {"kind":"sales_tax","rate_ppm","rate_bp","amount"}.
--     rate_ppm is the rate; rate_bp = round_half_up(rate_ppm, 100) is kept only for app
--     versions that read rate_bp (display only, e.g. 888 for 88750). Readers prefer rate_ppm
--     and treat a row without it as rate_ppm = rate_bp * 100. Existing quotes are backfilled.
set search_path = public, extensions;

-- us_sales_tax ---------------------------------------------------------------------------------------------
-- The second positional argument is now ppm. Named p_rate_bp keeps working.
drop function if exists public.us_sales_tax(bigint, int);

create function public.us_sales_tax(p_subtotal_minor bigint, p_rate_ppm int default null, p_rate_bp int default null)
returns bigint
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_ppm int;
begin
  if p_rate_bp is not null and (p_rate_bp < 0 or p_rate_bp > 10000) then
    raise exception using errcode = 'PT400', message = 'invalid_sales_tax_input';
  end if;
  if p_rate_ppm is not null and p_rate_bp is not null and p_rate_ppm <> p_rate_bp * 100 then
    raise exception using errcode = 'PT400', message = 'invalid_sales_tax_input';
  end if;
  v_ppm := coalesce(p_rate_ppm, p_rate_bp * 100);
  if p_subtotal_minor is null or p_subtotal_minor < 0 or v_ppm is null
     or v_ppm < 0 or v_ppm > 1000000 then
    raise exception using errcode = 'PT400', message = 'invalid_sales_tax_input';
  end if;
  return public.money_round_half_up(p_subtotal_minor::numeric * v_ppm, 1000000);
end $$;

-- compute_quote_totals -------------------------------------------------------------------------------------
-- Same positional arguments as before (p_sales_tax_rate_bp stays 4th), plus p_sales_tax_rate_ppm.
drop function if exists public.compute_quote_totals(text, jsonb, bigint, int, boolean);

create function public.compute_quote_totals(
  p_country text, p_lines jsonb, p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default null, p_intra_state boolean default true,
  p_sales_tax_rate_ppm int default null)
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
  v_ppm int;
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
    if p_sales_tax_rate_ppm is null and p_sales_tax_rate_bp is null then
      v_ppm := 0;
    else
      -- validates the range and a bp / ppm mismatch
      perform public.us_sales_tax(0, p_sales_tax_rate_ppm, p_sales_tax_rate_bp);
      v_ppm := coalesce(p_sales_tax_rate_ppm, p_sales_tax_rate_bp * 100);
    end if;
    v_tax := public.us_sales_tax(v_sub, v_ppm);
    v_breakdown := jsonb_build_object(
      'kind', 'sales_tax',
      'rate_ppm', v_ppm,
      'rate_bp', public.money_round_half_up(v_ppm, 100),
      'amount', v_tax);
  end if;

  return jsonb_build_object(
    'lines', v_lines,
    'subtotal_minor', v_sub,
    'tax_minor', v_tax,
    'tax_breakdown', v_breakdown,
    'delivery_minor', coalesce(p_delivery_minor, 0),
    'total_minor', v_sub + v_tax + coalesce(p_delivery_minor, 0));
end $$;

-- quote_totals_for -----------------------------------------------------------------------------------------
drop function if exists private.quote_totals_for(uuid, public.requests, jsonb, bigint, int);

create function private.quote_totals_for(
  p_seller_id uuid, p_request public.requests, p_line_items jsonb,
  p_delivery_minor bigint, p_sales_tax_rate_bp int, p_sales_tax_rate_ppm int)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_country text := private.setting_text('country', 'IN');
  v_seller_state text;
  v_intra boolean;
begin
  select lower(trim(state)) into v_seller_state from public.sellers where id = p_seller_id;
  -- Intra-state (CGST+SGST) when both states are equal or either is unknown.
  v_intra := v_seller_state is null or p_request.state is null
             or v_seller_state = lower(trim(p_request.state));
  return public.compute_quote_totals(v_country, p_line_items, coalesce(p_delivery_minor, 0),
                                     p_sales_tax_rate_bp, v_intra, p_sales_tax_rate_ppm);
end $$;

-- submit_quote / revise_quote: p_sales_tax_rate_ppm appended; p_sales_tax_rate_bp (older apps) kept ----------
drop function if exists public.submit_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb);
drop function if exists public.revise_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb);

create function public.submit_quote(
  p_request_id uuid,
  p_line_items jsonb,
  p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default null,
  p_offered_brand_model text default null,
  p_delivery_date date default null,
  p_warranty text default null,
  p_valid_days int default null,
  p_notes text default null,
  p_attachments text[] default '{}',
  p_fields jsonb default '{}'::jsonb,
  p_sales_tax_rate_ppm int default null)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_seller public.sellers;
  v_req public.requests;
  v_pol record;
  v_invited boolean;
  v_billing text;
  v_totals jsonb;
  v_quote public.quotes;
  v_resp int;
  v_valid int := coalesce(p_valid_days, private.setting_int('quote_valid_days_default', 7));
begin
  select * into v_seller from public.sellers where id = v_uid;
  if not found then
    perform private.raise_error('not_a_seller', 403);
  end if;
  if v_seller.hidden then
    perform private.raise_error('seller_suspended', 403);
  end if;
  if v_valid not between 1 and 90 then
    perform private.raise_error('invalid_validity', 400);
  end if;

  -- per-seller hourly rate limit
  if (select count(*) from public.quotes q where q.seller_id = v_uid and q.created_at > now() - interval '1 hour')
     >= private.setting_int('max_quotes_per_seller_per_hour', 20) then
    perform private.raise_error('rate_limited', 429, 'Hourly quote limit reached');
  end if;

  -- lock the request row: serializes the cap check and accept_quote
  select * into v_req from public.requests where id = p_request_id for update;
  if not found or v_req.hidden then
    perform private.raise_error('request_not_found', 404);
  end if;
  if v_req.buyer_id = v_uid then
    perform private.raise_error('cannot_quote_own_request', 403);
  end if;
  if (select is_review_account from public.profiles where id = v_req.buyer_id)
     is distinct from (select is_review_account from public.profiles where id = v_uid) then
    perform private.raise_error('request_not_found', 404);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  if v_req.quote_window_ends_at <= now() then
    perform private.raise_error('quote_window_closed', 409);
  end if;
  if private.is_blocked_between(v_uid, v_req.buyer_id) then
    perform private.raise_error('blocked', 403);
  end if;
  if exists (select 1 from public.quotes q where q.request_id = p_request_id and q.seller_id = v_uid
               and q.status in ('sent','revised','shortlisted','accepted')) then
    perform private.raise_error('already_quoted', 409, 'Use revise_quote');
  end if;
  if v_req.quote_count >= v_req.max_quotes then
    perform private.raise_error('quote_cap_reached', 409);
  end if;

  -- category policy and licence
  select * into v_pol from private.category_policy(v_req.category_id);
  if v_pol.policy = 'blocked' then
    perform private.raise_error('category_blocked', 403);
  end if;
  if v_pol.policy = 'restricted' and not private.seller_has_licence(v_uid, v_req.category_id) then
    perform private.raise_error('licence_required', 403, v_pol.required_licence_type);
  end if;

  -- match: category + service area (or invited by the buyer link)
  v_invited := v_req.inviting_seller_id = v_uid;
  if not private.seller_covers_request(v_uid, p_request_id) then
    perform private.raise_error('request_not_in_service_area', 403);
  end if;

  -- verified-first priority window
  if v_req.priority_until is not null and v_req.priority_until > now()
     and not coalesce(v_invited, false) and not private.seller_has_priority(v_uid) then
    perform private.raise_error('priority_window', 403, v_req.priority_until::text);
  end if;

  -- quote-scope structured fields (e.g. BIS/ISI mark, Energy Star, USDOT number)
  perform private.validate_fields((select field_schema from public.categories where id = v_req.category_id),
                                  coalesce(p_fields, '{}'::jsonb), 'quote');

  -- totals (validates line items) before spending any entitlement
  v_totals := private.quote_totals_for(v_uid, v_req, p_line_items, p_delivery_minor,
                                     p_sales_tax_rate_bp, p_sales_tax_rate_ppm);

  -- entitlement: launch free / early partner / subscription / free tier / credit
  v_billing := case when coalesce(v_invited, false) then 'invited'
                    else private.quote_entitlement(v_uid, true) end;

  v_resp := greatest(0, floor(extract(epoch from now() - v_req.created_at) / 60))::int;

  insert into public.quotes (
    request_id, seller_id, subtotal_minor, tax_minor, tax_breakdown, delivery_minor, total_minor,
    currency, offered_brand_model, fields, delivery_date, warranty, valid_until, notes, attachments,
    status, response_mins, billing_source)
  values (
    p_request_id, v_uid, (v_totals->>'subtotal_minor')::bigint, (v_totals->>'tax_minor')::bigint,
    v_totals->'tax_breakdown', (v_totals->>'delivery_minor')::bigint, (v_totals->>'total_minor')::bigint,
    v_req.currency, p_offered_brand_model, coalesce(p_fields, '{}'::jsonb), p_delivery_date, p_warranty, current_date + v_valid,
    p_notes, coalesce(p_attachments, '{}'), 'sent', v_resp, v_billing)
  returning * into v_quote;

  perform private.insert_quote_lines(v_quote.id, v_totals);

  update public.requests set quote_count = quote_count + 1 where id = p_request_id;

  update public.sellers
     set quotes_sent = quotes_sent + 1,
         avg_response_mins = case when avg_response_mins is null then v_resp
                                  else ((avg_response_mins::bigint * quotes_sent + v_resp) / (quotes_sent + 1))::int end
   where id = v_uid;

  insert into public.lead_states (seller_id, request_id, seen_at) values (v_uid, p_request_id, now())
  on conflict (seller_id, request_id) do update set seen_at = coalesce(lead_states.seen_at, now());

  -- buyer notification: first 3 quotes push individually, later ones are
  -- merged into a digest ("5 new quotes for your refrigerator")
  perform private.notify(v_req.buyer_id, 'new_quote',
    jsonb_build_object('title', v_req.title, 'request_id', p_request_id, 'quote_id', v_quote.id,
                       'seller_name', v_seller.business_name, 'total_minor', v_quote.total_minor,
                       'currency', v_quote.currency, 'quote_number', v_req.quote_count + 1,
                       'route', '/r/' || p_request_id),
    case when v_req.quote_count + 1 > 3 then 'quotes:' || p_request_id end,
    case when v_req.quote_count + 1 > 3 then now() + interval '15 minutes' else now() end);

  -- outreach attribution: first quote moves the CRM lead to 'active'
  if to_regclass('public.outreach_leads') is not null then
    execute 'update public.outreach_leads set stage = ''active'' where seller_id = $1 and stage <> ''active'''
      using v_uid;
  end if;

  return v_quote;
end $$;

create function public.revise_quote(
  p_quote_id uuid,
  p_line_items jsonb,
  p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default null,
  p_offered_brand_model text default null,
  p_delivery_date date default null,
  p_warranty text default null,
  p_valid_days int default null,
  p_notes text default null,
  p_attachments text[] default null,
  p_fields jsonb default null,
  p_sales_tax_rate_ppm int default null)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
  v_totals jsonb;
  v_valid int := coalesce(p_valid_days, private.setting_int('quote_valid_days_default', 7));
begin
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found or v_quote.seller_id <> v_uid then
    perform private.raise_error('quote_not_found', 404);
  end if;
  select * into v_req from public.requests where id = v_quote.request_id for update;
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_revisable', 409, v_quote.status);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409);
  end if;
  if v_quote.revision_count >= private.setting_int('max_quote_revisions', 5) then
    perform private.raise_error('revision_limit_reached', 409);
  end if;
  if v_valid not between 1 and 90 then
    perform private.raise_error('invalid_validity', 400);
  end if;

  insert into public.quote_revisions (quote_id, snapshot)
  values (p_quote_id, to_jsonb(v_quote) || jsonb_build_object('line_items',
    (select coalesce(jsonb_agg(to_jsonb(li) order by li.sort), '[]') from public.quote_line_items li
      where li.quote_id = p_quote_id)));

  if p_fields is not null then
    perform private.validate_fields((select field_schema from public.categories where id = v_req.category_id),
                                    p_fields, 'quote');
  end if;
  v_totals := private.quote_totals_for(v_uid, v_req, p_line_items, p_delivery_minor,
                                     p_sales_tax_rate_bp, p_sales_tax_rate_ppm);

  update public.quotes set
    subtotal_minor = (v_totals->>'subtotal_minor')::bigint,
    tax_minor = (v_totals->>'tax_minor')::bigint,
    tax_breakdown = v_totals->'tax_breakdown',
    delivery_minor = (v_totals->>'delivery_minor')::bigint,
    total_minor = (v_totals->>'total_minor')::bigint,
    offered_brand_model = coalesce(p_offered_brand_model, offered_brand_model),
    fields = coalesce(p_fields, fields),
    delivery_date = coalesce(p_delivery_date, delivery_date),
    warranty = coalesce(p_warranty, warranty),
    valid_until = current_date + v_valid,
    notes = coalesce(p_notes, notes),
    attachments = coalesce(p_attachments, attachments),
    status = case when status = 'shortlisted' then 'shortlisted' else 'revised' end,
    revision_count = revision_count + 1
  where id = p_quote_id
  returning * into v_quote;

  delete from public.quote_line_items where quote_id = p_quote_id;
  perform private.insert_quote_lines(p_quote_id, v_totals);

  perform private.post_system_message(v_req.id, v_uid, 'quote_card', 'quote_revised', p_quote_id);
  perform private.notify(v_req.buyer_id, 'quote_revised',
    jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                       'total_minor', v_quote.total_minor, 'currency', v_quote.currency,
                       'route', '/q/' || p_quote_id));
  return v_quote;
end $$;

-- grants (dropped functions lose theirs) -------------------------------------------------------------------
revoke all on function
  public.us_sales_tax(bigint, int, int),
  public.compute_quote_totals(text, jsonb, bigint, int, boolean, int),
  public.submit_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb, int),
  public.revise_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb, int),
  private.quote_totals_for(uuid, public.requests, jsonb, bigint, int, int)
  from public, anon, authenticated;
grant execute on function
  public.us_sales_tax(bigint, int, int),
  public.compute_quote_totals(text, jsonb, bigint, int, boolean, int)
  to anon, authenticated, service_role;
grant execute on function
  public.submit_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb, int),
  public.revise_quote(uuid, jsonb, bigint, int, text, date, text, int, text, text[], jsonb, int)
  to authenticated, service_role;
grant execute on function private.quote_totals_for(uuid, public.requests, jsonb, bigint, int, int) to service_role;

-- backfill: existing sales-tax breakdowns get rate_ppm = rate_bp * 100 ----------------------------------------
update public.quotes
   set tax_breakdown = tax_breakdown || jsonb_build_object('rate_ppm', (tax_breakdown->>'rate_bp')::int * 100)
 where tax_breakdown->>'kind' = 'sales_tax'
   and not tax_breakdown ? 'rate_ppm'
   and jsonb_typeof(tax_breakdown->'rate_bp') = 'number';
