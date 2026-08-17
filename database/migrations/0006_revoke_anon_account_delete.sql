-- Keep account deletion authenticated-only; revoke explicit anon execute.
revoke all on function public.delete_my_account() from anon;
revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
