-- 0043_payment_request_idempotency.sql
-- Prevent duplicate open subscription payment requests and duplicate activation
-- when a client retries after a timeout or an administrator submits the same
-- reconciliation more than once.

begin;

create index if not exists payment_requests_merchant_status_created_idx
  on public.payment_requests(merchant_id, payment_type, status, created_at desc);

create or replace function public.merchant_create_subscription_payment_request(
  p_plan_id uuid,
  p_campaign_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_merchant_id uuid := auth.uid();
  v_plan public.subscription_plans%rowtype;
  v_campaign public.subscription_campaigns%rowtype;
  v_request public.payment_requests%rowtype;
  v_discount numeric(5,2) := 0;
  v_final numeric(12,2);
begin
  if v_merchant_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  -- Serialize retries from the same merchant. This closes the race between
  -- checking the partial unique index and inserting a new request.
  perform pg_advisory_xact_lock(
    hashtextextended(v_merchant_id::text || ':subscription_payment_request', 0)
  );

  select * into v_request
  from public.payment_requests
  where merchant_id = v_merchant_id
    and payment_type = 'subscription'
    and status in ('not_started', 'proof_uploaded', 'under_review')
  order by created_at desc
  limit 1
  for update;

  if found then
    return to_jsonb(v_request);
  end if;

  select * into v_plan
  from public.subscription_plans
  where id = p_plan_id and is_active;
  if not found then raise exception 'plan_not_found'; end if;
  if v_plan.price_amount = 0 then raise exception 'free_plan_does_not_require_payment'; end if;

  if exists (
    select 1
    from public.merchant_subscriptions ms
    where ms.merchant_id = v_merchant_id
      and ms.status = 'active'
      and (ms.ends_at is null or ms.ends_at > timezone('utc', now()))
  ) then
    raise exception 'active_subscription_exists';
  end if;

  select * into v_campaign
  from public.subscription_campaigns c
  where c.is_active
    and (c.starts_at is null or c.starts_at <= timezone('utc', now()))
    and (c.ends_at is null or c.ends_at > timezone('utc', now()))
    and 'subscription' = any(c.applies_to)
    and (p_campaign_id is null or c.id = p_campaign_id)
  order by c.created_at desc
  limit 1;

  if found then
    v_discount := private.subscription_discount_for_plan(v_campaign.id, v_plan.code);
  end if;

  v_final := round(v_plan.price_amount * (1 - v_discount / 100), 2);

  insert into public.payment_requests (
    merchant_id,
    plan_id,
    payment_type,
    payment_method,
    status,
    base_amount,
    discount_percent,
    final_amount,
    currency,
    campaign_id
  )
  values (
    v_merchant_id,
    v_plan.id,
    'subscription',
    'bank_transfer',
    'not_started',
    v_plan.price_amount,
    v_discount,
    v_final,
    v_plan.currency,
    v_campaign.id
  )
  returning * into v_request;

  return to_jsonb(v_request);
end;
$$;

revoke all on function public.merchant_create_subscription_payment_request(uuid, uuid) from public, anon;
grant execute on function public.merchant_create_subscription_payment_request(uuid, uuid) to authenticated;

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
