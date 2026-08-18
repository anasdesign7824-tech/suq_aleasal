-- Merchant activation synchronization: application -> profile -> merchant profile -> store -> notification.
-- This migration keeps the customer account as the same Auth identity and promotes its capability only after admin approval.

alter table public.merchant_applications
  add column if not exists store_description text,
  add column if not exists region_id uuid references public.regions(id) on delete set null,
  add column if not exists logo_url text,
  add column if not exists cover_url text;

alter table public.merchant_application_drafts
  add column if not exists store_description text,
  add column if not exists region_id uuid references public.regions(id) on delete set null,
  add column if not exists logo_url text,
  add column if not exists cover_url text;

alter table public.merchant_applications
  drop constraint if exists merchant_applications_status_check;
alter table public.merchant_applications
  add constraint merchant_applications_status_check
  check (status in ('submitted', 'under_review', 'approved', 'needs_more_info', 'rejected', 'withdrawn'));

create unique index if not exists stores_one_per_merchant_idx
  on public.stores(merchant_id);

create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
begin
  if new.role is distinct from old.role
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change profile roles';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_merchant_verification_changes()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
begin
  if (new.verification_status is distinct from old.verification_status
      or new.verified_at is distinct from old.verified_at)
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change merchant verification';
  end if;
  return new;
end;
$$;

create or replace function private.prevent_store_moderation_changes()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private, auth
as $$
begin
  if (new.status is distinct from old.status
      or new.is_verified is distinct from old.is_verified)
     and not public.is_admin()
     and coalesce(auth.role(), '') <> 'service_role'
     and coalesce(current_setting('app.admin_action', true), '') <> 'true' then
    raise exception 'Only an admin may change store moderation fields';
  end if;
  return new;
end;
$$;

create or replace function public.admin_review_merchant_application(
  p_application_id uuid,
  p_status text,
  p_review_note text default null,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  v_reviewer_id uuid := coalesce(p_reviewer_id, auth.uid());
  v_application public.merchant_applications%rowtype;
  v_store public.stores%rowtype;
  v_note text := nullif(trim(coalesce(p_review_note, '')), '');
  v_notification public.notifications%rowtype;
begin
  if auth.role() <> 'service_role'
     and not exists (
       select 1 from public.admin_users
       where user_id = v_reviewer_id and is_active = true
     ) then
    raise exception 'Only an active administrator may review merchant applications';
  end if;

  if p_status not in ('under_review', 'approved', 'needs_more_info', 'rejected') then
    raise exception 'Unsupported merchant application status: %', p_status;
  end if;

  select * into v_application
  from public.merchant_applications
  where id = p_application_id
  for update;

  if not found then
    raise exception 'Merchant application not found';
  end if;

  perform set_config('app.admin_action', 'true', true);

  update public.merchant_applications
  set status = p_status,
      review_note = v_note,
      reviewed_at = timezone('utc', now()),
      reviewed_by = v_reviewer_id
  where id = p_application_id;

  select * into v_application
  from public.merchant_applications
  where id = p_application_id;

  if p_status = 'approved' then
    insert into public.merchant_profiles (
      user_id, business_name, description, verification_status, verified_at
    ) values (
      v_application.user_id,
      v_application.display_name,
      coalesce(v_application.store_description, v_application.experience),
      'verified',
      timezone('utc', now())
    )
    on conflict (user_id) do update set
      business_name = excluded.business_name,
      description = excluded.description,
      verification_status = 'verified',
      verified_at = timezone('utc', now());

    update public.profiles
    set role = 'merchant',
        phone = coalesce(v_application.phone, phone)
    where user_id = v_application.user_id;

    insert into public.stores (
      merchant_id, region_id, name_ar, slug, description, phone,
      logo_url, cover_url, status, is_verified
    ) values (
      v_application.user_id,
      v_application.region_id,
      v_application.display_name,
      'merchant-' || substring(v_application.user_id::text from 1 for 8),
      coalesce(v_application.store_description, v_application.experience),
      v_application.phone,
      v_application.logo_url,
      v_application.cover_url,
      'active',
      true
    )
    on conflict (merchant_id) do update set
      region_id = excluded.region_id,
      name_ar = excluded.name_ar,
      description = excluded.description,
      phone = excluded.phone,
      logo_url = coalesce(excluded.logo_url, public.stores.logo_url),
      cover_url = coalesce(excluded.cover_url, public.stores.cover_url),
      status = 'active',
      is_verified = true;

    select * into v_store from public.stores where merchant_id = v_application.user_id limit 1;

    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_application.user_id,
      'merchant_activation',
      'تم تفعيل متجرك بنجاح',
      'أصبح متجرك صالحًا لرفع المنتجات وسيظهر للمستخدمين بعد نشر المنتجات.',
      jsonb_build_object('application_id', v_application.id, 'store_id', v_store.id, 'status', 'approved')
    )
    returning * into v_notification;
  else
    insert into public.notifications (user_id, notification_type, title_ar, body_ar, payload)
    values (
      v_application.user_id,
      'merchant_application_review',
      case p_status
        when 'under_review' then 'بدأت مراجعة طلب متجرك'
        when 'needs_more_info' then 'نحتاج معلومات إضافية لطلب متجرك'
        else 'تحديث على طلب فتح متجرك'
      end,
      coalesce(v_note, case p_status
        when 'under_review' then 'ينتقل طلبك الآن إلى المراجعة الإدارية.'
        when 'needs_more_info' then 'افتح شاشة كن تاجرًا وأكمل البيانات المطلوبة ثم أرسل الطلب من جديد.'
        else 'راجع بيانات الطلب وملاحظة الإدارة قبل إعادة الإرسال.'
      end),
      jsonb_build_object('application_id', v_application.id, 'status', p_status, 'review_note', v_note)
    )
    returning * into v_notification;
  end if;

  return jsonb_build_object(
    'application', to_jsonb(v_application),
    'store', case when p_status = 'approved' then to_jsonb(v_store) else null end,
    'notification', to_jsonb(v_notification)
  );
end;
$$;

revoke all on function public.admin_review_merchant_application(uuid, text, text, uuid) from public;
grant execute on function public.admin_review_merchant_application(uuid, text, text, uuid) to service_role;

-- Repair already-approved applications that were written before this synchronization existed.
do $$
declare
  v_reviewer_id uuid;
  v_application record;
begin
  select user_id into v_reviewer_id
  from public.admin_users
  where is_active = true
  order by created_at asc
  limit 1;

  if v_reviewer_id is not null then
    for v_application in
      select id
      from public.merchant_applications
      where status = 'approved'
        and not exists (select 1 from public.stores s where s.merchant_id = merchant_applications.user_id)
    loop
      perform public.admin_review_merchant_application(v_application.id, 'approved', 'تمت مزامنة اعتماد سابق إلى مساحة التاجر.', v_reviewer_id);
    end loop;
  end if;
end;
$$;

comment on function public.admin_review_merchant_application(uuid, text, text, uuid)
is 'Atomic admin merchant review: synchronizes application, profile role, merchant profile, store activation, notification, and repair of legacy approved rows.';
