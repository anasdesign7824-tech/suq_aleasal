begin;

create or replace function public.admin_activate_subscription_for_user(
  p_merchant_id uuid,
  p_plan_id uuid,
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
  v_plan public.subscription_plans%rowtype;
  v_subscription public.merchant_subscriptions%rowtype;
  v_starts timestamptz := timezone('utc', now());
  v_ends timestamptz;
begin
  if auth.role() <> 'service_role' and not private.has_admin_permission('plans.manage') then raise exception 'plan_admin_forbidden'; end if;
  if p_merchant_id is null or p_plan_id is null then raise exception 'merchant_and_plan_required'; end if;
  select * into v_plan from public.subscription_plans where id = p_plan_id and is_active;
  if not found then raise exception 'subscription_plan_not_found'; end if;
  if v_plan.price_amount = 0 then raise exception 'free_plan_manual_activation_not_required'; end if;
  v_ends := case when v_plan.billing_interval = 'year' then v_starts + interval '1 year' else v_starts + interval '1 month' end;
  update public.merchant_subscriptions set status = 'expired', updated_at = timezone('utc', now()) where merchant_id = p_merchant_id and status = 'active';
  insert into public.merchant_subscriptions (merchant_id, plan_id, status, starts_at, ends_at, activated_by, cancellation_note)
  values (p_merchant_id, p_plan_id, 'active', v_starts, v_ends, v_reviewer_id, nullif(trim(coalesce(p_note, '')), ''))
  returning * into v_subscription;
  insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
  values (p_merchant_id, 'subscription_activated', 'تم تفعيل باقتك', 'تمت مراجعة الحوالة وتفعيل الباقة المختارة. أصبحت مزاياها متاحة الآن في حسابك.', jsonb_build_object('subscription_id', v_subscription.id, 'plan_id', v_plan.id, 'plan_code', v_plan.code, 'ends_at', v_ends, 'manual_activation', true));
  return (select to_jsonb(ms) from public.merchant_subscriptions ms where ms.id = v_subscription.id);
end;
$$;

revoke all on function public.admin_activate_subscription_for_user(uuid, uuid, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_activate_subscription_for_user(uuid, uuid, text, uuid) to service_role;

commit;
