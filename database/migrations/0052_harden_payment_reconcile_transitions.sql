-- Harden manual payment transition preconditions.
-- Confirmation must follow an uploaded proof or an admin review state;
-- refund must follow confirmation. Waived remains an explicit admin override.

begin;

create or replace function public.admin_reconcile_payment_request(
  p_payment_request_id uuid,
  p_status text,
  p_note text default null,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_request public.payment_requests%rowtype;
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_subscription public.merchant_subscriptions%rowtype;
  v_plan public.subscription_plans%rowtype;
  v_starts timestamptz := timezone('utc', now());
  v_ends timestamptz;
begin
  if auth.role() <> 'service_role'
     and not private.has_admin_permission('payments.manage') then
    raise exception 'payment_admin_forbidden';
  end if;
  if p_status not in ('confirmed', 'failed', 'refunded', 'waived', 'under_review') then
    raise exception 'payment_status_invalid';
  end if;

  select * into v_request
  from public.payment_requests
  where id = p_payment_request_id
  for update;
  if not found then raise exception 'payment_request_not_found'; end if;
  if p_status = 'confirmed' and v_request.payment_method <> 'bank_transfer' then
    raise exception 'card_payment_disabled';
  end if;
  if p_status = 'confirmed'
     and v_request.status not in ('proof_uploaded', 'under_review') then
    raise exception 'payment_confirmation_requires_proof';
  end if;
  if p_status = 'refunded' and v_request.status <> 'confirmed' then
    raise exception 'payment_refund_requires_confirmation';
  end if;
  if p_status = 'under_review'
     and v_request.status not in ('proof_uploaded', 'under_review') then
    raise exception 'payment_review_requires_proof';
  end if;
  if p_status = 'failed'
     and v_request.status not in ('not_started', 'proof_uploaded', 'under_review') then
    raise exception 'payment_failure_transition_invalid';
  end if;

  if p_status in ('confirmed', 'waived') then
    -- A second click/retry for the same payment request must be a no-op.
    select * into v_subscription
    from public.merchant_subscriptions
    where payment_request_id = v_request.id
    limit 1;
    if found then
      return to_jsonb(v_request);
    end if;

    perform pg_advisory_xact_lock(
      hashtextextended(v_request.merchant_id::text || ':subscription_activation', 0)
    );
  end if;

  update public.payment_requests
  set status = p_status,
      reviewer_note = nullif(trim(coalesce(p_note, '')), ''),
      reviewed_by = v_reviewer_id,
      reviewed_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = p_payment_request_id;

  insert into public.payment_events (
    payment_request_id,
    actor_user_id,
    from_status,
    to_status,
    note,
    metadata
  )
  values (
    p_payment_request_id,
    v_reviewer_id,
    v_request.status,
    p_status,
    nullif(trim(coalesce(p_note, '')), ''),
    jsonb_build_object('admin_reconciled', true)
  );

  if p_status in ('confirmed', 'waived') and v_request.payment_type = 'subscription' then
    select * into v_plan
    from public.subscription_plans
    where id = v_request.plan_id;
    if not found then raise exception 'subscription_plan_not_found'; end if;

    v_ends := case
      when v_plan.billing_interval = 'year' then v_starts + interval '1 year'
      else v_starts + interval '1 month'
    end;

    update public.merchant_subscriptions
    set status = 'expired', updated_at = timezone('utc', now())
    where merchant_id = v_request.merchant_id
      and status = 'active';

    insert into public.merchant_subscriptions (
      merchant_id,
      plan_id,
      payment_request_id,
      status,
      starts_at,
      ends_at,
      activated_by
    )
    values (
      v_request.merchant_id,
      v_plan.id,
      v_request.id,
      'active',
      v_starts,
      v_ends,
      v_reviewer_id
    )
    returning * into v_subscription;

    insert into public.notifications (
      user_id,
      notification_type,
      title_ar,
      body_ar,
      payload
    )
    values (
      v_request.merchant_id,
      'subscription_activated',
      'تم تفعيل خطتك',
      'تم تأكيد الحوالة وتفعيل مزايا الخطة في حسابك.',
      jsonb_build_object(
        'subscription_id', v_subscription.id,
        'plan_id', v_plan.id,
        'plan_code', v_plan.code,
        'ends_at', v_ends
      )
    );
  end if;

  if p_status in ('failed', 'refunded') then
    insert into public.notifications (
      user_id,
      notification_type,
      title_ar,
      body_ar,
      payload
    )
    values (
      v_request.merchant_id,
      'payment_update',
      'تحديث طلب الدفع',
      coalesce(
        nullif(trim(coalesce(p_note, '')), ''),
        'لم يتم تأكيد الحوالة. راجع الملاحظة وأعد الإرسال عند الحاجة.'
      ),
      jsonb_build_object(
        'payment_request_id', p_payment_request_id,
        'status', p_status
      )
    );
  end if;

  return (
    select to_jsonb(p)
    from public.payment_requests p
    where p.id = p_payment_request_id
  );
end;
$$;

revoke all on function public.admin_reconcile_payment_request(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_reconcile_payment_request(uuid, text, text, uuid) to service_role;

commit;
