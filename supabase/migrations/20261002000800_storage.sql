-- 0800 Storage buckets and policies (mirror the table RLS rules).
--   seller-media       public  {user_id}/...                 logos, shop photos, profile & review photos
--   request-media      private {request_id}/...              buyer photos/videos
--                              {request_id}/quotes/{seller_id}/...  quote attachments (spec sheets)
--   verification-docs  private {seller_id}/...               GSTIN/EIN/licence scans (admin readable)
--   chat-media         private {chat_id}/...                 chat photos
set search_path = public, extensions;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('seller-media', 'seller-media', true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('request-media', 'request-media', false, 26214400,
     array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime','application/pdf']),
  ('verification-docs', 'verification-docs', false, 10485760, array['image/jpeg','image/png','image/webp','application/pdf']),
  ('chat-media', 'chat-media', false, 10485760, array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.try_uuid(p_text text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return p_text::uuid;
exception when others then
  return null;
end $$;

-- request-media read access
create or replace function private.can_read_request_media(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parts text[] := string_to_array(p_name, '/');
  v_req uuid := private.try_uuid(v_parts[1]);
  v_uid uuid := auth.uid();
  v_r public.requests;
begin
  if v_req is null or v_uid is null then return false; end if;
  select * into v_r from public.requests where id = v_req;
  if not found then return false; end if;
  if v_r.buyer_id = v_uid or private.is_admin() then return true; end if;
  if v_parts[2] = 'quotes' then
    return private.try_uuid(v_parts[3]) = v_uid;
  end if;
  if v_r.hidden then return false; end if;
  return exists (select 1 from public.quotes q where q.request_id = v_req and q.seller_id = v_uid)
      or (v_r.status = 'open' and private.seller_covers_request(v_uid, v_req));
end $$;

create or replace function private.can_write_request_media(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parts text[] := string_to_array(p_name, '/');
  v_req uuid := private.try_uuid(v_parts[1]);
  v_uid uuid := auth.uid();
  v_r public.requests;
begin
  if v_req is null or v_uid is null or not private.is_active_user(v_uid) then return false; end if;
  select * into v_r from public.requests where id = v_req;
  if not found then return false; end if;
  if v_parts[2] = 'quotes' then
    return private.try_uuid(v_parts[3]) = v_uid
       and (exists (select 1 from public.quotes q where q.request_id = v_req and q.seller_id = v_uid)
            or (v_r.status = 'open' and private.seller_covers_request(v_uid, v_req)));
  end if;
  return v_r.buyer_id = v_uid and v_r.status = 'open' and array_length(v_parts, 1) = 2;
end $$;

grant execute on function private.try_uuid(text), private.can_read_request_media(text),
  private.can_write_request_media(text) to authenticated, service_role;
grant execute on function private.try_uuid(text) to anon;

-- seller-media (public read; owner-folder writes) ------------------------------------------------
create policy "seller-media public read" on storage.objects for select to anon, authenticated
  using (bucket_id = 'seller-media');
create policy "seller-media owner insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'seller-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "seller-media owner update" on storage.objects for update to authenticated
  using (bucket_id = 'seller-media' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'seller-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "seller-media owner delete" on storage.objects for delete to authenticated
  using (bucket_id = 'seller-media' and (storage.foldername(name))[1] = auth.uid()::text);

-- request-media ------------------------------------------------------------------------------
create policy "request-media read" on storage.objects for select to authenticated
  using (bucket_id = 'request-media' and private.can_read_request_media(name));
create policy "request-media insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'request-media' and private.can_write_request_media(name));
create policy "request-media delete" on storage.objects for delete to authenticated
  using (bucket_id = 'request-media' and private.can_write_request_media(name));

-- verification-docs --------------------------------------------------------------------------------
create policy "verification-docs owner or admin read" on storage.objects for select to authenticated
  using (bucket_id = 'verification-docs'
         and ((storage.foldername(name))[1] = auth.uid()::text or private.is_admin()));
create policy "verification-docs owner insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "verification-docs owner delete" on storage.objects for delete to authenticated
  using (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);

-- chat-media ----------------------------------------------------------------------------------------
create policy "chat-media members read" on storage.objects for select to authenticated
  using (bucket_id = 'chat-media'
         and (private.is_chat_member(private.try_uuid((storage.foldername(name))[1])) or private.is_admin()));
create policy "chat-media members insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-media'
              and private.is_chat_member(private.try_uuid((storage.foldername(name))[1])));
