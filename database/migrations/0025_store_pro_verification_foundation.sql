-- Store Pro verification foundation.
-- Store activation remains independent from verification and public badge state.
-- This migration adds no payment provider integration; payment remains an
-- explicit state in the verification lifecycle until a provider is configured.

begin;

create table if not exists public.store_verification_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  merchant_id uuid not null references public.users(id) on delete cascade,
  plan_code text not null default 'pro',
  origin text not null default 'merchant_request'
    check (origin in ('merchant_request', 'legacy_activation_review', 'admin_created')),
  status text not null default 'draft'
    check (status in ('draft', 'payment_pending', 'submitted', 'under_review', 'needs_more_info', 'approved', 'rejected', 'expired', 'revoked')),
  payment_status text not null default 'not_started'
    check (payment_status in ('not_started', 'pending', 'paid', 'failed', 'refunded', 'waived')),
  payment_reference text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.users(id) on delete set null,
  review_note text,
  expires_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists store_verification_one_open_request_idx
  on public.store_verification_requests(store_id)
  where status in ('draft', 'payment_pending', 'submitted', 'under_review', 'needs_more_info', 'approved');
create index if not exists store_verification_requests_merchant_idx
  on public.store_verification_requests(merchant_id, created_at desc);

create table if not exists public.store_verification_documents (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.store_verification_requests(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  merchant_id uuid not null references public.users(id) on delete cascade,
  document_type text not null
    check (document_type in ('identity', 'business_registration', 'tax_or_license', 'origin_certificate', 'quality_certificate', 'address_proof', 'other')),
  file_path text not null,
  file_name text not null,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  review_status text not null default 'pending'
    check (review_status in ('pending', 'accepted', 'rejected')),
  review_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create index if not exists store_verification_documents_request_idx
  on public.store_verification_documents(request_id, created_at);

create table if not exists public.store_verification_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.store_verification_requests(id) on delete cascade,
  actor_user_id uuid references public.users(id) on delete set null,
  from_status text,
  to_status text not null,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists store_verification_events_request_idx
  on public.store_verification_events(request_id, created_at desc);

create table if not exists public.store_badges (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  request_id uuid not null references public.store_verification_requests(id) on delete restrict,
  badge_code text not null default 'verified_store',
  label_ar text not null default 'متجر موثق',
  status text not null default 'active'
    check (status in ('active', 'expired', 'revoked')),
  issued_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create unique index if not exists store_badges_one_active_code_idx
  on public.store_badges(store_id, badge_code)
  where status = 'active';
create index if not exists store_badges_public_lookup_idx
  on public.store_badges(store_id, status, expires_at);

alter table public.store_verification_requests enable row level security;
alter table public.store_verification_documents enable row level security;
alter table public.store_verification_events enable row level security;
alter table public.store_badges enable row level security;

-- Merchant request metadata is visible to its owner; sensitive document paths
-- are deliberately restricted to the owner and the dedicated admin permission.
drop policy if exists store_verification_requests_owner_read on public.store_verification_requests;
create policy store_verification_requests_owner_read
  on public.store_verification_requests for select
  using (merchant_id = (select auth.uid()) or private.has_admin_permission('verification.read'));

drop policy if exists store_verification_requests_owner_insert on public.store_verification_requests;
create policy store_verification_requests_owner_insert
  on public.store_verification_requests for insert
  with check (
    merchant_id = (select auth.uid())
    and exists (
      select 1 from public.stores s
      where s.id = store_id and s.merchant_id = (select auth.uid())
    )
  );

drop policy if exists store_verification_requests_admin_write on public.store_verification_requests;
create policy store_verification_requests_admin_write
  on public.store_verification_requests for update
  using (private.has_admin_permission('verification.review'))
  with check (private.has_admin_permission('verification.review'));

drop policy if exists store_verification_documents_owner_read on public.store_verification_documents;
create policy store_verification_documents_owner_read
  on public.store_verification_documents for select
  using (merchant_id = (select auth.uid()) or private.has_admin_permission('verification.read_sensitive'));

drop policy if exists store_verification_documents_owner_insert on public.store_verification_documents;
create policy store_verification_documents_owner_insert
  on public.store_verification_documents for insert
  with check (
    merchant_id = (select auth.uid())
    and exists (
      select 1 from public.store_verification_requests r
      where r.id = request_id
        and r.store_id = store_verification_documents.store_id
        and r.merchant_id = (select auth.uid())
        and r.status in ('draft', 'payment_pending', 'needs_more_info')
    )
  );

drop policy if exists store_verification_documents_admin_write on public.store_verification_documents;
create policy store_verification_documents_admin_write
  on public.store_verification_documents for all
  using (private.has_admin_permission('verification.review'))
  with check (private.has_admin_permission('verification.review'));

drop policy if exists store_verification_events_owner_read on public.store_verification_events;
create policy store_verification_events_owner_read
  on public.store_verification_events for select
  using (
    exists (
      select 1 from public.store_verification_requests r
      where r.id = request_id and r.merchant_id = (select auth.uid())
    )
    or private.has_admin_permission('verification.read')
  );

drop policy if exists store_verification_events_admin_insert on public.store_verification_events;
create policy store_verification_events_admin_insert
  on public.store_verification_events for insert
  with check (private.has_admin_permission('verification.review'));

drop policy if exists store_badges_public_read on public.store_badges;
create policy store_badges_public_read
  on public.store_badges for select
  using (
    status = 'active'
    and (expires_at is null or expires_at > timezone('utc', now()))
  );

drop policy if exists store_badges_owner_read on public.store_badges;
create policy store_badges_owner_read
  on public.store_badges for select
  using (
    exists (
      select 1 from public.stores s
      where s.id = store_id and s.merchant_id = (select auth.uid())
    )
    or private.has_admin_permission('verification.read')
  );

drop policy if exists store_badges_admin_write on public.store_badges;
create policy store_badges_admin_write
  on public.store_badges for all
  using (private.has_admin_permission('verification.review'))
  with check (private.has_admin_permission('verification.review'));

-- Existing activation must not silently become Pro verification. Preserve the
-- legacy signal as a review queue item and expose the new badge only from the
-- new approved request table. This is idempotent and does not change stores.
insert into public.store_verification_requests (
  store_id, merchant_id, plan_code, origin, status, payment_status, review_note
)
select s.id, s.merchant_id, 'pro', 'legacy_activation_review', 'needs_more_info', 'not_started',
       'مراجعة توثيق Pro مطلوبة؛ تفعيل المتجر السابق لا يُعد توثيقًا.'
from public.stores s
where s.is_verified = true
  and not exists (
    select 1 from public.store_verification_requests r
    where r.store_id = s.id
  );

-- Correct the public read models: activation is status; Pro verification is an
-- active badge. Existing column names are retained for Dart compatibility.
create or replace view public.customer_stores
with (security_invoker = true)
as
select
  s.id,
  s.merchant_id,
  s.name_ar,
  s.slug,
  s.description,
  s.region_id,
  r.name_ar as region_name_ar,
  s.logo_url,
  s.cover_url,
  s.logo_url as avatar_url,
  mp.business_name as merchant_name_ar,
  coalesce(array_agg(sg.media_url order by sg.sort_order) filter (where sg.media_url is not null), '{}'::text[]) as gallery_urls,
  coalesce((select jsonb_object_agg(sl.platform, sl.url) from public.social_links sl where sl.store_id = s.id), '{}'::jsonb) as social_links,
  coalesce((select array_agg(distinct dm.name_ar order by dm.name_ar)
            from public.merchant_delivery_options mdo
            join public.delivery_methods dm on dm.id = mdo.delivery_method_id
            where mdo.store_id = s.id and mdo.is_active = true and dm.is_active = true), '{}'::text[]) as delivery_options,
  coalesce((select array_agg(mpl.name_ar order by mpl.name_ar)
            from public.merchant_pickup_locations mpl
            where mpl.store_id = s.id and mpl.is_active = true), '{}'::text[]) as pickup_locations,
  s.phone as contact_phone,
  null::text as contact_whatsapp,
  null::text as contact_telegram,
  exists (select 1 from public.store_badges sb where sb.store_id = s.id and sb.status = 'active' and (sb.expires_at is null or sb.expires_at > timezone('utc', now()))) as is_verified,
  s.status,
  coalesce(ss.rating_average, 0)::numeric as rating_average,
  coalesce(ss.review_count, 0) as review_count,
  coalesce(ss.followers_count, 0) as followers_count,
  0 as years_experience,
  mp.description as bio,
  '{}'::text[] as specialties,
  '{}'::text[] as certifications
from public.stores s
left join public.regions r on r.id = s.region_id
left join public.merchant_profiles mp on mp.user_id = s.merchant_id
left join public.store_statistics ss on ss.store_id = s.id
left join public.store_gallery sg on sg.store_id = s.id
group by
  s.id, s.merchant_id, s.name_ar, s.slug, s.description, s.region_id, r.name_ar,
  s.logo_url, s.cover_url, mp.business_name, s.phone, ss.rating_average,
  ss.review_count, ss.followers_count, mp.description;

grant select on public.customer_stores to anon, authenticated;

create or replace view public.customer_products
with (security_invoker = true)
as
select
  p.id,
  p.store_id,
  s.merchant_id,
  p.taxonomy_id,
  p.taxonomy_id as subcategory_id,
  c.id as category_id,
  p.name_ar,
  p.name_en,
  p.description,
  p.product_type,
  p.grade_level,
  p.status,
  p.is_featured,
  p.metadata,
  ht.name_ar as subcategory_name_ar,
  c.name_ar as category_name_ar,
  r.name_ar as region_name_ar,
  p.metadata ->> 'region_id' as region_id,
  p.metadata ->> 'province_id' as province_id,
  p.metadata ->> 'origin_country' as origin_country,
  p.metadata ->> 'honey_identity' as honey_identity,
  p.metadata ->> 'quality_label_ar' as quality_label_ar,
  p.metadata ->> 'processing_method_ar' as processing_method_ar,
  p.metadata ->> 'processing_status_ar' as processing_status_ar,
  p.metadata ->> 'packaging_label_ar' as packaging_label_ar,
  p.metadata ->> 'availability' as availability,
  p.metadata ->> 'weight_label' as weight_label,
  p.metadata ->> 'harvest_label' as harvest_label,
  p.metadata ->> 'province_name_ar' as province_name_ar,
  p.metadata ->> 'grade_label_ar' as grade_label_ar,
  p.metadata ->> 'purpose' as purpose,
  p.metadata ->> 'currency_code' as currency_code,
  nullif(p.metadata ->> 'price', '')::numeric as price,
  nullif(p.metadata ->> 'rating_average', '')::numeric as rating_average,
  nullif(p.metadata ->> 'review_count', '')::integer as review_count,
  nullif(p.metadata ->> 'views_count', '')::integer as views_count,
  nullif(p.metadata ->> 'likes_count', '')::integer as likes_count,
  (array_agg(pi.image_url order by pi.sort_order) filter (where pi.image_url is not null))[1] as primary_image_url,
  coalesce(array_agg(pi.image_url order by pi.sort_order) filter (where pi.image_url is not null), '{}'::text[]) as image_urls,
  coalesce((select array_agg(distinct dm.name_ar order by dm.name_ar)
            from public.merchant_delivery_options mdo
            join public.delivery_methods dm on dm.id = mdo.delivery_method_id
            where mdo.store_id = p.store_id and mdo.is_active = true and dm.is_active = true), '{}'::text[]) as delivery_options,
  coalesce((select array_agg(mpl.name_ar order by mpl.name_ar)
            from public.merchant_pickup_locations mpl
            where mpl.store_id = p.store_id and mpl.is_active = true), '{}'::text[]) as pickup_locations,
  coalesce((select array_agg(value order by value) from jsonb_array_elements_text(coalesce(p.metadata -> 'tags', '[]'::jsonb)) value), '{}'::text[]) as tags,
  coalesce((select array_agg(value order by value) from jsonb_array_elements_text(coalesce(p.metadata -> 'badges', '[]'::jsonb)) value), '{}'::text[]) as badges,
  coalesce((select array_agg(value order by value) from jsonb_array_elements_text(coalesce(p.metadata -> 'regions', '[]'::jsonb)) value), '{}'::text[]) as regions,
  coalesce((select array_agg(value order by value) from jsonb_array_elements_text(coalesce(p.metadata -> 'forms', '[]'::jsonb)) value), '{}'::text[]) as forms,
  coalesce((select array_agg(cert.name_ar order by cert.name_ar)
            from public.product_certifications pc2
            join public.certifications cert on cert.id = pc2.certification_id
            where pc2.product_id = p.id), '{}'::text[]) as certifications,
  case when (p.metadata ->> 'production_date') ~ '^\\d{4}-\\d{2}-\\d{2}$' then (p.metadata ->> 'production_date')::date else null end as production_date,
  case when (p.metadata ->> 'packaged_date') ~ '^\\d{4}-\\d{2}-\\d{2}$' then (p.metadata ->> 'packaged_date')::date else null end as packaged_date,
  p.created_at,
  p.updated_at
from public.products p
left join public.stores s on s.id = p.store_id
left join public.honey_taxonomy ht on ht.id = p.taxonomy_id
left join public.product_categories pc on pc.product_id = p.id
left join public.categories c on c.id = pc.category_id
left join public.regions r on r.id::text = p.metadata ->> 'region_id'
left join public.product_images pi on pi.product_id = p.id
group by
  p.id, p.store_id, s.merchant_id, p.taxonomy_id, c.id, p.name_ar, p.name_en,
  p.description, p.product_type, p.grade_level, p.status, p.is_featured, p.metadata,
  ht.name_ar, c.name_ar, r.name_ar, p.created_at, p.updated_at;

grant select on public.customer_products to anon, authenticated;

commit;
