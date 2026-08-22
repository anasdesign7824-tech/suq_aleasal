-- REQ-09: project the store contact and handoff data authored by the merchant.
-- Keep security_invoker so underlying RLS remains effective for client roles.

begin;

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
  coalesce((
    select jsonb_object_agg(sl.platform, sl.url)
    from public.social_links sl
    where sl.store_id = s.id
  ), '{}'::jsonb) as social_links,
  coalesce((
    select array_agg(distinct dm.name_ar order by dm.name_ar)
    from public.merchant_delivery_options mdo
    join public.delivery_methods dm on dm.id = mdo.delivery_method_id
    where mdo.store_id = s.id
      and mdo.is_active
      and dm.is_active
  ), '{}'::text[]) as delivery_options,
  coalesce((
    select array_agg(mpl.name_ar order by mpl.created_at)
    from public.merchant_pickup_locations mpl
    where mpl.store_id = s.id
      and mpl.is_active
  ), '{}'::text[]) as pickup_locations,
  s.phone as contact_phone,
  (
    select sl.url
    from public.social_links sl
    where sl.store_id = s.id and sl.platform = 'whatsapp'
    order by sl.created_at desc
    limit 1
  ) as contact_whatsapp,
  (
    select sl.url
    from public.social_links sl
    where sl.store_id = s.id and sl.platform = 'telegram'
    order by sl.created_at desc
    limit 1
  ) as contact_telegram,
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

commit;
