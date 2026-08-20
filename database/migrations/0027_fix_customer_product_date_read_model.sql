-- Correct the date validation in customer_products without touching product rows.
-- The previous foundation view used an escaped regex that could reject valid ISO dates.

begin;

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
  case when (p.metadata ->> 'production_date') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then (p.metadata ->> 'production_date')::date else null end as production_date,
  case when (p.metadata ->> 'packaged_date') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then (p.metadata ->> 'packaged_date')::date else null end as packaged_date,
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
