-- Customer read models: keep UI contracts stable while reading the canonical schema.
-- Views use security_invoker so underlying RLS remains effective for client roles.

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
  '{}'::jsonb as social_links,
  '{}'::text[] as delivery_options,
  '{}'::text[] as pickup_locations,
  s.phone as contact_phone,
  null::text as contact_whatsapp,
  null::text as contact_telegram,
  s.is_verified,
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
  s.logo_url, s.cover_url, mp.business_name, s.phone, s.is_verified, s.status,
  ss.rating_average, ss.review_count, ss.followers_count, mp.description;

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
  '{}'::text[] as delivery_options,
  '{}'::text[] as pickup_locations,
  '{}'::text[] as tags,
  '{}'::text[] as badges,
  '{}'::text[] as regions,
  '{}'::text[] as forms,
  '{}'::text[] as certifications,
  null::date as production_date,
  null::date as packaged_date,
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

create or replace view public.customer_banners
with (security_invoker = true)
as
select
  id,
  title_ar,
  body_ar as description_ar,
  coalesce(cta_label_ar, 'استكشف') as cta_label_ar,
  image_url,
  cta_url as target_query,
  sort_order,
  is_active,
  starts_at,
  ends_at,
  created_at,
  updated_at
from public.banners;

grant select on public.customer_banners to anon, authenticated;
