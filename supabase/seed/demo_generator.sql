-- =============================================================================
-- Demo data generator (local dev / staging only; NEVER run in prod except
-- seed_tools.create_review_account for the store-review accounts).
--
-- Creates, per demo city: 5 buyers, 20 sellers (radius / postal-code list /
-- nationwide, ~1/3 verified), 30 requests with quotes, some chats, accepted
-- orders and reviews. Data goes through the real RPCs (create_request,
-- submit_quote, accept_quote, ...) by impersonating each demo user, so it
-- obeys the same rules as the app.
--
-- Deterministic: user ids are md5-derived and random() is seeded per city.
-- Phones: only the dev test accounts have phones (fictional ranges, matching
-- [auth.sms.test_otp] in config.toml); all other demo users are email-only
-- (@demo.invalid).
-- =============================================================================

create schema if not exists seed_tools;

create table if not exists seed_tools.demo_templates (
  slug text not null,
  title text not null,
  description text,
  fields jsonb not null default '{}'::jsonb,
  budget_min bigint,
  budget_max bigint,
  unit_min bigint not null,      -- unit price range for generated quotes (minor units)
  unit_max bigint not null,
  tax_rate_bp int not null default 0, -- India GST per line (USA uses the city sales tax)
  brands text[] not null default '{}'
);

create or replace function seed_tools.demo_uuid(p_key text)
returns uuid language sql immutable as $$ select md5('iwant-demo:' || p_key)::uuid $$;

-- Values for the required quote-scope fields of a category (e.g. BIS mark, licence no.).
create or replace function seed_tools.demo_quote_fields(p_slug text)
returns jsonb
language sql
stable
as $$
  select coalesce(jsonb_object_agg(f->>'key',
           case f->>'type' when 'boolean' then 'true'::jsonb else to_jsonb('DEMO-' || upper(f->>'key')) end), '{}'::jsonb)
    from public.categories c, jsonb_array_elements(c.field_schema->'fields') f
   where c.slug = p_slug and f->>'scope' = 'quote' and coalesce((f->>'required')::boolean, false)
$$;

-- Impersonate a user for the RPCs (auth.uid() / auth.jwt() read these claims).
create or replace function seed_tools.as_user(p_uid uuid)
returns void
language sql
as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated', 'aud', 'authenticated',
                      'roles', (select to_json(roles) from public.profiles where id = p_uid))::text, true)
$$;

create or replace function seed_tools.create_user(
  p_key text, p_name text, p_phone text default null, p_email text default null,
  p_roles text[] default '{buyer}', p_review boolean default false, p_language text default 'en')
returns uuid
language plpgsql
as $$
declare
  v_id uuid := seed_tools.demo_uuid(p_key);
begin
  insert into auth.users (instance_id, id, aud, role, email, phone, phone_confirmed_at, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at, encrypted_password,
                          confirmation_token, recovery_token, email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', p_email, p_phone,
          case when p_phone is not null then now() end, case when p_email is not null then now() end,
          jsonb_build_object('provider', case when p_phone is not null then 'phone' else 'email' end,
                             'providers', jsonb_build_array(case when p_phone is not null then 'phone' else 'email' end)),
          jsonb_build_object('full_name', p_name, 'language', p_language), now(), now(), '', '', '', '', '')
  on conflict (id) do nothing;

  insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (v_id::text, v_id,
          jsonb_strip_nulls(jsonb_build_object('sub', v_id::text, 'phone', p_phone, 'email', p_email,
                                               'email_verified', p_email is not null, 'phone_verified', p_phone is not null)),
          case when p_phone is not null then 'phone' else 'email' end, now(), now(), now())
  on conflict do nothing;

  update public.profiles
     set name = p_name, roles = p_roles, is_review_account = p_review, language = p_language,
         phone = coalesce(p_phone, phone), email = coalesce(p_email, email)
   where id = v_id;
  return v_id;
end $$;

-- Store-review accounts (Section 20.2). In prod, call this from the SQL
-- editor with the test numbers configured in the dashboard (Auth > Phone):
--   select seed_tools.create_review_account('review-buyer', 'App Review Buyer', '<phone>', false);
--   select seed_tools.create_review_account('review-seller', 'App Review Seller', '<phone>', true);
-- Review accounts only see each other's data (hidden from real feeds).
create or replace function seed_tools.create_review_account(
  p_key text, p_name text, p_phone text, p_seller boolean)
returns uuid
language plpgsql
as $$
declare v_id uuid;
begin
  v_id := seed_tools.create_user(p_key, p_name, p_phone, null,
                                 case when p_seller then array['buyer','seller'] else array['buyer'] end, true);
  if p_seller then
    perform seed_tools.as_user(v_id);
    perform public.upsert_seller_profile(
      p_business_name => p_name || ' Store', p_area_type => 'nationwide',
      p_category_ids => (select array_agg(c.id) from public.categories c
                          where c.parent_id is null and c.policy = 'allowed' and c.slug <> 'other'),
      p_description => 'Demo seller account for app store review.');
    update public.sellers set verification_status = 'verified', verified_at = now() where id = v_id;
  end if;
  return v_id;
end $$;

create or replace function seed_tools.gstin(p_state_num text, p_seq int)
returns text
language plpgsql
immutable
as $$
declare
  chars constant text := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  v text := p_state_num || 'AAB' || chr(65 + (p_seq % 26)) || 'C' || lpad((1000 + p_seq)::text, 4, '0') || 'K1Z';
  s int := 0; p int; i int;
begin
  for i in 1..14 loop
    p := (strpos(chars, substr(v, i, 1)) - 1) * (case when i % 2 = 1 then 1 else 2 end);
    s := s + p / 36 + p % 36;
  end loop;
  return v || substr(chars, ((36 - s % 36) % 36) + 1, 1);
end $$;

-- Generates one demo city. p_test_accounts: jsonb with the test phones
-- {"buyer":..,"seller":..,"verified_seller":..,"admin":..} (first city only).
create or replace function seed_tools.generate_city(
  p_key text, p_city text, p_state text, p_state_num text, p_lat float8, p_lng float8,
  p_codes text[], p_other_state text, p_sales_tax_bp int, p_test_accounts jsonb default null)
returns jsonb
language plpgsql
as $$
declare
  v_country text := private.setting_text('country', 'IN');
  v_lang text := case when v_country = 'US' then 'es' else 'hi' end;
  v_buyers uuid[] := '{}';
  v_sellers uuid[] := '{}';
  v_pool text[];
  v_restricted text[];
  v_uid uuid;
  v_req record;
  v_tpl seed_tools.demo_templates;
  v_quote public.quotes;
  v_order public.orders;
  v_chat public.chats;
  v_cats bigint[];
  v_n_quotes int := 0; v_n_orders int := 0; v_n_reviews int := 0; v_n_req int := 0;
  v_area text; v_qty numeric; v_unit bigint; v_offset float8;
  v_best uuid; v_req_ids uuid[] := '{}';
  i int; j int; k int;
  s record;
  v_first_names text[] := case when v_country = 'US'
    then array['Emily','Michael','Sofia','James','Olivia','Daniel','Ava','Carlos','Grace','Ethan']
    else array['Priya','Rahul','Ananya','Arjun','Kavya','Vikram','Sneha','Rohan','Meera','Aditya'] end;
  v_last_names text[] := case when v_country = 'US'
    then array['Johnson','Garcia','Smith','Lee','Martinez','Brown','Nguyen','Davis','Lopez','Wilson']
    else array['Sharma','Iyer','Reddy','Patel','Nair','Gupta','Rao','Singh','Kulkarni','Menon'] end;
  v_shop_words text[] := case when v_country = 'US'
    then array['Pro','Express','Home','Prime','City','Metro','Star','Elite','Quick','Trusted']
    else array['Sri','Super','Royal','New','Star','City','Prime','Shree','Metro','Galaxy'] end;
  v_shop_kinds text[] := case when v_country = 'US'
    then array['Appliances','Services','Electronics','Supply Co','Home Solutions','Repairs','Events','Print Shop']
    else array['Electronics','Enterprises','Traders','Services','Home Appliances','Agencies','Solutions','Print House'] end;
begin
  perform setseed(0.5 + (abs(hashtext(p_key)) % 1000) / 4000.0);
  -- the generator posts many quotes in one transaction; lift hourly limits temporarily
  update public.app_settings set value = '100000' where key in ('max_quotes_per_seller_per_hour', 'max_requests_per_buyer_per_day');

  select array_agg(distinct t.slug) into v_pool from seed_tools.demo_templates t;
  select array_agg(distinct t.slug) into v_restricted from seed_tools.demo_templates t
   where (select cp.policy from private.category_policy((select id from public.categories where slug = t.slug)) cp) = 'restricted';

  -- buyers ---------------------------------------------------------------------------------
  for i in 1..5 loop
    v_uid := seed_tools.create_user(
      p_key || ':buyer:' || i,
      v_first_names[1 + (i * 3 + length(p_key)) % 10] || ' ' || v_last_names[1 + (i * 7 + length(p_key)) % 10],
      case when i = 1 then p_test_accounts->>'buyer' end,
      case when i = 1 and p_test_accounts ? 'buyer' then null else 'buyer' || i || '.' || p_key || '@demo.invalid' end,
      '{buyer}', false, case when i = 3 then v_lang else 'en' end);
    v_buyers := v_buyers || v_uid;
  end loop;

  -- sellers --------------------------------------------------------------------------------
  for i in 1..20 loop
    v_uid := seed_tools.create_user(
      p_key || ':seller:' || i,
      v_first_names[1 + (i * 5) % 10] || ' ' || v_last_names[1 + (i * 3) % 10],
      case when i = 1 then p_test_accounts->>'seller' when i = 2 then p_test_accounts->>'verified_seller' end,
      case when (i = 1 and p_test_accounts ? 'seller') or (i = 2 and p_test_accounts ? 'verified_seller') then null
           else 'seller' || i || '.' || p_key || '@demo.invalid' end);
    perform seed_tools.as_user(v_uid);
    v_area := case when i <= 12 then 'radius' when i <= 17 then 'codes' else 'nationwide' end;
    -- 3 categories from the template pool (licensed sellers get a restricted trade)
    select array_agg(c.id) into v_cats from public.categories c
     where c.slug = any(array(select x from unnest(v_pool) x order by random() limit 3)
                        || case when i in (3, 6, 9, 15) and v_restricted is not null then v_restricted else '{}'::text[] end);
    v_offset := (random() - 0.5) * 0.12;
    perform public.upsert_seller_profile(
      p_business_name => v_shop_words[1 + (i + length(p_key)) % 10] || ' ' || v_shop_kinds[1 + i % 8] || ' ' || p_city,
      p_description => 'Demo business in ' || p_city || '. Fast quotes, genuine products, local service.',
      p_years_in_business => 1 + (i * 7) % 25,
      p_brands => array(select unnest(coalesce((select t.brands from seed_tools.demo_templates t where cardinality(t.brands) > 0 order by random() limit 1), '{}'))),
      p_area_type => v_area,
      p_lat => p_lat + v_offset, p_lng => p_lng + (random() - 0.5) * 0.12,
      p_radius_km => case when v_area = 'radius' then (5 + (i * 3) % 21)::numeric end,
      p_service_codes => case when v_area = 'codes' then array(select c from unnest(p_codes) c order by random() limit 3) end,
      p_category_ids => v_cats,
      p_city => case when v_area = 'nationwide' and i >= 19 then null else p_city end,
      p_state => case when v_area = 'nationwide' and i >= 19 then p_other_state else p_state end,
      p_business_phone => null,
      p_business_email => 'shop' || i || '.' || p_key || '@demo.invalid',
      p_postal_code => p_codes[1 + i % cardinality(p_codes)]);
    if i % 3 = 2 then
      update public.sellers set verification_status = 'verified', verified_at = now() - interval '30 days' where id = v_uid;
      insert into public.seller_documents (seller_id, doc_type, doc_number, status, reviewed_at)
      values (v_uid, case when v_country = 'US' then 'ein' else 'gstin' end,
              case when v_country = 'US' then '12-' || lpad((3456700 + i)::text, 7, '0')
                   else seed_tools.gstin(p_state_num, i + abs(hashtext(p_key)) % 500) end,
              'approved', now() - interval '30 days');
    elsif i % 5 = 0 then
      update public.sellers set verification_status = 'pending' where id = v_uid;
      insert into public.seller_documents (seller_id, doc_type, doc_number)
      values (v_uid, case when v_country = 'US' then 'ein' else 'gstin' end,
              case when v_country = 'US' then '45-' || lpad((1234500 + i)::text, 7, '0')
                   else seed_tools.gstin(p_state_num, 900 + i) end);
    end if;
    if i in (3, 6, 9, 15) and v_restricted is not null then
      insert into public.seller_licences (seller_id, licence_type, number, issuer, state, category_ids, expires_at, status, reviewed_at)
      select v_uid, cp.required_licence_type, 'LIC-' || upper(p_key) || '-' || i, p_state || ' licensing board', p_state,
             array[c.parent_id], now() + interval '1 year', 'approved', now()
        from public.categories c, private.category_policy(c.id) cp
       where c.slug = v_restricted[1];
    end if;
    v_sellers := v_sellers || v_uid;
  end loop;

  -- requests + quotes -----------------------------------------------------------------------
  for i in 1..30 loop
    select * into v_tpl from seed_tools.demo_templates order by random() limit 1;
    v_uid := v_buyers[1 + (i - 1) % 5];
    perform seed_tools.as_user(v_uid);
    select * into v_req from public.create_request(
      p_category_id => (select id from public.categories where slug = v_tpl.slug),
      p_title => v_tpl.title || ' (' || p_city || ' #' || i || ')',
      p_description => v_tpl.description,
      p_fields => v_tpl.fields,
      p_budget_min_minor => v_tpl.budget_min,
      p_budget_max_minor => v_tpl.budget_max,
      p_budget_visible => i % 4 <> 0,
      p_needed_by => current_date + (3 + i % 10),
      p_lat => case when i % 3 = 0 then null else p_lat + (random() - 0.5) * 0.1 end,
      p_lng => case when i % 3 = 0 then null else p_lng + (random() - 0.5) * 0.1 end,
      p_location_code => p_codes[1 + i % cardinality(p_codes)],
      p_audience => case when i % 7 = 0 then 'local' when i % 11 = 0 then 'online' else 'both' end,
      p_quote_window_hours => case when i % 5 = 0 then 168 else 48 end,
      p_full_address => (100 + i) || ' Demo Street, ' || p_city,
      p_inviting_seller_id => case when i = 30 then v_sellers[4] end);
    v_n_req := v_n_req + 1;
    v_req_ids := v_req_ids || v_req.request_id;

    -- age the request (spread over the last ~2.5 days) and end the priority window
    update public.requests
       set created_at = now() - make_interval(hours => (i * 2 + (random() * 3)::int)),
           priority_until = now() - make_interval(hours => (i * 2)) + interval '15 minutes',
           quote_window_ends_at = now() + make_interval(days => 2 + i % 5)
     where id = v_req.request_id;
    if i % 10 = 1 then
      continue; -- a few fresh requests without quotes yet
    end if;

    k := 0;
    for s in select m.seller_id from private.match_sellers(v_req.request_id, 50) m order by random() limit 2 + (i % 5) loop
      perform seed_tools.as_user(s.seller_id);
      v_qty := coalesce((v_tpl.fields->>'quantity')::numeric, (v_tpl.fields->>'units')::numeric, 1);
      v_unit := v_tpl.unit_min + floor(random() * (v_tpl.unit_max - v_tpl.unit_min))::bigint;
      v_unit := (v_unit / 100) * 100 - case when v_unit > 10000 then 100 else 0 end + 99 * (k % 2);
      begin
        v_quote := public.submit_quote(
          p_request_id => v_req.request_id,
          p_line_items => jsonb_build_array(jsonb_build_object(
              'description', v_tpl.title, 'qty', v_qty, 'unit_price_minor', greatest(v_unit, 100),
              'tax_rate_bp', v_tpl.tax_rate_bp)),
          p_delivery_minor => case when k % 3 = 0 then 0 else (case when v_country = 'US' then 2500 else 30000 end) end,
          p_sales_tax_rate_bp => case when v_country = 'US' then p_sales_tax_bp else 0 end,
          p_offered_brand_model => case when cardinality(v_tpl.brands) > 0
                                        then v_tpl.brands[1 + k % cardinality(v_tpl.brands)] || ' (as requested)' end,
          p_delivery_date => current_date + 2 + k,
          p_warranty => case k % 3 when 0 then '1 year' when 1 then '2 years' else '6 months' end,
          p_notes => 'Demo quote. Price includes standard installation where applicable.',
          p_fields => seed_tools.demo_quote_fields(v_tpl.slug));
        v_n_quotes := v_n_quotes + 1;
        k := k + 1;
        if k % 2 = 1 then
          v_chat := public.get_or_create_chat(v_req.request_id, null);
          insert into public.messages (chat_id, sender_id, type, body)
          values (v_chat.id, v_uid, 'text', case when v_country = 'US' then 'Hi! Can you deliver on a weekend?' else 'Namaste, weekend delivery possible?' end),
                 (v_chat.id, s.seller_id, 'text', case when v_country = 'US' then 'Yes, Saturday works. Installation included.' else 'Yes ji, Saturday delivery with free installation.' end);
        end if;
      exception when others then
        raise notice 'demo quote skipped (%): %', v_tpl.slug, sqlerrm;
      end;
    end loop;

    -- accept the cheapest quote on every 4th request; complete + review half of those
    if i % 4 = 0 and k >= 2 then
      perform seed_tools.as_user(v_uid);
      select q.id into v_best from public.quotes q where q.request_id = v_req.request_id and q.status = 'sent'
       order by q.total_minor limit 1;
      v_order := public.accept_quote(v_best);
      v_n_orders := v_n_orders + 1;
      perform public.record_payment(v_order.id, case when v_country = 'US' then 'card' else 'upi' end, v_order.total_minor);
      if i % 8 = 0 then
        perform seed_tools.as_user(v_order.seller_id);
        perform public.update_order_status(v_order.id, 'delivered', 'Delivered and installed');
        perform seed_tools.as_user(v_uid);
        perform public.update_order_status(v_order.id, 'completed');
        perform public.submit_review(v_order.id, 4 + (i / 8) % 2, array['on_time','fair_price'],
          case when v_country = 'US' then 'Great service, arrived on time.' else 'Bahut accha service, on time delivery.' end);
        v_n_reviews := v_n_reviews + 1;
      end if;
    elsif i % 6 = 1 and k >= 1 then
      perform seed_tools.as_user(v_uid);
      perform public.shortlist(q.id) from public.quotes q
        where q.request_id = v_req.request_id and q.status = 'sent' order by q.total_minor limit 1;
    end if;
  end loop;

  update public.app_settings set value = '20' where key = 'max_quotes_per_seller_per_hour';
  update public.app_settings set value = '10' where key = 'max_requests_per_buyer_per_day';
  perform set_config('request.jwt.claims', '', true);

  return jsonb_build_object('city', p_city, 'buyers', 5, 'sellers', 20, 'requests', v_n_req,
                            'quotes', v_n_quotes, 'orders', v_n_orders, 'reviews', v_n_reviews);
end $$;

-- Dev test accounts (phones must match [auth.sms.test_otp] in config.toml).
create or replace function seed_tools.create_test_admin(p_phone text)
returns uuid
language sql
as $$ select seed_tools.create_user('test:admin', 'Test Admin', p_phone, null, array['buyer','admin']) $$;

-- Review accounts with a little demo data of their own.
create or replace function seed_tools.generate_review_data(p_buyer_phone text, p_seller_phone text,
  p_lat float8, p_lng float8, p_code text, p_sales_tax_bp int)
returns void
language plpgsql
as $$
declare
  v_buyer uuid := seed_tools.create_review_account('review:buyer', 'Review Buyer', p_buyer_phone, false);
  v_seller uuid := seed_tools.create_review_account('review:seller', 'Review Seller', p_seller_phone, true);
  v_req record;
  v_tpl seed_tools.demo_templates;
  i int := 0;
begin
  for v_tpl in select * from seed_tools.demo_templates t
                where (select cp.policy from private.category_policy((select id from public.categories c where c.slug = t.slug)) cp) = 'allowed'
                order by t.slug limit 3 loop
    i := i + 1;
    perform seed_tools.as_user(v_buyer);
    select * into v_req from public.create_request(
      p_category_id => (select id from public.categories where slug = v_tpl.slug),
      p_title => v_tpl.title || ' (review demo ' || i || ')', p_description => v_tpl.description,
      p_fields => v_tpl.fields, p_lat => p_lat, p_lng => p_lng, p_location_code => p_code);
    update public.requests set priority_until = now() - interval '1 minute' where id = v_req.request_id;
    if i < 3 then
      perform seed_tools.as_user(v_seller);
      perform public.submit_quote(v_req.request_id,
        jsonb_build_array(jsonb_build_object('description', v_tpl.title, 'qty', 1,
                                             'unit_price_minor', v_tpl.unit_min, 'tax_rate_bp', v_tpl.tax_rate_bp)),
        0, p_sales_tax_bp, null, current_date + 3, '1 year', 7, 'Review demo quote', '{}',
        seed_tools.demo_quote_fields(v_tpl.slug));
    end if;
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
