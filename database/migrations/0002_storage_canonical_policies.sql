-- Canonical Storage policies for Souq Al Assal.
-- Public media is readable by everyone but writable only by the owning user path or Admin.
-- Verification/private media is never publicly readable.

begin;

drop policy if exists assalkom_public_read on storage.objects;
drop policy if exists assalkom_public_insert on storage.objects;
drop policy if exists assalkom_public_update on storage.objects;
drop policy if exists assalkom_public_delete on storage.objects;
drop policy if exists assalkom_private_select on storage.objects;
drop policy if exists assalkom_private_insert on storage.objects;
drop policy if exists assalkom_private_update on storage.objects;
drop policy if exists assalkom_private_delete on storage.objects;

create policy assalkom_public_read
on storage.objects for select
to public
using (bucket_id = 'assalkom_public');

create policy assalkom_public_insert
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'assalkom_public'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_public_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'assalkom_public'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
)
with check (
  bucket_id = 'assalkom_public'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_public_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'assalkom_public'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_private_select
on storage.objects for select
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_private_insert
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'assalkom_private'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_private_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
)
with check (
  bucket_id = 'assalkom_private'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

create policy assalkom_private_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (split_part(name, '/', 1) = (select auth.uid())::text or (select public.is_admin()))
);

commit;
