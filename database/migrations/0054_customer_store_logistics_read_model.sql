-- TASK 069: expose active merchant logistics through the existing customer store read model.
-- The view remains security_invoker so existing RLS policies on stores and logistics apply.
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
  coalesce((
    select array_agg(
      concat_ws(
        ' — ',
        dm.name_ar,
        coalesce(dr.name_ar, 'كل المناطق'),
        case
          when mdo.fee_amount is null then null
          else trim(to_char(mdo.fee_amount, 'FM9999999990.##')) || ' ' || mdo.currency
        end,
        case
          when mdo.estimated_days is null then null
          else mdo.estimated_days::text || ' يوم'
        end
      ) order by dm.name_ar, dr.name_ar nulls first, mdo.id
    )
    from public.merchant_delivery_options mdo
    join public.delivery_methods dm on dm.id = mdo.delivery_method_id and dm.is_active
    left join public.regions dr on dr.id = mdo.region_id
    where mdo.store_id = s.id and mdo.is_active
  ), '{}'::text[]) as delivery_options,
  coalesce((
    select array_agg(
      concat_ws(' — ', mpl.name_ar, pr.name_ar, mpl.address, mpl.phone)
      order by mpl.created_at, mpl.id
    )
    from public.merchant_pickup_locations mpl
    left join public.regions pr on pr.id = mpl.region_id
    where mpl.store_id = s.id and mpl.is_active
  ), '{}'::text[]) as pickup_locations,
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
