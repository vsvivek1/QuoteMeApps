-- 0720 Quotes: submit, revise, withdraw (seller); accept, decline, counter,
-- shortlist (buyer). Every state change is one transaction that locks the
-- request row first, so the quote cap and acceptance can't race.
set search_path = public, extensions;

-- Builds and validates totals for a seller quoting on a request.
create or replace function private.quote_totals_for(
  p_seller_id uuid, p_request public.requests, p_line_items jsonb,
  p_delivery_minor bigint, p_sales_tax_rate_bp int)
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
                                     coalesce(p_sales_tax_rate_bp, 0), v_intra);
end $$;

create or replace function private.insert_quote_lines(p_quote_id uuid, p_totals jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.quote_line_items (quote_id, sort, description, qty, unit_price_minor,
                                       tax_rate_bp, hsn_sac, line_total_minor, tax_minor)
  select p_quote_id, (ord - 1)::int, coalesce(nullif(l->>'description', ''), 'Item'),
         (l->>'qty')::numeric, (l->>'unit_price_minor')::bigint, (l->>'tax_rate_bp')::int,
         l->>'hsn_sac', (l->>'line_total_minor')::bigint, (l->>'tax_minor')::bigint
    from jsonb_array_elements(p_totals->'lines') with ordinality as t(l, ord)
$$;

-- Ensures a chat exists for (request, seller); returns its id.
create or replace function private.ensure_chat(p_request_id uuid, p_seller_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_id uuid;
begin
  insert into public.chats (request_id, buyer_id, seller_id)
  select r.id, r.buyer_id, p_seller_id from public.requests r where r.id = p_request_id
  on conflict (request_id, seller_id) do nothing
  returning id into v_id;
  if v_id is null then
    select id into v_id from public.chats where request_id = p_request_id and seller_id = p_seller_id;
  end if;
  return v_id;
end $$;

create or replace function private.post_system_message(
  p_request_id uuid, p_seller_id uuid, p_type text, p_body text, p_quote_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_chat uuid := private.ensure_chat(p_request_id, p_seller_id);
begin
  insert into public.messages (chat_id, sender_id, type, body, quote_id)
  values (v_chat, null, p_type, p_body, p_quote_id);
end $$;

-- submit_quote -----------------------------------------------------------------------------------------
create or replace function public.submit_quote(
  p_request_id uuid,
  p_line_items jsonb,
  p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default 0,
  p_offered_brand_model text default null,
  p_delivery_date date default null,
  p_warranty text default null,
  p_valid_days int default null,
  p_notes text default null,
  p_attachments text[] default '{}',
  p_fields jsonb default '{}'::jsonb)
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
  v_totals := private.quote_totals_for(v_uid, v_req, p_line_items, p_delivery_minor, p_sales_tax_rate_bp);

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

-- revise_quote ---------------------------------------------------------------------------------------------
create or replace function public.revise_quote(
  p_quote_id uuid,
  p_line_items jsonb,
  p_delivery_minor bigint default 0,
  p_sales_tax_rate_bp int default 0,
  p_offered_brand_model text default null,
  p_delivery_date date default null,
  p_warranty text default null,
  p_valid_days int default null,
  p_notes text default null,
  p_attachments text[] default null,
  p_fields jsonb default null)
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
  v_totals := private.quote_totals_for(v_uid, v_req, p_line_items, p_delivery_minor, p_sales_tax_rate_bp);

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

-- withdraw_quote --------------------------------------------------------------------------------------------
create or replace function public.withdraw_quote(p_quote_id uuid)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
begin
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found or v_quote.seller_id <> v_uid then
    perform private.raise_error('quote_not_found', 404);
  end if;
  select * into v_req from public.requests where id = v_quote.request_id for update;
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_withdrawable', 409, v_quote.status);
  end if;
  update public.quotes set status = 'withdrawn' where id = p_quote_id returning * into v_quote;
  -- frees the slot so another seller can quote
  update public.requests set quote_count = greatest(quote_count - 1, 0)
   where id = v_req.id and status = 'open';
  return v_quote;
end $$;

-- accept_quote -----------------------------------------------------------------------------------------------
-- One transaction: accept this quote, decline the others, award (close) the
-- request, create the order + first order_event, which unlocks
-- request_private for the winning seller (RLS via accepted_quote_id).
create or replace function public.accept_quote(p_quote_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
  v_order public.orders;
  q record;
begin
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found then
    perform private.raise_error('quote_not_found', 404);
  end if;
  select * into v_req from public.requests where id = v_quote.request_id for update;
  if v_req.buyer_id <> v_uid then
    perform private.raise_error('quote_not_found', 404);
  end if;
  if v_req.status <> 'open' then
    perform private.raise_error('request_not_open', 409, v_req.status);
  end if;
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_acceptable', 409, v_quote.status);
  end if;
  if v_quote.valid_until is not null and v_quote.valid_until < current_date then
    perform private.raise_error('quote_expired', 409);
  end if;
  if private.is_blocked_between(v_uid, v_quote.seller_id) then
    perform private.raise_error('blocked', 403);
  end if;

  update public.quotes set status = 'accepted', accepted_at = now()
   where id = p_quote_id returning * into v_quote;

  for q in update public.quotes
              set status = 'declined', decline_reason = 'another_quote_accepted'
            where request_id = v_req.id and id <> p_quote_id
              and status in ('sent','revised','shortlisted')
            returning id, seller_id loop
    perform private.notify(q.seller_id, 'quote_not_selected',
      jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', q.id,
                         'route', '/seller/quotes/' || q.id));
  end loop;

  update public.requests
     set status = 'awarded', accepted_quote_id = p_quote_id, closed_at = now()
   where id = v_req.id;

  insert into public.orders (request_id, quote_id, buyer_id, seller_id, status, total_minor, currency)
  values (v_req.id, p_quote_id, v_uid, v_quote.seller_id, 'accepted', v_quote.total_minor, v_quote.currency)
  returning * into v_order;

  insert into public.order_events (order_id, status, actor_id, note)
  values (v_order.id, 'accepted', v_uid, null);

  update public.sellers set quotes_won = quotes_won + 1 where id = v_quote.seller_id;

  perform private.post_system_message(v_req.id, v_quote.seller_id, 'system', 'quote_accepted', p_quote_id);
  perform private.notify(v_quote.seller_id, 'quote_accepted',
    jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                       'order_id', v_order.id, 'route', '/orders/' || v_order.id));
  return v_order;
end $$;

-- decline_quote ------------------------------------------------------------------------------------------------
create or replace function public.decline_quote(p_quote_id uuid, p_reason text default null)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
begin
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found then perform private.raise_error('quote_not_found', 404); end if;
  select * into v_req from public.requests where id = v_quote.request_id for update;
  if v_req.buyer_id <> v_uid then perform private.raise_error('quote_not_found', 404); end if;
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_declinable', 409, v_quote.status);
  end if;
  update public.quotes set status = 'declined', decline_reason = left(p_reason, 500)
   where id = p_quote_id returning * into v_quote;
  perform private.notify(v_quote.seller_id, 'quote_declined',
    jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                       'reason', left(p_reason, 500), 'route', '/seller/quotes/' || p_quote_id));
  return v_quote;
end $$;

-- counter_offer ----------------------------------------------------------------------------------------------------
create or replace function public.counter_offer(p_quote_id uuid, p_target_minor bigint, p_note text default null)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
begin
  if p_target_minor is null or p_target_minor < 0 then
    perform private.raise_error('invalid_target_price', 400);
  end if;
  select * into v_quote from public.quotes where id = p_quote_id;
  if not found then perform private.raise_error('quote_not_found', 404); end if;
  select * into v_req from public.requests where id = v_quote.request_id for update;
  if v_req.buyer_id <> v_uid then perform private.raise_error('quote_not_found', 404); end if;
  if v_req.status <> 'open' then perform private.raise_error('request_not_open', 409); end if;
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_counterable', 409, v_quote.status);
  end if;
  update public.quotes
     set counter_target_minor = p_target_minor, counter_note = left(p_note, 1000), countered_at = now()
   where id = p_quote_id returning * into v_quote;
  perform private.post_system_message(v_req.id, v_quote.seller_id, 'system', 'counter_offer', p_quote_id);
  perform private.notify(v_quote.seller_id, 'counter_offer',
    jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                       'target_minor', p_target_minor, 'currency', v_quote.currency,
                       'route', '/seller/quotes/' || p_quote_id));
  return v_quote;
end $$;

-- shortlist ----------------------------------------------------------------------------------------------------------
create or replace function public.shortlist(p_quote_id uuid, p_on boolean default true)
returns public.quotes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_quote public.quotes;
  v_req public.requests;
begin
  select * into v_quote from public.quotes where id = p_quote_id for update;
  if not found then perform private.raise_error('quote_not_found', 404); end if;
  select * into v_req from public.requests where id = v_quote.request_id;
  if v_req.buyer_id <> v_uid then perform private.raise_error('quote_not_found', 404); end if;
  if v_quote.status not in ('sent','revised','shortlisted') then
    perform private.raise_error('quote_not_shortlistable', 409, v_quote.status);
  end if;
  if p_on and v_quote.status <> 'shortlisted' then
    update public.quotes set status = 'shortlisted', shortlisted_at = now()
     where id = p_quote_id returning * into v_quote;
    perform private.notify(v_quote.seller_id, 'shortlisted',
      jsonb_build_object('title', v_req.title, 'request_id', v_req.id, 'quote_id', p_quote_id,
                         'route', '/seller/quotes/' || p_quote_id));
  elsif not p_on and v_quote.status = 'shortlisted' then
    update public.quotes
       set status = case when revision_count > 0 then 'revised' else 'sent' end, shortlisted_at = null
     where id = p_quote_id returning * into v_quote;
  end if;
  return v_quote;
end $$;

-- Seller "My quotes" with a safe request summary --------------------------------------------------------------
-- p_tab: 'active' (sent/revised/shortlisted), 'won' (accepted), 'lost'
-- (declined/withdrawn/expired) or null for all. Keyset on (created_at, id).
create or replace function public.get_my_quotes(p_tab text default null, p_cursor jsonb default null, p_limit int default 20)
returns table (quote jsonb, request jsonb, order_id uuid, chat_id uuid, created_at timestamptz, id uuid)
language plpgsql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_cur_ts timestamptz := (p_cursor->>'created_at')::timestamptz;
  v_cur_id uuid := (p_cursor->>'id')::uuid;
begin
  return query
  select to_jsonb(q) || jsonb_build_object('line_items',
           (select coalesce(jsonb_agg(to_jsonb(li) order by li.sort), '[]') from public.quote_line_items li where li.quote_id = q.id)),
         private.request_safe_json(r, v_uid),
         o.id, c.id, q.created_at, q.id
    from public.quotes q
    join public.requests r on r.id = q.request_id
    left join public.orders o on o.quote_id = q.id
    left join public.chats c on c.request_id = q.request_id and c.seller_id = v_uid
   where q.seller_id = v_uid
     and (p_tab is null
          or (p_tab = 'active' and q.status in ('sent','revised','shortlisted'))
          or (p_tab = 'won' and q.status = 'accepted')
          or (p_tab = 'lost' and q.status in ('declined','withdrawn','expired')))
     and (v_cur_ts is null or (q.created_at, q.id) < (v_cur_ts, v_cur_id))
   order by q.created_at desc, q.id desc
   limit least(greatest(coalesce(p_limit, 20), 1), 50);
end $$;
