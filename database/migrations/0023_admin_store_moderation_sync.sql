-- Unify the legacy Stores moderation button with the merchant activation lifecycle.
-- The local Admin Backend calls this function with service_role after its own RBAC check.

create or replace function public.admin_moderate_store(
  p_store_id uuid,
  p_action text,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_store public.stores%rowtype;
  v_application public.merchant_applications%rowtype;
  v_merchant_profile public.merchant_profiles%rowtype;
  v_notification public.notifications%rowtype;
  v_next_status text;
  v_next_verified boolean;
  v_was_active boolean;
begin
  if auth.role() <> 'service_role'
     and not exists (
       select 1
       from public.admin_users
       where user_id = v_reviewer_id and is_active = true
     ) then
    raise exception 'Only an active administrator may moderate stores';
  end if;

  if p_action not in ('approve', 'reject', 'suspend', 'reactivate') then
    raise exception 'Unsupported store moderation action: %', p_action;
  end if;

  select * into v_store
  from public.stores
  where id = p_store_id
  for update;

  if not found then
    raise exception 'Store not found';
  end if;

  v_was_active := v_store.status = 'active' and v_store.is_verified = true;
  case p_action
    when 'approve', 'reactivate' then
      v_next_status := 'active';
      v_next_verified := true;
    when 'reject' then
      v_next_status := 'rejected';
      v_next_verified := false;
    when 'suspend' then
      v_next_status := 'suspended';
      v_next_verified := false;
  end case;

  -- The trigger guards are intentionally bypassed only inside this server-side action.
  perform set_config('app.admin_action', 'true', true);

  update public.stores
  set status = v_next_status,
      is_verified = v_next_verified,
      updated_at = timezone('utc', now())
  where id = p_store_id;

  if p_action in ('approve', 'reactivate') then
    insert into public.merchant_profiles (
      user_id, business_name, description, verification_status, verified_at
    ) values (
      v_store.merchant_id,
      v_store.name_ar,
      v_store.description,
      'verified',
      timezone('utc', now())
    )
    on conflict (user_id) do update set
      business_name = excluded.business_name,
      description = coalesce(excluded.description, public.merchant_profiles.description),
      verification_status = 'verified',
      verified_at = timezone('utc', now()),
      updated_at = timezone('utc', now());

    update public.profiles
    set role = 'merchant',
        updated_at = timezone('utc', now())
    where user_id = v_store.merchant_id;

    update public.products
    set status = 'active',
        updated_at = timezone('utc', now())
    where store_id = p_store_id and status = 'pending';
  elsif p_action = 'reject' then
    update public.merchant_profiles
    set verification_status = 'rejected',
        verified_at = null,
        updated_at = timezone('utc', now())
    where user_id = v_store.merchant_id;
  elsif p_action = 'suspend' then
    update public.merchant_profiles
    set verification_status = 'suspended',
        verified_at = null,
        updated_at = timezone('utc', now())
    where user_id = v_store.merchant_id;
  end if;

  -- Keep an existing application consistent when the administrator moderates from Stores.
  select * into v_application
  from public.merchant_applications
  where user_id = v_store.merchant_id
  order by submitted_at desc
  limit 1
  for update;

  if found then
    if p_action in ('approve', 'reactivate') then
      update public.merchant_applications
      set status = 'approved',
          reviewed_at = timezone('utc', now()),
          reviewed_by = v_reviewer_id,
          updated_at = timezone('utc', now())
      where id = v_application.id;
    elsif p_action = 'reject' then
      update public.merchant_applications
      set status = 'rejected',
          reviewed_at = timezone('utc', now()),
          reviewed_by = v_reviewer_id,
          updated_at = timezone('utc', now())
      where id = v_application.id;
    end if;
  end if;

  if (p_action in ('approve', 'reactivate') and not v_was_active)
     or p_action in ('reject', 'suspend') then
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_store.merchant_id,
      'store_moderation',
      case p_action
        when 'approve' then 'تم تفعيل متجرك بنجاح'
        when 'reactivate' then 'تمت إعادة تفعيل متجرك'
        when 'reject' then 'تم رفض تفعيل المتجر'
        else 'تم تعليق المتجر مؤقتًا'
      end,
      case p_action
        when 'approve' then 'أصبح متجرك صالحًا لرفع المنتجات وسيظهر للمستخدمين بعد نشر المنتجات.'
        when 'reactivate' then 'عاد متجرك إلى الظهور ويمكنك متابعة إدارة المنتجات.'
        when 'reject' then 'راجع بيانات المتجر وملاحظات الإدارة قبل إعادة التقديم.'
        else 'المتجر غير ظاهر للمستخدمين حاليًا. راجع الإدارة لمعرفة التفاصيل.'
      end,
      jsonb_build_object('store_id', p_store_id, 'status', v_next_status, 'action', p_action)
    )
    returning * into v_notification;
  end if;

  select * into v_store from public.stores where id = p_store_id;
  select * into v_merchant_profile from public.merchant_profiles where user_id = v_store.merchant_id;
  if v_application.id is not null then
    select * into v_application from public.merchant_applications where id = v_application.id;
  end if;

  return jsonb_build_object(
    'store', to_jsonb(v_store),
    'merchant_profile', case when v_merchant_profile.user_id is null then null else to_jsonb(v_merchant_profile) end,
    'application', case when v_application.id is null then null else to_jsonb(v_application) end,
    'notification', case when v_notification.id is null then null else to_jsonb(v_notification) end
  );
end;
$$;

revoke all on function public.admin_moderate_store(uuid, text, uuid) from public;
grant execute on function public.admin_moderate_store(uuid, text, uuid) to service_role;
