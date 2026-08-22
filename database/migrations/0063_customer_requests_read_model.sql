-- REQ-04: unified request read model for customer and merchant surfaces.
-- security_invoker keeps requests/request_items/stores/profile RLS effective.

begin;

create or replace view public.customer_requests
with (security_invoker = true)
as
select
  r.id,
  r.requester_id,
  r.store_id,
  s.merchant_id,
  r.subject,
  r.status,
  item.product_id,
  item.product_name,
  s.name_ar as store_name,
  requester.display_name as requester_name,
  r.body,
  item.quantity,
  r.phone,
  r.preferred_handoff_option,
  r.price_note,
  r.delivery_note,
  r.updated_at,
  r.created_at
from public.requests r
join public.stores s on s.id = r.store_id
left join public.profiles requester on requester.user_id = r.requester_id
left join lateral (
  select
    ri.product_id,
    p.name_ar as product_name,
    ri.quantity
  from public.request_items ri
  join public.products p on p.id = ri.product_id
  where ri.request_id = r.id
  order by ri.product_id
  limit 1
) item on true;

revoke all on public.customer_requests from public, anon;
grant select on public.customer_requests to authenticated;

commit;
