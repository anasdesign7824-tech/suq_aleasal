-- Email-only release: user-initiated account deletion for Google Play compliance.
-- The public users row cascades to the owned profile and user-owned records.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  subject uuid := auth.uid();
begin
  if subject is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  delete from auth.users where id = subject;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
