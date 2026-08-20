-- Payment reconciliation for Store Verification Pro.
-- The merchant submits an external payment reference; only the local Admin
-- Backend/service_role may confirm paid, waived, failed, or refunded.

begin;

create or replace function public.merchant_submit_verification_payment_reference(
  p_request_id uuid,
  p_payment_reference text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
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
  from public;
grant execute on function public.merchant_submit_verification_payment_reference(uuid, text)
  to authenticated;

create or replace function public.admin_set_store_verification_payment(
  p_request_id uuid,
  p_payment_status text,
  p_payment_reference text default null,
  p_note text default null,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.store_verification_requests%rowtype;
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_status text;
begin
  if auth.role() <> 'service_role'
     and not private.has_admin_permission('verification.review') then
    raise exception 'Only an authorized administrator may reconcile Pro payment';
  end if;
  if p_payment_status not in ('paid', 'waived', 'failed', 'refunded') then
    raise exception 'Unsupported verification payment status';
  end if;

  select * into v_request
  from public.store_verification_requests
  where id = p_request_id
  for update;
  if not found then
    raise exception 'verification_request_not_found';
  end if;

  v_status := case
    when v_request.status = 'payment_pending' and p_payment_status in ('paid', 'waived') then 'draft'
    when p_payment_status in ('failed', 'refunded') and v_request.status in ('submitted', 'under_review') then 'needs_more_info'
    else v_request.status
  end;

  update public.store_verification_requests
  set payment_status = p_payment_status,
      payment_reference = coalesce(nullif(trim(coalesce(p_payment_reference, '')), ''), payment_reference),
      status = v_status,
      review_note = coalesce(nullif(trim(coalesce(p_note, '')), ''), review_note),
      updated_at = timezone('utc', now())
  where id = p_request_id;

  insert into public.store_verification_events (
    request_id, actor_user_id, from_status, to_status, note, metadata
  ) values (
    p_request_id, v_reviewer_id, v_request.status, v_status,
    nullif(trim(coalesce(p_note, '')), ''),
    jsonb_build_object('payment_status', p_payment_status, 'payment_reconciled', true)
  );

  insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
  values (
    v_request.merchant_id,
    'store_verification_payment',
    case when p_payment_status in ('paid', 'waived') then 'تم تأكيد رسوم توثيق Pro' else 'تحديث حالة رسوم توثيق Pro' end,
    case when p_payment_status in ('paid', 'waived')
      then 'تم تأكيد الدفع. أكمل المستندات ثم أرسل طلب التوثيق للمراجعة.'
      else 'تغيرت حالة رسوم التوثيق. راجع الملاحظة وأعد الإجراء عند الحاجة.'
    end,
    jsonb_build_object('request_id', p_request_id, 'payment_status', p_payment_status)
  );

  return (select to_jsonb(r) from public.store_verification_requests r where r.id = p_request_id);
end;
$$;

revoke all on function public.admin_set_store_verification_payment(uuid, text, text, text, uuid)
  from public, anon, authenticated;
grant execute on function public.admin_set_store_verification_payment(uuid, text, text, text, uuid)
  to service_role;

grant usage on schema private to service_role;
grant execute on function private.has_admin_permission(text) to service_role;

commit;
