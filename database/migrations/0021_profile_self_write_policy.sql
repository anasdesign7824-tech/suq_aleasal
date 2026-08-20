-- 0021_profile_self_write_policy.sql
-- Allow a signed-in user to create the profile row owned by that same auth identity.
-- This is required for PostgREST upsert because an upsert may evaluate INSERT policy
-- even when the row already exists and resolves through the profiles_pkey conflict.

begin;

create policy profiles_insert
  on public.profiles
  for insert
to public
with check (
  user_id = (select auth.uid())
  or (select is_admin())
);

commit;
