-- 0400 Indexes (Section 20.3 plus FK / query support)
set search_path = public, extensions;

-- Lead feed (20.3)
create index requests_location_gix on public.requests using gist (location);
create index sellers_center_gix on public.sellers using gist (center);
create index requests_status_category_created_idx
  on public.requests (status, category_id, created_at desc);
create index requests_open_code_idx
  on public.requests (location_code, created_at desc) where status = 'open';
create index requests_open_created_idx
  on public.requests (created_at desc, id desc) where status = 'open';
create index sellers_service_codes_gin on public.sellers using gin (service_codes);
create index seller_categories_category_seller_idx
  on public.seller_categories (category_id, seller_id);

-- Buyer screens / duplicate detection
create index requests_buyer_created_idx on public.requests (buyer_id, created_at desc);
create index requests_buyer_fingerprint_idx on public.requests (buyer_id, category_id, text_fingerprint);

-- Quotes
create index quotes_request_idx on public.quotes (request_id, status);
create index quotes_seller_created_idx on public.quotes (seller_id, created_at desc);
create index quote_line_items_quote_idx on public.quote_line_items (quote_id, sort);
create index quote_revisions_quote_idx on public.quote_revisions (quote_id, created_at);

-- Chat
create index chats_buyer_idx on public.chats (buyer_id, last_message_at desc);
create index chats_seller_idx on public.chats (seller_id, last_message_at desc);
create index messages_chat_created_idx on public.messages (chat_id, created_at desc, id desc);
create index messages_unread_idx on public.messages (chat_id) where read_at is null;

-- Orders / reviews
create index orders_buyer_idx on public.orders (buyer_id, created_at desc);
create index orders_seller_idx on public.orders (seller_id, created_at desc);
create index order_events_order_idx on public.order_events (order_id, at);
create index reviews_to_idx on public.reviews (to_id, created_at desc);

-- Misc FKs / lookups
create index addresses_user_idx on public.addresses (user_id);
create index device_tokens_user_idx on public.device_tokens (user_id);
create index blocks_blocked_idx on public.blocks (blocked_id);
create index categories_parent_idx on public.categories (parent_id);
create index category_keywords_active_idx on public.category_keywords (action) where active;
create index seller_documents_seller_idx on public.seller_documents (seller_id);
create index seller_documents_pending_idx on public.seller_documents (created_at) where status = 'pending';
create index seller_licences_seller_idx on public.seller_licences (seller_id, status);
create index entitlements_seller_idx on public.entitlements (seller_id, status);
create index request_media_request_idx on public.request_media (request_id, sort);
create index lead_states_request_idx on public.lead_states (request_id);
create index reports_target_idx on public.reports (target_type, target_id, status);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_due_idx on public.notifications (push_after) where push_status = 'queued';
create index consents_user_idx on public.consents (user_id, document, accepted_at desc);
create index postal_codes_centroid_gix on public.postal_codes using gist (centroid);
create index cities_centroid_gix on public.cities using gist (centroid);
create index cities_state_name_idx on public.cities (state, name);
create index profiles_phone_idx on public.profiles (phone);
