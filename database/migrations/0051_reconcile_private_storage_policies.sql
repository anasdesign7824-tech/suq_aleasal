-- Reconcile private verification storage policies that are present in the canonical
-- storage migration but missing from the Production policy snapshot.
-- This does not make the bucket public and does not alter stored objects.

begin;

drop policy if exists assalkom_private_select on storage.objects;
drop policy if exists assalkom_private_insert on storage.objects;
drop policy if exists assalkom_private_update on storage.objects;
drop policy if exists assalkom_private_delete on storage.objects;

create policy assalkom_private_select
on storage.objects for select
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select public.is_admin())
  )
);

create policy assalkom_private_insert
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'assalkom_private'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select public.is_admin())
  )
);

create policy assalkom_private_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select public.is_admin())
  )
)
with check (
  bucket_id = 'assalkom_private'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select public.is_admin())
  )
);

create policy assalkom_private_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'assalkom_private'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or (select public.is_admin())
  )
);

commit;
