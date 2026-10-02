-- 0600 Grants and Row Level Security policies.
-- Principle: clients SELECT through RLS; anything that must be atomic or
-- validated (requests, quotes, orders, reviews, reports, seller profile…) is
-- written only through security-definer RPCs. Direct table writes are
-- granted only where RLS alone is enough (addresses, device tokens,
-- templates, messages, consents, profile basics).
set search_path = public, extensions;

-- Table privileges ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke insert, update, delete, truncate, references, trigger on all tables in schema public from authenticated;
grant select on all tables in schema public to authenticated;
revoke select on public.rate_limits from authenticated;
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;

-- anon (signed-out) may read public catalogue data only.
grant select on public.app_settings, public.postal_codes, public.cities, public.categories,
  public.sellers, public.seller_categories, public.reviews to anon;

-- direct writes allowed (RLS-checked)
grant update (name, photo_url, language, timezone, notification_prefs) on public.profiles to authenticated;
grant insert, update, delete on public.addresses to authenticated;
grant insert, update, delete on public.device_tokens to authenticated;
grant insert, delete on public.blocks to authenticated;
grant insert, delete on public.request_media to authenticated;
grant update (full_address) on public.request_private to authenticated;
grant insert, update, delete on public.quote_templates to authenticated;
grant insert (chat_id, sender_id, type, body, attachment_path) on public.messages to authenticated;
grant insert on public.consents to authenticated;

-- app_settings ---------------------------------------------------------------------------
create policy app_settings_read on public.app_settings for select to anon, authenticated
  using (is_public or private.is_admin());

-- profiles ------------------------------------------------------------------------------
create policy profiles_read_own on public.profiles for select to authenticated
  using (id = auth.uid() or private.is_admin());
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- addresses / device tokens -----------------------------------------------------------------
create policy addresses_own on public.addresses for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy device_tokens_own on public.device_tokens for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- blocks --------------------------------------------------------------------------------------
create policy blocks_read_own on public.blocks for select to authenticated
  using (blocker_id = auth.uid() or private.is_admin());
create policy blocks_insert_own on public.blocks for insert to authenticated
  with check (blocker_id = auth.uid());
create policy blocks_delete_own on public.blocks for delete to authenticated
  using (blocker_id = auth.uid());

-- reference data ----------------------------------------------------------------------------------
create policy postal_codes_read on public.postal_codes for select to anon, authenticated using (true);
create policy cities_read on public.cities for select to anon, authenticated using (true);
create policy categories_read on public.categories for select to anon, authenticated
  using (active or private.is_admin());
create policy category_keywords_admin_read on public.category_keywords for select to authenticated
  using (private.is_admin());

-- sellers ------------------------------------------------------------------------------------------
create policy sellers_read_public on public.sellers for select to anon, authenticated
  using (not hidden or id = auth.uid() or private.is_admin());
create policy seller_categories_read on public.seller_categories for select to anon, authenticated
  using (true);
create policy seller_contacts_read on public.seller_contacts for select to authenticated
  using (seller_id = auth.uid() or private.is_admin() or private.has_order_with_seller(seller_id));
create policy seller_documents_read on public.seller_documents for select to authenticated
  using (seller_id = auth.uid() or private.is_admin());
create policy seller_licences_read on public.seller_licences for select to authenticated
  using (seller_id = auth.uid() or private.is_admin());
create policy entitlements_read on public.entitlements for select to authenticated
  using (seller_id = auth.uid() or private.is_admin());

-- requests -------------------------------------------------------------------------------------------
-- Buyers read their own requests. Sellers never select requests directly:
-- they use get_lead_feed / get_request_for_seller which return safe columns.
create policy requests_read_own on public.requests for select to authenticated
  using (buyer_id = auth.uid() or private.is_admin());

create policy request_private_read on public.request_private for select to authenticated
  using (private.is_request_buyer(request_id) or private.is_accepted_seller(request_id) or private.is_admin());
create policy request_private_update_buyer on public.request_private for update to authenticated
  using (private.is_request_buyer(request_id)) with check (private.is_request_buyer(request_id));

create policy request_media_read on public.request_media for select to authenticated
  using (private.is_request_buyer(request_id) or private.is_admin()
         or (not hidden and exists (
               select 1 from public.quotes q where q.request_id = request_media.request_id
                  and q.seller_id = auth.uid())));
create policy request_media_insert on public.request_media for insert to authenticated
  with check (exists (select 1 from public.requests r where r.id = request_id
                        and r.buyer_id = auth.uid() and r.status = 'open'));
create policy request_media_delete on public.request_media for delete to authenticated
  using (private.is_request_buyer(request_id));

-- quotes ------------------------------------------------------------------------------------------------
create policy quotes_read on public.quotes for select to authenticated
  using (seller_id = auth.uid() or private.is_request_buyer(request_id) or private.is_admin());
create policy quote_line_items_read on public.quote_line_items for select to authenticated
  using (private.can_view_quote(quote_id) or private.is_admin());
create policy quote_revisions_read on public.quote_revisions for select to authenticated
  using (private.can_view_quote(quote_id) or private.is_admin());
create policy quote_templates_own on public.quote_templates for all to authenticated
  using (seller_id = auth.uid()) with check (seller_id = auth.uid());
create policy lead_states_own on public.lead_states for select to authenticated
  using (seller_id = auth.uid());

-- chat --------------------------------------------------------------------------------------------------
create policy chats_read on public.chats for select to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid() or private.is_admin());

create policy messages_read on public.messages for select to authenticated
  using ((private.is_chat_member(chat_id) and (not hidden or sender_id = auth.uid()))
         or private.is_admin());
create policy messages_insert on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and type in ('text','image')
    and private.is_chat_member(chat_id)
    and private.is_active_user(auth.uid())
    and not exists (
      select 1 from public.chats c
       where c.id = chat_id
         and private.is_blocked_between(c.buyer_id, c.seller_id))
    and (attachment_path is null or attachment_path like chat_id::text || '/%'));

-- orders --------------------------------------------------------------------------------------------------
create policy orders_read on public.orders for select to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid() or private.is_admin());
create policy order_events_read on public.order_events for select to authenticated
  using (private.is_order_party(order_id) or private.is_admin());

-- reviews / reports / notifications / consents ---------------------------------------------------------------
create policy reviews_read on public.reviews for select to anon, authenticated
  using (not hidden or from_id = auth.uid() or to_id = auth.uid() or private.is_admin());
create policy reports_read on public.reports for select to authenticated
  using (reporter_id = auth.uid() or private.is_admin());
create policy notifications_read on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy consents_read on public.consents for select to authenticated
  using (user_id = auth.uid() or private.is_admin());
create policy consents_insert on public.consents for insert to authenticated
  with check (user_id = auth.uid());

-- admin read access on remaining tables ----------------------------------------------------------------------------
create policy billing_events_admin on public.billing_events for select to authenticated
  using (private.is_admin());
