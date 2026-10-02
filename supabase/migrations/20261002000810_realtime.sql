-- 0810 Realtime publication (Postgres Changes; RLS decides who receives rows).
--   messages       chat screen (filter chat_id=eq.<id>)
--   quotes         buyer request screen (filter request_id=eq.<id>), seller my-quotes
--   requests       buyer's own requests: quote_count / status changes (RLS: buyer only)
--   notifications  inbox badge (filter user_id=eq.<uid>)
--   chats          chat list ordering (last_message_at)
-- Sellers' lead feeds are refreshed via Broadcast channel `seller:<seller_id>`
-- sent by the match-request Edge Function, never by subscribing to requests.
do $$
declare t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  foreach t in array array['messages','quotes','requests','notifications','chats'] loop
    if not exists (select 1 from pg_publication_tables
                    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
