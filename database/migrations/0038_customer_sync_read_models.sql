-- Read models for fast, cross-device customer synchronization.
create or replace view public.customer_conversations
with (security_invoker = true)
as
select
  cp.user_id,
  c.id,
  c.store_id,
  c.created_by,
  s.name_ar as store_name,
  coalesce(last_message.body, 'ابدأ محادثة جديدة') as last_message,
  coalesce(last_message.created_at, c.created_at) as updated_at,
  c.created_at,
  coalesce(
    (
      select array_agg(cp2.user_id::text order by cp2.user_id::text)
      from public.conversation_participants cp2
      where cp2.conversation_id = c.id
    ),
    '{}'::text[]
  ) as participant_ids
from public.conversation_participants cp
join public.conversations c on c.id = cp.conversation_id
join public.stores s on s.id = c.store_id
left join lateral (
  select m.body, m.created_at
  from public.messages m
  where m.conversation_id = c.id
  order by m.created_at desc
  limit 1
) last_message on true;

grant select on public.customer_conversations to authenticated;

create or replace view public.customer_favorite_products
with (security_invoker = true)
as
select
  f.user_id,
  cp.*
from public.favorites f
join public.customer_products cp on cp.id = f.product_id
where f.product_id is not null;

grant select on public.customer_favorite_products to authenticated;

create or replace view public.customer_followed_stores
with (security_invoker = true)
as
select
  sf.user_id,
  cs.*
from public.store_followers sf
join public.customer_stores cs on cs.id = sf.store_id
where cs.status = 'active';

grant select on public.customer_followed_stores to authenticated;
