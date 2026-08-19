-- Atomic Admin review lifecycle for Store Pro verification.
-- Only the local Admin Backend service_role is allowed to execute this RPC.

begin;

grant execute on function private.has_admin_permission(text) to service_role;

grant usage on schema private to service_role;

create or replace function public.admin_review_store_verification(
  p_request_id uuid,
  p_action text,
  p_review_note text default null,
  p_reviewer_id uuid default null,
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.store_verification_requests%rowtype;
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_next_status text;
  v_notification_title text;
  v_notification_body text;
  v_badge jsonb;
begin
  if auth.role() <> 'service_role'
     and not private.has_admin_permission('verification.review') then
    raise exception 'Only an authorized administrator may review Pro verification';
  end if;

  if p_action not in ('approve', 'reject', 'needs_more_info', 'revoke') then
    raise exception 'Unsupported Pro verification action: %', p_action;
  end if;

  select * into v_request
  from public.store_verification_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Verification request not found';
  end if;

  if p_action = 'approve' and v_request.payment_status not in ('paid', 'waived') then
    raise exception 'Verification payment is not complete';
  end if;

  v_next_status := case p_action
    when 'approve' then 'approved'
    when 'reject' then 'rejected'
    when 'needs_more_info' then 'needs_more_info'
    else 'revoked'
  end;

  perform set_config('app.admin_action', 'true', true);

  update public.store_verification_requests
  set status = v_next_status,
      review_note = nullif(trim(coalesce(p_review_note, '')), ''),
      reviewed_at = timezone('utc', now()),
      reviewed_by = v_reviewer_id,
      expires_at = case when p_action = 'approve' then p_expires_at else null end,
      updated_at = timezone('utc', now())
  where id = p_request_id;

  if p_action = 'approve' then
    update public.store_badges
    set status = 'revoked',
        revoked_at = timezone('utc', now()),
        revoked_reason = 'استبدال بطلب توثيق أحدث',
        updated_at = timezone('utc', now())
    where store_id = v_request.store_id and status = 'active';

    insert into public.store_badges (
      store_id, request_id, badge_code, label_ar, status, issued_at, expires_at
    ) values (
      v_request.store_id, p_request_id, 'verified_store', 'متجر موثق Pro',
      'active', timezone('utc', now()), p_expires_at
    )
    returning to_jsonb(store_badges.*) into v_badge;

    update public.merchant_profiles
    set verification_status = 'verified',
        verified_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where user_id = v_request.merchant_id;

    v_notification_title := 'تم اعتماد توثيق متجرك Pro';
    v_notification_body := 'ظهرت شارة التوثيق على متجرك بعد اكتمال المراجعة.';
  elsif p_action = 'reject' then
    update public.store_badges
    set status = 'revoked',
        revoked_at = timezone('utc', now()),
        revoked_reason = coalesce(nullif(trim(coalesce(p_review_note, '')), ''), 'لم يستوفِ الطلب معايير التوثيق'),
        updated_at = timezone('utc', now())
    where store_id = v_request.store_id and status = 'active';

    update public.merchant_profiles
    set verification_status = 'rejected',
        verified_at = null,
        updated_at = timezone('utc', now())
    where user_id = v_request.merchant_id;

    v_notification_title := 'تحديث طلب توثيق متجرك';
    v_notification_body := 'لم يُعتمد طلب التوثيق حاليًا. راجع ملاحظة الإدارة وأعد التقديم عند استكمال المطلوب.';
  elsif p_action = 'needs_more_info' then
    v_notification_title := 'يلزم استكمال طلب توثيق المتجر';
    v_notification_body := 'طلبت الإدارة معلومات أو مستندات إضافية لإكمال مراجعة توثيق Pro.';
  else
    update public.store_badges
    set status = 'revoked',
        revoked_at = timezone('utc', now()),
        revoked_reason = coalesce(nullif(trim(coalesce(p_review_note, '')), ''), 'سحب التوثيق من الإدارة'),
        updated_at = timezone('utc', now())
    where store_id = v_request.store_id and status = 'active';

    update public.merchant_profiles
    set verification_status = 'suspended',
        verified_at = null,
        updated_at = timezone('utc', now())
    where user_id = v_request.merchant_id;

    v_notification_title := 'تم سحب توثيق المتجر';
    v_notification_body := 'لم تعد شارة Pro فعالة على المتجر. راجع ملاحظة الإدارة عند الحاجة.';
  end if;

  insert into public.store_verification_events (
    request_id, actor_user_id, from_status, to_status, note, metadata
  ) values (
    p_request_id, v_reviewer_id, v_request.status, v_next_status,
    nullif(trim(coalesce(p_review_note, '')), ''),
    jsonb_build_object('action', p_action, 'payment_status', v_request.payment_status)
  );

  insert into public.notifications (
    user_id, notification_type, title_ar, body_ar, payload
  ) values (
    v_request.merchant_id, 'store_verification', v_notification_title,
    v_notification_body,
    jsonb_build_object('request_id', p_request_id, 'store_id', v_request.store_id, 'status', v_next_status)
  );

  select * into v_request from public.store_verification_requests where id = p_request_id;
  return jsonb_build_object(
    'request', to_jsonb(v_request),
    'badge', v_badge,
    'status', v_next_status
  );
end;
$$;

revoke all on function public.admin_review_store_verification(uuid, text, text, uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.admin_review_store_verification(uuid, text, text, uuid, timestamptz)
  to service_role;

commit;
