-- Harden the merchant payment-reference RPC.
-- The owner update policy is limited to the pre-review payment lifecycle;
-- SECURITY INVOKER keeps RLS active and removes public SECURITY DEFINER exposure.

begin;

drop policy if exists store_verification_requests_owner_payment_update
  on public.store_verification_requests;
create policy store_verification_requests_owner_payment_update
  on public.store_verification_requests for update
  using (
    merchant_id = (select auth.uid())
    and status in ('draft', 'payment_pending', 'needs_more_info')
  )
  with check (
    merchant_id = (select auth.uid())
    and status in ('draft', 'payment_pending', 'needs_more_info')
  );

create or replace function public.merchant_submit_verification_payment_reference(
  p_request_id uuid,
  p_payment_reference text
)
returns jsonb
language plpgsql
security invoker
set search_path = pg_catalog, public, auth
as $$
declare
  v_request public.store_verification_requests%rowtype;
  v_reference text := nullif(trim(coalesce(p_payment_reference, '')), '');
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if v_reference is null or char_length(v_reference) < 3 or char_length(v_reference) > 120 then
    raise exception 'payment_reference_invalid';
  end if;

  select * into v_request
  from public.store_verification_requests
  where id = p_request_id
    and merchant_id = auth.uid()
  for update;
  if not found then
    raise exception 'verification_request_not_found';
  end if;
  if v_request.status not in ('draft', 'payment_pending', 'needs_more_info') then
    raise exception 'verification_payment_reference_not_allowed';
  end if;

  update public.store_verification_requests
  set payment_status = 'pending',
      payment_reference = v_reference,
      status = 'payment_pending',
      updated_at = timezone('utc', now())
  where id = p_request_id;

  return (select to_jsonb(r) from public.store_verification_requests r where r.id = p_request_id);
end;
$$;

revoke all on function public.merchant_submit_verification_payment_reference(uuid, text)
  from public, anon, authenticated;
grant execute on function public.merchant_submit_verification_payment_reference(uuid, text)
  to authenticated;

commit;
