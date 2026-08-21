-- Refresh the favorite-products read model after customer_products gained metadata projections.
-- The view is read-only and remains protected by security_invoker and authenticated SELECT.
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
