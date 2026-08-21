-- Prevent an expired subscription from being marked active without a new plan activation.
-- Suspended/cancelled subscriptions with remaining time may still be resumed.

begin;

create or replace function public.admin_set_subscription_status(
  p_subscription_id uuid,
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
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_subscription public.merchant_subscriptions%rowtype;
begin
  if auth.role() <> 'service_role' and not private.has_admin_permission('plans.manage') then
    raise exception 'plan_admin_forbidden';
  end if;
  if p_status not in ('active', 'expired', 'cancelled', 'suspended') then
    raise exception 'subscription_status_invalid';
  end if;
  select * into v_subscription
  from public.merchant_subscriptions
  where id = p_subscription_id
  for update;
  if not found then raise exception 'subscription_not_found'; end if;
  if p_status = 'active'
     and v_subscription.ends_at is not null
     and v_subscription.ends_at <= timezone('utc', now()) then
    raise exception 'subscription_reactivation_requires_new_activation';
  end if;

  update public.merchant_subscriptions
  set status = p_status,
      activated_by = case when p_status = 'active' then v_reviewer_id else activated_by end,
      cancelled_at = case
        when p_status in ('cancelled', 'suspended') then timezone('utc', now())
        else cancelled_at
      end,
      cancellation_note = case
        when p_status in ('cancelled', 'suspended') then nullif(trim(coalesce(p_note, '')), '')
        else cancellation_note
      end,
      updated_at = timezone('utc', now())
  where id = p_subscription_id;

  insert into public.notifications (
    user_id,
    notification_type,
    title_ar,
    body_ar,
    payload
  )
  values (
    v_subscription.merchant_id,
    'subscription_update',
    case when p_status = 'active' then 'تم تفعيل خطتك' else 'تحديث حالة خطتك' end,
    coalesce(
      nullif(trim(coalesce(p_note, '')), ''),
      case
        when p_status = 'active' then 'أصبحت مزايا الخطة متاحة في التطبيق.'
        else 'تغيرت حالة خطتك. راجع لوحة التاجر.'
      end
    ),
    jsonb_build_object('subscription_id', p_subscription_id, 'status', p_status)
  );

  return (
    select to_jsonb(ms)
    from public.merchant_subscriptions ms
    where ms.id = p_subscription_id
  );
end;
$$;

revoke all on function public.admin_set_subscription_status(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_set_subscription_status(uuid, text, text, uuid) to service_role;

commit;
