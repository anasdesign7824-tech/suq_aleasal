-- Complete customer_products projection without changing canonical products storage.
-- Existing view columns retain their original order; new projections are appended.
-- Read-only view: preserve security_invoker and tolerate malformed optional metadata.
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
  case
    when (p.metadata ->> 'production_date') ~ '^\\d{4}-\\d{2}-\\d{2}$'
      then (p.metadata ->> 'production_date')::date
    else null::date
  end as production_date,
  case
    when (p.metadata ->> 'packaged_date') ~ '^\\d{4}-\\d{2}-\\d{2}$'
      then (p.metadata ->> 'packaged_date')::date
    else null::date
  end as packaged_date,
  p.created_at,
  p.updated_at,
  case
    when jsonb_typeof(p.metadata -> 'components') = 'array'
      then array(select jsonb_array_elements_text(p.metadata -> 'components'))
    else '{}'::text[]
  end as components,
  case
    when jsonb_typeof(p.metadata -> 'grade_levels') = 'array'
      then array(
        select value::integer
        from jsonb_array_elements_text(p.metadata -> 'grade_levels') as values(value)
        where value ~ '^-?\\d+$'
      )
    when p.grade_level is not null then array[p.grade_level]::integer[]
    else '{}'::integer[]
  end as grade_levels,
  case
    when jsonb_typeof(p.metadata -> 'grade_labels') = 'array'
      then array(select jsonb_array_elements_text(p.metadata -> 'grade_labels'))
    when nullif(p.metadata ->> 'grade_label_ar', '') is not null
      then array[p.metadata ->> 'grade_label_ar']::text[]
    else '{}'::text[]
  end as grade_labels,
  p.metadata ->> 'shelf_life_label_ar' as shelf_life_label_ar
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
